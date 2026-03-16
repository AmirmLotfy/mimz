import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/onboarding_provider.dart';

/// Screen — Gameplay preferences: difficulty, squad, voice
class GameplayPreferencesScreen extends ConsumerStatefulWidget {
  const GameplayPreferencesScreen({super.key});

  @override
  ConsumerState<GameplayPreferencesScreen> createState() =>
      _GameplayPreferencesScreenState();
}

class _GameplayPreferencesScreenState
    extends ConsumerState<GameplayPreferencesScreen> {
  String _difficulty = 'dynamic';
  String _squad = 'social';

  void _proceed() {
    HapticFeedback.mediumImpact();
    ref.read(onboardingDataProvider.notifier).updateField(
          difficultyPreference: _difficulty,
          squadPreference: _squad,
        );
    context.push('/onboarding/summary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Play Style'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MimzSpacing.md),
              _buildProgressBar(),
              const SizedBox(height: MimzSpacing.xl),
              Text(
                'How do you\nlike to play?',
                style: MimzTypography.displayMedium,
              ),
              const SizedBox(height: MimzSpacing.sm),
              Text(
                'You can always change this later in Settings.',
                style: MimzTypography.bodyMedium
                    .copyWith(color: MimzColors.textSecondary),
              ),
              const SizedBox(height: MimzSpacing.xxl),

              // Difficulty
              Text('Challenge Level', style: MimzTypography.headlineMedium),
              const SizedBox(height: MimzSpacing.md),
              _buildDifficultyCards(),
              const SizedBox(height: MimzSpacing.xxl),

              // Squad Preference
              Text('Play Mode', style: MimzTypography.headlineMedium),
              const SizedBox(height: MimzSpacing.md),
              _buildPlayModeCards(),

              const SizedBox(height: MimzSpacing.xxl),
              MimzButton(
                label: 'Almost Done!  →',
                onPressed: _proceed,
              ),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCards() {
    final options = [
      (
        id: 'easy',
        label: 'Casual',
        subtitle: 'Relaxed pace, room for reflection',
        icon: Icons.sentiment_satisfied_alt,
        color: MimzColors.mossCore,
      ),
      (
        id: 'dynamic',
        label: 'Dynamic',
        subtitle: 'Adapts to your performance in real-time',
        icon: Icons.auto_awesome,
        color: MimzColors.mistBlue,
      ),
      (
        id: 'hard',
        label: 'Challenger',
        subtitle: 'Max difficulty, maximum growth',
        icon: Icons.local_fire_department,
        color: MimzColors.dustyGold,
      ),
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = _difficulty == opt.id;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _difficulty = opt.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
            padding: const EdgeInsets.all(MimzSpacing.base),
            decoration: BoxDecoration(
              color: isSelected
                  ? opt.color.withValues(alpha: 0.1)
                  : MimzColors.white,
              borderRadius: BorderRadius.circular(MimzRadius.md),
              border: Border.all(
                color: isSelected ? opt.color : MimzColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: opt.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(MimzRadius.sm),
                  ),
                  child: Icon(opt.icon, color: opt.color, size: 24),
                ),
                const SizedBox(width: MimzSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label,
                          style: MimzTypography.headlineSmall),
                      Text(
                        opt.subtitle,
                        style: MimzTypography.bodySmall
                            .copyWith(color: MimzColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? opt.color : MimzColors.textTertiary,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayModeCards() {
    final modes = [
      (
        id: 'solo',
        label: 'Solo Explorer',
        subtitle: 'Build your district at your own pace',
        icon: Icons.person,
      ),
      (
        id: 'social',
        label: 'Squad Player',
        subtitle: 'Compete and collaborate with a crew',
        icon: Icons.group,
      ),
    ];

    return Row(
      children: modes.map((mode) {
        final isSelected = _squad == mode.id;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _squad = mode.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  right: mode.id == 'solo' ? MimzSpacing.sm : 0),
              padding: const EdgeInsets.all(MimzSpacing.base),
              decoration: BoxDecoration(
                color: isSelected
                    ? MimzColors.mossCore.withValues(alpha: 0.1)
                    : MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.md),
                border: Border.all(
                  color:
                      isSelected ? MimzColors.mossCore : MimzColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    mode.icon,
                    color: isSelected
                        ? MimzColors.mossCore
                        : MimzColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: MimzSpacing.sm),
                  Text(mode.label,
                      style: MimzTypography.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(
                    mode.subtitle,
                    style: MimzTypography.bodySmall
                        .copyWith(color: MimzColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STEP 3 OF 5', style: MimzTypography.caption),
            Text(
              '60% Complete',
              style: MimzTypography.caption
                  .copyWith(color: MimzColors.mossCore),
            ),
          ],
        ),
        const SizedBox(height: MimzSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0.6,
            backgroundColor: MimzColors.borderLight,
            valueColor: AlwaysStoppedAnimation(MimzColors.mossCore),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
