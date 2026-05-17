import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/feed_screen.dart';
import '../../explore/presentation/explore_screen.dart';
import '../../upload/presentation/upload_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadCountAsync.asData?.value ?? 0;

    final List<Widget> screens = [
      const FeedScreen(),
      const ExploreScreen(),
      const UploadScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).set(index);
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search), // TikTok standard uses search for explore
            activeIcon: Icon(Icons.search, size: 28),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined, size: 32),
            activeIcon: Icon(Icons.add_box, size: 32),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.person_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
