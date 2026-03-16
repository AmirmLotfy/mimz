import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../services/haptics_service.dart';
import '../../../core/providers.dart';

/// Emblem selection screen — choose your district identity
class EmblemSelectionScreen extends ConsumerStatefulWidget {
  const EmblemSelectionScreen({super.key});

  @override
  ConsumerState<EmblemSelectionScreen> createState() => _EmblemSelectionScreenState();
}

class _EmblemSelectionScreenState extends ConsumerState<EmblemSelectionScreen> {
  int _selectedIndex = 2; // Default selection

  static const _emblems = [
    _Emblem(Icons.eco, 'Verdant', MimzColors.mossCore),
    _Emblem(Icons.terrain, 'Stone', MimzColors.textSecondary),
    _Emblem(Icons.water_drop, 'Tidal', MimzColors.mistBlue),
    _Emblem(Icons.local_fire_department, 'Ember', MimzColors.persimmonHit),
    _Emblem(Icons.auto_awesome, 'Stellar', MimzColors.dustyGold),
    _Emblem(Icons.park, 'Grove', MimzColors.mossCore),
    _Emblem(Icons.diamond, 'Crystal', MimzColors.mistBlue),
    _Emblem(Icons.bolt, 'Volt', MimzColors.persimmonHit),
    _Emblem(Icons.architecture, 'Monolith', MimzColors.deepInk),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _emblems[_selectedIndex];

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('District Emblem'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MimzSpacing.xl),
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('STEP 4 OF 5', style: MimzTypography.caption),
                Text(
                  '80% Complete',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.mossCore,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.8,
                backgroundColor: MimzColors.borderLight,
                valueColor: AlwaysStoppedAnimation(MimzColors.mossCore),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: MimzSpacing.xl),
            Text(
              'Choose your\nemblem',
              style: MimzTypography.displayMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              'Your emblem represents your district\'s identity on the world map.',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Preview
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: selected.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: selected.color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: selected.color.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(selected.icon, color: selected.color, size: 44),
              ).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
            const SizedBox(height: MimzSpacing.sm),
            Center(
              child: Text(
                selected.name,
                style: MimzTypography.headlineMedium.copyWith(
                  color: selected.color,
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Emblem grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: MimzSpacing.md,
                crossAxisSpacing: MimzSpacing.md,
              ),
              itemCount: _emblems.length,
              itemBuilder: (context, index) {
                final emblem = _emblems[index];
                final isSelected = index == _selectedIndex;
                return GestureDetector(
                  onTap: () {
                    ref.read(hapticsServiceProvider).selection();
                    setState(() => _selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? emblem.color.withValues(alpha: 0.1)
                          : MimzColors.white,
                      borderRadius: BorderRadius.circular(MimzRadius.lg),
                      border: Border.all(
                          color:
                              isSelected ? emblem.color : MimzColors.borderLight,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(emblem.icon,
                            color:
                                isSelected ? emblem.color : MimzColors.textSecondary,
                            size: 28),
                        const SizedBox(height: MimzSpacing.sm),
                        Text(emblem.name,
                            style: MimzTypography.caption.copyWith(
                                color: isSelected
                                    ? emblem.color
                                    : MimzColors.textSecondary,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn(
                    duration: 300.ms).scale(
                    begin: const Offset(0.9, 0.9), duration: 200.ms);
              },
            ),
            const SizedBox(height: MimzSpacing.xxxl),
            MimzButton(
              label: 'Set Emblem  →',
              onPressed: () async {
                ref.read(hapticsServiceProvider).mediumImpact();
                final emblemId = _emblems[_selectedIndex].name.toLowerCase();
                try {
                  await ref.read(apiClientProvider)
                      .patch('/profile', {'emblemId': emblemId});
                } catch (_) {}
                if (context.mounted) context.go('/district/name');
              },
            ),
            const SizedBox(height: MimzSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _Emblem {
  final IconData icon;
  final String name;
  final Color color;

  const _Emblem(this.icon, this.name, this.color);
}
