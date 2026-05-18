import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pedi/core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class GemOverlay extends ConsumerWidget {
  final String title;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> tags;

  const GemOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.tags,
  });

  void _handleInteraction(BuildContext context, WidgetRef ref, VoidCallback action) {
    final authState = ref.read(authStateProvider);
    if (authState.asData?.value != null) {
      action();
    } else {
      _showBottomLoginAlert(context);
    }
  }

  void _showBottomLoginAlert(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amberAccent, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Logged Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Please sign in to interact with posts.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Sign In',
          textColor: Colors.blueAccent,
          onPressed: () {
            context.push('/login');
          },
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showMapBottomSheet(BuildContext context) {
    final bool hasCoordinates = latitude != null && longitude != null;
    const String apiKey = 'AIzaSyCfW7jMPNl7eUk7nR_CKRDMgAFgurme7wo';

    // Premium dark-theme custom style parameters for Google Static Maps
    const String darkMapStyle = 'style=element:geometry%7Ccolor:0x1b1d24&style=element:labels.icon%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x8e929d&style=element:labels.text.stroke%7Ccolor:0x1b1d24&style=feature:administrative%7Celement:geometry%7Ccolor:0x333742&style=feature:road%7Celement:geometry.fill%7Ccolor:0x272a35&style=feature:road%7Celement:geometry.stroke%7Ccolor:0x1b1d24&style=feature:water%7Celement:geometry%7Ccolor:0x0d0f14&style=feature:poi%7Celement:geometry%7Ccolor:0x1f222b';

    final String staticMapUrl = hasCoordinates
        ? 'https://maps.googleapis.com/maps/api/staticmap'
            '?center=$latitude,$longitude'
            '&zoom=15'
            '&size=600x320'
            '&scale=2'
            '&maptype=roadmap'
            '&markers=color:0x00E5FF%7C$latitude,$longitude' // Glowing cyan pin
            '&$darkMapStyle'
            '&key=$apiKey'
        : '';

    Future<void> launchNativeMaps() async {
      final String query = Uri.encodeComponent(location);
      final String urlPath = hasCoordinates
          ? 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
          : 'https://www.google.com/maps/search/?api=1&query=$query';
      
      try {
        final Uri uri = Uri.parse(urlPath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open maps application.')),
            );
          }
        }
      } catch (e) {
        logger.e('Error launching native maps: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D0F16), // Sleek OLED-matching background
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Premium Grab Pill
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),

                  // Header Location Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF00E5FF),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Map Display
                  if (hasCoordinates) ...[
                    GestureDetector(
                      onTap: launchNativeMaps,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: staticMapUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF161922),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF161922),
                              child: const Center(
                                child: Icon(Icons.map_outlined, color: Colors.white24, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Premium fallback container for items with just text location
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161922),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Approximate Location',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'This post specifies a preset area. Click below to explore it dynamically in your native maps application.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Map Navigation Button
                  ElevatedButton.icon(
                    onPressed: launchNativeMaps,
                    icon: const Icon(Icons.directions_rounded, size: 20),
                    label: const Text(
                      'Get Directions',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Bottom Left Info Area
        Positioned(
          bottom: 20,
          left: 16,
          right: 80, // leave room for right sidebar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _handleInteraction(context, ref, () => _showMapBottomSheet(context)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: tags.map((tag) => Text(
                  '#$tag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 60), // Space for bottom nav
            ],
          ),
        ),
        // Right Sidebar
        Positioned(
          bottom: 80, // Above bottom nav
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProfileIcon(context, ref),
              const SizedBox(height: 20),
              _buildSidebarIcon(context, ref, Icons.favorite, '12.4k', () {}),
              const SizedBox(height: 20),
              _buildSidebarIcon(context, ref, Icons.comment, '432', () {}),
              const SizedBox(height: 20),
              _buildSidebarIcon(context, ref, Icons.repeat, 'Repost', () {}),
              const SizedBox(height: 20),
              _buildSidebarIcon(context, ref, Icons.map, 'Map', () => _showMapBottomSheet(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarIcon(BuildContext context, WidgetRef ref, IconData icon, String label, VoidCallback onTap, {bool requiresAuth = true}) {
    return GestureDetector(
      onTap: () {
        if (requiresAuth) {
          _handleInteraction(context, ref, onTap);
        } else {
          onTap();
        }
      },
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleInteraction(context, ref, () {}),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: CachedNetworkImageProvider(
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: -8,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
