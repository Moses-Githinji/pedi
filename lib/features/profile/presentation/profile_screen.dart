import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/main_layout.dart'; // provides navigationIndexProvider
import '../../feed/domain/models/post_model.dart';
import 'providers/profile_provider.dart';
import '../domain/models/user_model.dart';
import 'widgets/edit_profile_dialog.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../notifications/presentation/widgets/notifications_bottom_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfileImage(BuildContext context, WidgetRef ref, UserModel user) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show instant loading feedback
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Uploading profile image...', style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(days: 1), // Keep open until finished
        ),
      );

      // Upload image to Storage
      final downloadUrl = await ref.read(profileServiceProvider).uploadProfileImage(user.uid, pickedFile.path);

      // Update Firestore user document
      await ref.read(profileServiceProvider).updateProfile(
        user.uid,
        displayName: user.displayName,
        username: user.username,
        bio: user.bio,
        photoUrl: downloadUrl,
      );

      // Success SnackBar
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile image: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.asData?.value;

    // ── Guest ───────────────────────────────────────────────────────────────
    if (firebaseUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Profile'),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_off_outlined, size: 80, color: Colors.white54),
                      const SizedBox(height: 24),
                      const Text(
                        'Join the Pedi community!',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to customise your profile, save your favourite videos, and interact with creators.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                        ),
                        child: const Text('Log In / Register', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Authenticated ────────────────────────────────────────────────────────
    final profileAsync = ref.watch(userProfileStreamProvider(firebaseUser.uid));

    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadCountAsync.asData?.value ?? 0;

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Error loading profile: $err',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
      data: (user) {
        const showEditButton = true;
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount.toString()),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
                tooltip: 'Notifications',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (ctx) => const NotificationsBottomSheet(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Log Out',
                onPressed: () async {
                  final router = GoRouter.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[950],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      title: const Text('Log Out',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to log out from Pedi?',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Log Out',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authActionsProvider).signOut();
                    ref.read(navigationIndexProvider.notifier).set(0);
                    if (mounted) router.go('/');
                  }
                },
              ),
            ],
          ),

          // Column: scrollable header + pinned TabBar + Expanded tab body
          body: Column(
            children: [
              // Scrollable header — Flexible(loose) caps it so it never overflows
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: user.photoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(user.photoUrl)
                                : const CachedNetworkImageProvider(
                                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150',
                                  ),
                          ),
                          if (showEditButton)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _pickAndUploadProfileImage(context, ref, user),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _stat(user.followingCount.toString(), 'Following'),
                          _stat(user.followersCount.toString(), 'Followers'),
                          _stat(user.likesCount.toString(), 'Likes'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showEditButton) ...[
                            ElevatedButton(
                              onPressed: () => showDialog(
                                context: context,
                                barrierColor: Colors.black.withValues(alpha: 0.6),
                                builder: (_) => EditProfileDialog(user: user),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Edit Profile',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Profile link copied!'),
                                  backgroundColor: Colors.grey[900],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.share, size: 20),
                          ),
                        ],
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            user.bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Pinned TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.white.withValues(alpha: 0.1),
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on), text: 'Videos'),
                  Tab(icon: Icon(Icons.favorite_border), text: 'Liked'),
                  Tab(icon: Icon(Icons.bookmark_border), text: 'Saved'),
                ],
              ),

              // Tab body — Expanded gives it bounded height; GridView scrolls inside it
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _createdTab(firebaseUser.uid),
                    _likedTab(firebaseUser.uid),
                    _savedTab(firebaseUser.uid),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Stat widget ──────────────────────────────────────────────────────────────
  Widget _stat(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(count,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Tab builders ─────────────────────────────────────────────────────────────
  Widget _createdTab(String uid) {
    final async = ref.watch(userPostsStreamProvider(uid));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      data: (posts) => posts.isEmpty
          ? _emptyState(
              icon: Icons.video_call_outlined,
              title: 'Share your first Gem!',
              description: 'Capture videos, add tags, and share them with the Pedi community.',
              buttonLabel: 'Upload Video',
              onPressed: () => ref.read(navigationIndexProvider.notifier).set(2),
            )
          : _videoGrid(posts),
    );
  }

  Widget _likedTab(String uid) {
    final async = ref.watch(userLikedPostsStreamProvider(uid));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      data: (posts) => posts.isEmpty
          ? _emptyState(
              icon: Icons.favorite_border,
              title: 'No liked videos yet',
              description: 'Double-tap posts on your feed to show some love and support creators.',
              buttonLabel: 'Discover Videos',
              onPressed: () => ref.read(navigationIndexProvider.notifier).set(0),
            )
          : _videoGrid(posts),
    );
  }

  Widget _savedTab(String uid) {
    final async = ref.watch(userSavedPostsStreamProvider(uid));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      data: (posts) => posts.isEmpty
          ? _emptyState(
              icon: Icons.bookmark_border,
              title: 'Bookmark items for later',
              description: 'Save videos you love so you can easily find them here.',
              buttonLabel: 'Explore Gems',
              onPressed: () => ref.read(navigationIndexProvider.notifier).set(0),
            )
          : _videoGrid(posts),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // ConstrainedBox ensures the content is centred when it fits,
        // and the SingleChildScrollView takes over when it doesn't.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 44, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(buttonLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Video grid ───────────────────────────────────────────────────────────────
  Widget _videoGrid(List<PostModel> posts) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemCount: posts.length,
      itemBuilder: (_, index) {
        final post = posts[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                post.thumbnailUrl.isNotEmpty
                    ? post.thumbnailUrl
                    : 'https://picsum.photos/seed/${post.id}/300/400',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 2),
                      Text('${post.likesCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
