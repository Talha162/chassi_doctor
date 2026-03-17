import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/app_notification.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseService _service = SupabaseService.instance;
  bool _isLoading = true;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      final items = await _service.getNotificationsForUser(userId);
      if (!mounted) return;
      setState(() {
        _notifications = items;
      });
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _service.markAllNotificationsRead(userId);
    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kQuaternaryColor,
          title: const Text('Clear all notifications?'),
          content: const Text('This will permanently delete all notifications.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _service.clearNotificationsForUser(userId);
    await _loadNotifications();
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      await _service.markNotificationRead(notification.id);
      await _loadNotifications();
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    await _service.deleteNotification(notification.id);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: 'Notifications',
        actions: [
          PopupMenuButton<String>(
            color: kQuaternaryColor,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'read') _markAllRead();
              if (value == 'clear') _clearAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        color: kSecondaryColor,
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Image.asset(Assets.imagesPushNotification, height: 80),
                      const SizedBox(height: 16),
                      Center(
                        child: MyText(
                          text: 'No notifications yet.',
                          color: kTertiaryColor,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: AppSizes.DEFAULT,
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final formattedDate = DateFormat('MMM d • hh:mm a')
                          .format(notification.createdAt.toLocal());
                      return Dismissible(
                        key: ValueKey(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteNotification(notification),
                        child: GestureDetector(
                          onTap: () => _openNotification(notification),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kQuaternaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: notification.isRead
                                    ? kBorderColor2
                                    : kSecondaryColor,
                                width: notification.isRead ? 1 : 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: kSecondaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    notification.isRead
                                        ? Icons.notifications_none
                                        : Icons.notifications_active,
                                    color: kSecondaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      MyText(
                                        text: notification.title,
                                        size: 14,
                                        weight: FontWeight.w600,
                                      ),
                                      const SizedBox(height: 4),
                                      MyText(
                                        text: notification.body,
                                        size: 12,
                                        color: kSecondaryColor,
                                        maxLines: 2,
                                        textOverflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      MyText(
                                        text: formattedDate,
                                        size: 10,
                                        color: kTertiaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    height: 8,
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: kSecondaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
