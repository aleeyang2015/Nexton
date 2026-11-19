import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_copy.dart';

/// One row of the bell list (#54): the kind, the server's title and body
/// as sent, and when. An unread row carries a dot (#55).
class NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationRow({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final row = notification;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  NotificationCopy.kindIcon(row.type),
                  color: AppColors.primary,
                  size: 24,
                ),
                widthBx(w: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: customText(
                              NotificationCopy.kindLabel(l10n, row.type),
                              fontSize: 12,
                              color: AppColors.subTitle,
                            ),
                          ),
                          customText(
                            NotificationCopy.when(l10n, row.createdAt),
                            fontSize: 12,
                            color: AppColors.subTitle,
                          ),
                          if (!row.isRead) ...[
                            widthBx(w: 8),
                            Container(
                              key: ValueKey('notification-unread-${row.id}'),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (row.title.isNotEmpty) ...[
                        heightBx(h: 4),
                        customText(
                          row.title,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          maxLine: 2,
                        ),
                      ],
                      if (row.body.isNotEmpty) ...[
                        heightBx(h: 4),
                        customText(row.body, fontSize: 13, maxLine: 4),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
