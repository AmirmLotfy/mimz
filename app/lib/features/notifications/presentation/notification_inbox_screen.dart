import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/notifications_provider.dart';
import '../domain/notification_item.dart';
import '../../../services/haptics_service.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final notifications = notificationsAsync.valueOrNull ?? const <NotificationItem>[];

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                haptics.mediumImpact();
                await ref.read(notificationsProvider.notifier).markAllRead();
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: MimzColors.mossCore),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: MimzColors.textSecondary),
                  const SizedBox(height: MimzSpacing.md),
                  Text('Could not load notifications', style: MimzTypography.headlineSmall),
                  const SizedBox(height: MimzSpacing.sm),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
                  ),
                  const SizedBox(height: MimzSpacing.md),
                  OutlinedButton(
                    onPressed: () => ref.read(notificationsProvider.notifier).load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) return _buildEmptyState();
            return RefreshIndicator(
              onRefresh: () => ref.read(notificationsProvider.notifier).load(),
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: MimzSpacing.base,
                  right: MimzSpacing.base,
                  top: MimzSpacing.base,
                  bottom: MimzSpacing.base + 100, // padding for floating pill
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _NotificationTile(item: item)
                      .animate(delay: Duration(milliseconds: 100 * index))
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, color: MimzColors.textTertiary, size: 64),
          const SizedBox(height: MimzSpacing.md),
          Text('Nothing to see here', style: MimzTypography.headlineSmall),
          const SizedBox(height: MimzSpacing.xs),
          Text(
            'We\'ll notify you when interesting\nthings happen in your district.',
            textAlign: TextAlign.center,
            style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haptics = ref.read(hapticsServiceProvider);

    return GestureDetector(
      onTap: () {
        haptics.selection();
        ref.read(notificationsProvider.notifier).markAsRead(item.id);
        if (item.route != null) {
          context.push(item.route!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
        padding: const EdgeInsets.all(MimzSpacing.base),
        decoration: BoxDecoration(
          color: item.isRead ? MimzColors.white.withValues(alpha: 0.6) : MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.lg),
          border: Border.all(
            color: item.isRead ? MimzColors.borderLight : MimzColors.mossCore.withValues(alpha: 0.3),
            width: item.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: MimzSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.title, style: MimzTypography.headlineSmall.copyWith(
                        color: item.isRead ? MimzColors.textSecondary : MimzColors.deepInk,
                      )),
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: MimzTypography.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: MimzSpacing.xs),
                  Text(item.message, style: MimzTypography.bodySmall.copyWith(
                    color: item.isRead ? MimzColors.textTertiary : MimzColors.textSecondary,
                  )),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(left: MimzSpacing.sm, top: MimzSpacing.xs),
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: MimzColors.mossCore,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (item.type) {
      case NotificationType.event:
        iconData = Icons.event;
        color = MimzColors.persimmonHit;
        break;
      case NotificationType.reward:
        iconData = Icons.inventory_2;
        color = MimzColors.mossCore;
        break;
      case NotificationType.squad:
        iconData = Icons.people;
        color = Colors.blue;
        break;
      case NotificationType.system:
        iconData = Icons.info_outline;
        color = MimzColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(MimzSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MimzRadius.md),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  String _formatTimestamp(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
