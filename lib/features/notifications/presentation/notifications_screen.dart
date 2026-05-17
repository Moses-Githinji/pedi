import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.asData?.value != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Notifications'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_off, size: 80, color: Colors.white54),
              const SizedBox(height: 24),
              const Text('Login to see notifications', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Today'),
          _buildNotificationItem(Icons.favorite, Colors.red, 'Alex liked your video.', '2h'),
          _buildNotificationItem(Icons.person_add, Colors.blue, 'Jordan started following you.', '4h'),
          _buildSectionHeader('This Week'),
          _buildNotificationItem(Icons.comment, Colors.green, 'Sam commented: "This is fire!"', '1d'),
          _buildNotificationItem(Icons.repeat, Colors.purple, 'Chris reposted your video.', '3d'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildNotificationItem(IconData icon, Color color, String text, String time) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      trailing: Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: () {},
    );
  }
}
