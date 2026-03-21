import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../core/providers.dart';
import '../../../design_system/components/mimz_chip.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Screen 10 — District naming with smart suggestions
class DistrictNamingScreen extends ConsumerStatefulWidget {
  const DistrictNamingScreen({super.key});

  @override
  ConsumerState<DistrictNamingScreen> createState() => _DistrictNamingScreenState();
}

class _DistrictNamingScreenState extends ConsumerState<DistrictNamingScreen> {
  final _nameController = TextEditingController(text: 'Verdant Reach');
  String _selectedSuggestion = 'Verdant Reach';

  final _suggestions = [
    'Mossy Hollow',
    'Cedar Ridge',
    'Verdant Reach',
    'Greyrock Bay',
    'Sylvan Grove',
    'Elder Peak',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
        title: const Text('Name Your District'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: MimzColors.mossCore.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline,
                  color: MimzColors.mossCore, size: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('STEP 5 OF 5', style: MimzTypography.caption),
                Text(
                  '100% Complete',
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
                value: 1.0,
                backgroundColor: MimzColors.borderLight,
                valueColor: AlwaysStoppedAnimation(MimzColors.mossCore),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: MimzSpacing.xl),
            Text(
              'Give your district\na legacy',
              style: MimzTypography.displayMedium,
            ),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              'The identity of your region starts with its name. Choose something that resonates.',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
            ),
            const SizedBox(height: MimzSpacing.xl),
            // Map preview card
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MimzRadius.lg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MimzColors.mossCore.withValues(alpha: 0.2),
                    MimzColors.mistBlue.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Grid pattern
                  CustomPaint(
                    size: Size.infinite,
                    painter: _MapGridPainter(),
                  ),
                  // District info overlay
                  Positioned(
                    bottom: MimzSpacing.base,
                    left: MimzSpacing.base,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(MimzSpacing.sm),
                              decoration: BoxDecoration(
                                color: MimzColors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(MimzRadius.sm),
                              ),
                              child: const Icon(Icons.location_city,
                                  color: MimzColors.mossCore, size: 20),
                            ),
                            const SizedBox(width: MimzSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DISTRICT EMBLEM',
                                  style: MimzTypography.caption.copyWith(
                                    color: MimzColors.white,
                                  ),
                                ),
                                Text(
                                  _selectedSuggestion,
                                  style: MimzTypography.headlineSmall.copyWith(
                                    color: MimzColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: MimzSpacing.base,
                    right: MimzSpacing.base,
                    child: Text(
                      '1.0 sq km',
                      style: MimzTypography.bodySmall.copyWith(
                        color: MimzColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MimzSpacing.xl),
            // District name input
            Text('District Name', style: MimzTypography.headlineSmall),
            const SizedBox(height: MimzSpacing.sm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter district name',
                filled: true,
                fillColor: MimzColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide: const BorderSide(color: MimzColors.borderLight),
                ),
              ),
              style: MimzTypography.bodyLarge,
            ),
            const SizedBox(height: MimzSpacing.xl),
            // Smart suggestions
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: MimzColors.dustyGold, size: 18),
                const SizedBox(width: MimzSpacing.sm),
                Text(
                  'SMART SUGGESTIONS',
                  style: MimzTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.md),
            Wrap(
              spacing: MimzSpacing.sm,
              runSpacing: MimzSpacing.sm,
              children: _suggestions.map((s) {
                final isSelected = s == _selectedSuggestion;
                return MimzChip(
                  label: s,
                  isSelected: isSelected,
                  icon: isSelected ? Icons.check_circle : null,
                  onTap: () {
                    setState(() {
                      _selectedSuggestion = s;
                      _nameController.text = s;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: MimzSpacing.xxl),
            MimzButton(
              label: 'Establish District  →',
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  // Update local state immediately for snappy UI
                  final user = ref.read(currentUserProvider).valueOrNull;
                  if (user != null) {
                    ref.read(currentUserProvider.notifier).updateUser(
                      user.copyWith(districtName: name),
                    );
                  }
                  // Persist to backend
                  try {
                    await ref.read(apiClientProvider).patch('/profile', {
                      'districtName': name,
                      'onboardingStage': 'district_reveal',
                    });
                    final refreshedUser =
                        ref.read(currentUserProvider).valueOrNull;
                    if (refreshedUser != null) {
                      ref.read(currentUserProvider.notifier).updateUser(
                        refreshedUser.copyWith(
                          districtName: name,
                          onboardingStage: 'district_reveal',
                        ),
                      );
                    }
                  } catch (_) {
                    // Non-fatal — local state already updated
                  }
                }

                // Go to first district reveal, then user taps "Enter your world" to mark onboarded and go to /world
                if (context.mounted) context.go('/district/reveal');
              },
            ),
            const SizedBox(height: MimzSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
