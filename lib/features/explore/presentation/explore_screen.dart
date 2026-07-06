import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../feed/presentation/providers/feed_provider.dart';
import 'explore_detail_screen.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search for gems, users, tags...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          feedAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error loading explore: $err',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No posts yet.', style: TextStyle(color: Colors.white)),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(2),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ExploreDetailScreen(initialIndex: index),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                post.thumbnailUrl.isNotEmpty 
                                    ? post.thumbnailUrl 
                                    : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&q=80&w=400',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: const Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.play_arrow_outlined, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
