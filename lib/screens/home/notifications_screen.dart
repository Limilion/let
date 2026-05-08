import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/ui_state_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications(forceRefresh: true);
    });
  }

  Future<void> _markAllAsRead() async {
    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).markAllAsRead();
    await ApiService.trackEvent(
      'notifications_mark_all_read',
      source: 'notifications_screen',
    );
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notification) async {
    await ApiService.trackEvent(
      'notification_tap',
      source: 'notifications_screen',
      metadata: {'type': notification['type']?.toString()},
    );
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final id = notification['id']?.toString();
    if (id != null && notification['isRead'] == false) {
      await notificationProvider.markAsRead(id);
    }

    final type = notification['type']?.toString();
    final actorId = (notification['actor'] as Map<String, dynamic>?)?['id']
        ?.toString();
    final postId = notification['postId']?.toString();

    if ((type == 'like' || type == 'comment') && postId != null) {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final result = await postProvider.fetchPostById(postId);
      if (result['success'] == true && mounted) {
        context.push('/post-details', extra: result['data']);
        return;
      }
    }

    if (type == 'follow' && actorId != null) {
      context.push('/user-profile/$actorId');
      return;
    }
    if (actorId != null) {
      context.push('/user-profile/$actorId');
    }
  }

  Future<void> _handleFollowBack(Map<String, dynamic> notification) async {
    final actorId = (notification['actor'] as Map<String, dynamic>?)?['id']
        ?.toString();
    if (actorId == null) return;
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    await postProvider.toggleFollow(actorId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تنفيذ طلب المتابعة')));
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return 'الآن';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'الآن';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final colors = themeProvider.colors;
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'الإشعارات',
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('تعيين الكل كمقروء'),
          ),
        ],
      ),
      body: notificationProvider.loading
          ? const StateLoading(message: 'جار تحميل الإشعارات...')
          : notificationProvider.error != null && notifications.isEmpty
          ? StateError(
              title: 'تعذر تحميل الإشعارات',
              subtitle: notificationProvider.error!,
              onRetry: () => Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).fetchNotifications(forceRefresh: true),
            )
          : notifications.isEmpty
          ? const StateEmpty(
              icon: Icons.notifications_off_outlined,
              title: 'لا توجد إشعارات حتى الآن',
            )
          : RefreshIndicator(
              onRefresh: () => Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).fetchNotifications(forceRefresh: true),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  0,
                  16,
                  0,
                  120,
                ),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: _buildNotificationItem(notification, colors),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    dynamic colors,
  ) {
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment_rounded;
        iconColor = colors.primary;
        break;
      case 'follow':
        icon = Icons.person_add_alt_1_rounded;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = colors.primary;
    }

    final actor = notification['actor'] as Map<String, dynamic>?;
    final actorName = actor?['name'] ?? 'مستخدم';
    final avatarUrl = ApiService.getImageUrl(actor?['photo']);

    return InkWell(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        color: notification['isRead'] == false
            ? colors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  backgroundColor: colors.surface,
                  child: avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.background, width: 2),
                    ),
                    child: Icon(icon, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 14,
                        fontFamily: 'ExpoArabic',
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '$actorName ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: notification['body'] ?? ''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification['createdAt']),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (notification['type'] == 'follow')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: () => _handleFollowBack(notification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'رد المتابعة',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
