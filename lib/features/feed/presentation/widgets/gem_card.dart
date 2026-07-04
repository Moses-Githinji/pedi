import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'gem_overlay.dart';
import 'gem_video_player.dart';

class GemCard extends StatelessWidget {
  final String imageUrl; // Can be image or video URL
  final String title;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final String mediaType;
  final bool isActive;
  final bool isPreload;

  const GemCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.tags,
    this.mediaType = 'image',
    this.isActive = false,
    this.isPreload = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Media
        if (mediaType == 'video')
          GemVideoPlayer(
            videoUrl: imageUrl,
            isActive: isActive,
            isPreload: isPreload,
          )
        else
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.error, color: Colors.white),
            ),
          ),
        
        // Dark Gradient for text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
        // Overlays
        GemOverlay(
          title: title,
          description: description,
          location: location,
          latitude: latitude,
          longitude: longitude,
          tags: tags,
        ),
      ],
    );
  }
}
