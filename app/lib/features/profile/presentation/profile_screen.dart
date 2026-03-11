import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/profile_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../data/models/user.dart';

/// Profile / Me screen — wired with providers
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull ?? MimzUser.demo;
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MimzSpacing.xl),
          child: Column(
            children: [
              // Avatar + name
              CircleAvatar(
                radius: 48,
                backgroundColor: MimzColors.mossCore.withValues(alpha: 0.15),
                child: const Icon(Icons.person, size: 48, color: MimzColors.mossCore),
              ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
              const SizedBox(height: MimzSpacing.md),
              Text(user.displayName, style: MimzTypography.headlineLarge),
              Text(user.handle, style: MimzTypography.bodySmall),
              const SizedBox(height: MimzSpacing.xxl),
              // Stats row — from provider
              Row(
                children: stats.entries.map((e) => Expanded(
                  child: _StatCard(value: e.value, label: e.key),
                )).toList()
                  ..insert(1, const SizedBox(width: MimzSpacing.md) as Widget)
                  ..insert(3, const SizedBox(width: MimzSpacing.md) as Widget),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: MimzSpacing.xxl),
              // Menu items
              _MenuItem(icon: Icons.map, title: 'My District',
                  subtitle: '${user.districtName} • ${user.sectors} sectors'),
              _MenuItem(icon: Icons.inventory_2, title: 'Reward Vault',
                  subtitle: '12 blueprints collected'),
              _MenuItem(icon: Icons.people, title: 'My Squad',
                  subtitle: '4 members'),
              _MenuItem(icon: Icons.bar_chart, title: 'Leaderboard',
                  subtitle: 'Rank #142'),
              _MenuItem(icon: Icons.settings, title: 'Settings',
                  subtitle: 'Account, privacy, notifications'),
              _MenuItem(icon: Icons.help, title: 'Help',
                  subtitle: 'FAQ, support, feedback'),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Icon(Icons.chevron_right, color: MimzColors.textTertiary),
        ],
      ),
    );
  }
}
