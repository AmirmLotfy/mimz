import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design_system/tokens.dart';
import '../providers/profile_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../services/haptics_service.dart';
import '../../../core/providers.dart';
import '../services/profile_storage_service.dart';
import '../../../data/models/user.dart';

/// Profile / Me screen — wired with providers and navigation
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _removePhoto() async {
    Navigator.pop(context); // close bottom sheet
    ref.read(hapticsServiceProvider).heavyImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: MimzColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isUploadingPhoto = true);
      try {
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user != null && user.storagePath != null) {
          await ProfileStorageService.deleteImage(user.storagePath!);
        }
        
        if (user != null) {
          ref.read(currentUserProvider.notifier).updateUser(
            user.copyWith(profileImageUrl: null, storagePath: null),
          );
        }
        
        await ref.read(apiClientProvider).patch('/profile', {
          'profileImageUrl': null,
          'storagePath': null,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove photo: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _changePhoto(bool fromCamera, {bool closeSheet = true}) async {
    if (closeSheet && Navigator.canPop(context)) {
      Navigator.pop(context); // close bottom sheet
    }
    setState(() => _isUploadingPhoto = true);
    try {
      final result = await ProfileStorageService.pickAndUpload(fromCamera: fromCamera);
      if (result != null) {
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user != null) {
          ref.read(currentUserProvider.notifier).updateUser(
            user.copyWith(profileImageUrl: result.url, storagePath: result.storagePath),
          );
        }
        await ref.read(apiClientProvider).patch('/profile', {
          'profileImageUrl': result.url,
          'storagePath': result.storagePath,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            action: SnackBarAction(
              label: 'Retry',
                onPressed: () => _changePhoto(fromCamera, closeSheet: false),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    ref.read(hapticsServiceProvider).mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MimzRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: MimzSpacing.md),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: MimzColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            Text('Change Profile Photo', style: MimzTypography.headlineSmall),
            const SizedBox(height: MimzSpacing.base),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: MimzColors.mossCore),
              title: const Text('Take a photo'),
              onTap: () => _changePhoto(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: MimzColors.mossCore),
              title: const Text('Choose from library'),
              onTap: () => _changePhoto(false),
            ),
            if (ref.read(currentUserProvider).valueOrNull?.profileImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: MimzColors.error),
                title: Text('Remove photo', style: TextStyle(color: MimzColors.error)),
                onTap: _removePhoto,
              ),
            const SizedBox(height: MimzSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull ?? MimzUser.demo;
    final stats = ref.watch(userStatsProvider);
    final isLoading = userAsync.isLoading;

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: MimzSpacing.xl,
            right: MimzSpacing.xl,
            top: MimzSpacing.xl,
            bottom: MimzSpacing.xl + 100, // padding for floating pill
          ),
          child: Column(
            children: [
              // Tappable Avatar
              if (isLoading)
                const _SkeletonBox(width: 96, height: 96, radius: 48)
              else
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MimzColors.mossCore.withValues(alpha: 0.15),
                        ),
                        child: ClipOval(
                          child: _isUploadingPhoto
                              ? const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : user.profileImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: user.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 96,
                                      height: 96,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName[0].toUpperCase()
                                              : 'M',
                                          style: MimzTypography.headlineLarge
                                              .copyWith(color: MimzColors.mossCore),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : 'M',
                                        style: MimzTypography.headlineLarge
                                            .copyWith(color: MimzColors.mossCore),
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: MimzColors.mossCore,
                            shape: BoxShape.circle,
                            border: Border.all(color: MimzColors.cloudBase, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: MimzColors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
              const SizedBox(height: MimzSpacing.md),
              if (isLoading) ...[
                const _SkeletonBox(width: 160, height: 20, radius: 4),
                const SizedBox(height: MimzSpacing.sm),
                const _SkeletonBox(width: 100, height: 14, radius: 4),
              ] else ...[
                Text(user.displayName, style: MimzTypography.headlineLarge),
                Text(user.handle, style: MimzTypography.bodySmall),
              ],
              const SizedBox(height: MimzSpacing.xxl),
              // Stats row
              if (isLoading)
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? MimzSpacing.md : 0),
                      child: const _SkeletonBox(width: double.infinity, height: 72, radius: MimzRadius.md),
                    ),
                  )),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...stats.entries.toList().asMap().entries.expand((entry) {
                        final widgets = <Widget>[
                          _StatCard(value: entry.value.value, label: entry.value.key),
                        ];
                        if (entry.key < stats.length - 1) {
                          widgets.add(const SizedBox(width: MimzSpacing.md));
                        }
                        return widgets;
                      }),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: MimzSpacing.xxl),
              // Menu items — all wired to routes
              _MenuItem(
                icon: Icons.map,
                title: 'My District',
                subtitle: '${user.districtName} • ${user.sectors} sectors',
                onTap: () => context.go('/world'),
              ),
              _MenuItem(
                icon: Icons.inventory_2,
                title: 'Reward Vault',
                subtitle: '12 blueprints collected',
                onTap: () => context.push('/rewards'),
              ),
              _MenuItem(
                icon: Icons.people,
                title: 'My Squad',
                subtitle: '4 members',
                onTap: () => context.go('/squad'),
              ),
              _MenuItem(
                icon: Icons.bar_chart,
                title: 'Leaderboard',
                subtitle: 'Rank #142',
                onTap: () => context.push('/leaderboard'),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Messages, alerts, and system logs',
                badgeCount: ref.watch(unreadNotificationsCountProvider),
                onTap: () => context.push('/notifications'),
              ),
              _MenuItem(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Account, privacy, notifications',
                onTap: () => context.push('/settings'),
              ),
              _MenuItem(
                icon: Icons.help,
                title: 'Help',
                subtitle: 'FAQ, support, feedback',
                onTap: () => context.push('/settings/help'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: MimzSpacing.base,
        horizontal: MimzSpacing.md,
      ),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        children: [
          Text(value, style: MimzTypography.headlineMedium),
          Text(label, style: MimzTypography.caption),
        ],
      ),
    );
  }
}

class _MenuItem extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? badgeCount;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(hapticsServiceProvider).selection();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
        padding: const EdgeInsets.all(MimzSpacing.base),
        decoration: BoxDecoration(
          color: MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(color: MimzColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MimzColors.mossCore.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MimzRadius.sm),
              ),
              child: Icon(icon, color: MimzColors.mossCore, size: 20),
            ),
            const SizedBox(width: MimzSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MimzTypography.headlineSmall),
                  Text(subtitle, style: MimzTypography.bodySmall),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MimzColors.persimmonHit,
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Text(
                  '$badgeCount',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            const SizedBox(width: MimzSpacing.sm),
            const Icon(Icons.chevron_right, color: MimzColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Animated skeleton placeholder used while async data loads.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MimzColors.borderLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
      .fadeIn(duration: 600.ms)
      .then()
      .fadeOut(duration: 600.ms);
  }
}
