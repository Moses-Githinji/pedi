import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/gem_card.dart';
import 'providers/feed_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 1,
    ); // Default to Explore
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (mounted) {
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _FeedList(
                feedType: 'picks',
                isTabActive: _activeTabIndex == 0,
              ),
              _FeedList(
                feedType: 'explore',
                isTabActive: _activeTabIndex == 1,
              ),
            ],
          ),
          // Top Navigation Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Center(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    indicatorColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.finlandica(
                       fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: 'My Picks'),
                      Tab(text: 'Explore'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedList extends ConsumerStatefulWidget {
  final String feedType;
  final bool isTabActive;
  const _FeedList({
    required this.feedType,
    required this.isTabActive,
  });

  @override
  ConsumerState<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<_FeedList> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
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
              'No posts yet. Be the first to share!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        // Optional: for now we use the same list for both tabs.
        // If 'picks' needs different logic later, handle it here.
        final data = widget.feedType == 'picks' ? posts.reversed.toList() : posts;

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: data.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final post = data[index];
            final isItemActive = widget.isTabActive && index == _currentIndex;
            final isItemPreload = widget.isTabActive && (index - _currentIndex).abs() <= 1;

            return GemCard(
              imageUrl: post.videoUrl, // GemCard uses imageUrl for both
              title: post.title,
              description: post.description,
              tags: post.tags,
              mediaType: 'video', // All current backend posts are videos
              isActive: isItemActive,
              isPreload: isItemPreload,
            );
          },
        );
      },
    );
  }
}
