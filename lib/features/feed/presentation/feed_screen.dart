import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/gem_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 1,
    ); // Default to Explore
  }

  @override
  void dispose() {
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
            children: const [
              _FeedList(feedType: 'picks'),
              _FeedList(feedType: 'explore'),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Empty space to balance the search icon on the right
                    const SizedBox(width: 48),
                    Expanded(
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
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedList extends StatefulWidget {
  final String feedType;
  const _FeedList({required this.feedType});

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  int _currentIndex = 0;

  // Mock data for the feed
  final List<Map<String, dynamic>> mockGems = [
    {
      'imageUrl':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'mediaType': 'video',
      'title': 'Underground Techno Party',
      'description':
          'Secret location techno party with the best DJs in town. Don\'t miss out!',
      'location': 'Brooklyn, NY',
      'tags': ['techno', 'party', 'underground'],
    },
    {
      'imageUrl': 'https://media.w3.org/2010/05/sintel/trailer.mp4',
      'mediaType': 'video',
      'title': 'Indie Rock Festival',
      'description': 'Three days of non-stop indie rock from upcoming bands.',
      'location': 'Austin, TX',
      'tags': ['music', 'festival', 'indie'],
    },
    {
      'imageUrl':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'mediaType': 'video',
      'title': 'Rooftop Sunset Lounge',
      'description':
          'Enjoy the best views of the city with our signature cocktails.',
      'location': 'Manhattan, NY',
      'tags': ['rooftop', 'sunset', 'drinks'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Reverse the mock data for 'picks' just to look different
    final data = widget.feedType == 'picks'
        ? mockGems.reversed.toList()
        : mockGems;

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: data.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final gem = data[index];
        return GemCard(
          imageUrl: gem['imageUrl'],
          title: gem['title'],
          description: gem['description'],
          location: gem['location'],
          tags: List<String>.from(gem['tags']),
          mediaType: gem['mediaType'],
          isActive: index == _currentIndex,
        );
      },
    );
  }
}
