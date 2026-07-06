import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class GemOverlay extends ConsumerWidget {
  final String title;
  final String description;
  final List<String> tags;

  const GemOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.tags,
  });

  void _handleInteraction(
    BuildContext context,
    WidgetRef ref,
    VoidCallback action,
  ) {
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
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        duration: const Duration(seconds: 4),
      ),
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
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: tags
                    .map(
                      (tag) => Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                    .toList(),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarIcon(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool requiresAuth = true,
  }) {
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
