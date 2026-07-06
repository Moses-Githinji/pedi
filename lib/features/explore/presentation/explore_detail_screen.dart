import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/widgets/gem_card.dart';
import '../../feed/presentation/providers/feed_provider.dart';

class ExploreDetailScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const ExploreDetailScreen({
    super.key,
    required this.initialIndex,
  });

  @override
  ConsumerState<ExploreDetailScreen> createState() => _ExploreDetailScreenState();
}

class _ExploreDetailScreenState extends ConsumerState<ExploreDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading feed: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'No posts found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: posts.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final isItemActive = index == _currentIndex;
                  final isItemPreload = (index - _currentIndex).abs() <= 1;

                  return GemCard(
                    imageUrl: post.videoUrl, // All current backend posts are videos
                    title: post.title,
                    description: post.description,
                    tags: post.tags,
                    mediaType: 'video',
                    isActive: isItemActive,
                    isPreload: isItemPreload,
                  );
                },
              ),
              // Back Button Overlay
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
