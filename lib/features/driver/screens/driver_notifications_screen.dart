import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';

class DriverNotificationsScreen extends ConsumerWidget {
  const DriverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              PrototypeSession.markAllNotificationsRead();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<NotificationItem>>(
        valueListenable: PrototypeSession.notifications,
        builder: (context, notifications, child) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final todayNotifs = notifications
              .where(
                (n) =>
                    n.time.year == now.year &&
                    n.time.month == now.month &&
                    n.time.day == now.day,
              )
              .toList();
          final earlierNotifs = notifications
              .where(
                (n) =>
                    !(n.time.year == now.year &&
                        n.time.month == now.month &&
                        n.time.day == now.day),
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (todayNotifs.isNotEmpty) ...[
                Text(
                  'Today',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...todayNotifs.map((n) => _buildNotificationItem(context, n)),
                const SizedBox(height: 16),
              ],
              if (earlierNotifs.isNotEmpty) ...[
                Text(
                  'Earlier',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...earlierNotifs.map((n) => _buildNotificationItem(context, n)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationItem notification,
  ) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.booking:
        icon = Icons.receipt_long;
        color = AppColors.primary;
        break;
      case NotificationType.driver:
        icon = Icons.person;
        color = AppColors.secondary;
        break;
      case NotificationType.promo:
        icon = Icons.local_offer;
        color = AppColors.success;
        break;
      case NotificationType.system:
        icon = Icons.campaign;
        color = AppColors.danger;
        break;
    }

    // Format time difference
    final difference = DateTime.now().difference(notification.time);
    String timeString;
    if (difference.inMinutes < 60) {
      timeString = '${difference.inMinutes} mins ago';
      if (difference.inMinutes == 0) timeString = 'Just now';
    } else if (difference.inHours < 24) {
      timeString = '${difference.inHours} hours ago';
    } else {
      timeString = '${difference.inDays} days ago';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: !notification.isRead
          ? color.withValues(alpha: 0.05)
          : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          PrototypeSession.markNotificationRead(notification.id);
          if (notification.routePath != null) {
            context.push(notification.routePath!);
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            notification.title,
            style: GoogleFonts.poppins(
              fontWeight: !notification.isRead
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeString,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
