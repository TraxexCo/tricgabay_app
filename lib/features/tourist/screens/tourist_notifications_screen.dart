import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/shared_widgets.dart';

class TouristNotificationsScreen extends StatelessWidget {
  const TouristNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.notifications,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            tooltip: context.l10n.markAllRead,
            onPressed: () => AppSession.markAllNotificationsRead(),
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<NotificationItem>>(
        valueListenable: AppSession.notifications,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications_off_rounded,
              title: context.l10n.noNotificationsYet,
              subtitle: context.l10n.whenYouGetNotificationsTheyWillAppearHere,
            );
          }

          final today = items
              .where((n) => DateTime.now().difference(n.time).inHours < 24)
              .toList();
          final earlier = items
              .where((n) => DateTime.now().difference(n.time).inHours >= 24)
              .toList();

          return ListView(
            children: [
              if (today.isNotEmpty)
                ..._buildSection(context, MessageCode.today, today),
              if (earlier.isNotEmpty)
                ..._buildSection(context, MessageCode.earlier, earlier),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSection(
    BuildContext context,
    String title,
    List<NotificationItem> items,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          context.message(title),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      ...items.map((n) => _NotificationTile(item: n)),
    ];
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  IconData get _icon => switch (item.type) {
    NotificationType.booking => Icons.receipt_long_rounded,
    NotificationType.driver => Icons.local_taxi_rounded,
    NotificationType.promo => Icons.discount_rounded,
    NotificationType.system => Icons.info_rounded,
  };

  Color get _color => switch (item.type) {
    NotificationType.booking => AppColors.primary,
    NotificationType.driver => Colors.green,
    NotificationType.promo => Colors.orange,
    NotificationType.system => Colors.blueGrey,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppSession.markNotificationRead(item.id);
        if (item.routePath != null) context.push(item.routePath!);
      },
      child: Container(
        color: item.isRead ? null : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.message(item.title),
                          style: GoogleFonts.poppins(
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.message(item.subtitle),
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.message(_timeAgo(item.time)),
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
