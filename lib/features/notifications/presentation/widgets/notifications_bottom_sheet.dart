import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';
import '../../domain/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationsBottomSheet extends ConsumerWidget {
  const NotificationsBottomSheet({super.key});

  // Timeago helper
  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Groups list
  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> list) {
    final Map<String, List<NotificationModel>> groups = {
      'Today': [],
      'This Week': [],
      'Earlier': [],
    };
    final now = DateTime.now();
    final todayLimit = DateTime(now.year, now.month, now.day);
    final weekLimit = todayLimit.subtract(const Duration(days: 7));

    for (var notification in list) {
      if (notification.createdAt.isAfter(todayLimit)) {
        groups['Today']!.add(notification);
      } else if (notification.createdAt.isAfter(weekLimit)) {
        groups['This Week']!.add(notification);
      } else {
        groups['Earlier']!.add(notification);
      }
    }
    
    // Clean up empty lists
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;

    if (user == null) {
      return _buildDarkGlassContainer(
        context,
        child: const Center(
          child: Text(
            'Please log in to see notifications',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return notificationsAsync.when(
      loading: () => _buildDarkGlassContainer(
        context,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (err, _) => _buildDarkGlassContainer(
        context,
        child: Center(
          child: Text(
            'Error loading notifications: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      data: (list) {
        final grouped = _groupNotifications(list);
        final hasUnread = list.any((n) => !n.isRead);

        return _buildDarkGlassContainer(
          context,
          child: Column(
            children: [
              // Sheet Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Header Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (hasUnread)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: TextButton(
                          onPressed: () {
                            ref.read(notificationsServiceProvider).markAllNotificationsAsRead(user.uid);
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.white70),
                          child: const Text(
                            'Mark all as read',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 24),

              // Main List
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: grouped.length,
                        itemBuilder: (context, groupIndex) {
                          final groupName = grouped.keys.elementAt(groupIndex);
                          final items = grouped[groupName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Timeline Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                child: Text(
                                  groupName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              // Notification Tiles
                              ...items.map((notification) => _buildNotificationTile(context, ref, user.uid, notification)),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDarkGlassContainer(BuildContext context, {required Widget child}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: SafeArea(child: child),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New updates and interactions will show up here.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    String userId,
    NotificationModel notification,
  ) {
    IconData typeIcon = Icons.notifications;
    Color typeColor = Colors.white;

    switch (notification.type) {
      case 'like':
        typeIcon = Icons.favorite;
        typeColor = Colors.redAccent;
        break;
      case 'comment':
        typeIcon = Icons.comment;
        typeColor = Colors.greenAccent;
        break;
      case 'follow':
        typeIcon = Icons.person_add;
        typeColor = Colors.blueAccent;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Mark as read on tap
          if (!notification.isRead) {
            ref.read(notificationsServiceProvider).markNotificationAsRead(userId, notification.id);
          }
          // Dismiss sheet
          Navigator.pop(context);
          
          // Toast or route feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Interacted with @${notification.senderName}\'s activity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF0288D1), // Sky blue
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            children: [
              // Left side sender photo + type badge overlap
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[900],
                    backgroundImage: notification.senderPhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(notification.senderPhotoUrl)
                        : const CachedNetworkImageProvider(
                            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150',
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Middle rich text description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          TextSpan(
                            text: '@${notification.senderName} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: notification.text,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Right side unread blue/red indicator dot
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
