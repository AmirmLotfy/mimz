import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../services/haptics_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

// Interest taxonomy — mirrors backend /interests/taxonomy
const _taxonomy = [
  (
    category: 'Technology & Engineering',
    icon: Icons.computer,
    tags: [
      'Software Engineering',
      'Artificial Intelligence',
      'Hardware & Gadgets',
      'Cybersecurity',
      'Data Science',
    ]
  ),
  (
    category: 'Science & Nature',
    icon: Icons.science,
    tags: [
      'Physics & Astronomy',
      'Biology & Medicine',
      'Chemistry',
      'Earth & Environment',
    ]
  ),
  (
    category: 'Arts & Humanities',
    icon: Icons.history_edu,
    tags: [
      'World History',
      'Literature & Writing',
      'Design & Visual Arts',
      'Music Theory',
    ]
  ),
  (
    category: 'Business & Economics',
    icon: Icons.business,
    tags: [
      'Finance & Markets',
      'Startups & VC',
      'Marketing',
      'Macroeconomics',
    ]
  ),
  (
    category: 'Pop Culture & Trivia',
    icon: Icons.movie,
    tags: [
      'Movies & TV',
      'Video Games',
      'Sports',
      'Pop Music',
    ]
  ),
];

/// Screen — Interest selection using structured taxonomy
class InterestSelectionScreen extends ConsumerStatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  ConsumerState<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState
    extends ConsumerState<InterestSelectionScreen> {
  final Set<String> _selected = {};

  static const _minInterests = 3;

  bool get _canContinue => _selected.length >= _minInterests;

  @override
  void initState() {
    super.initState();
    final cached = ref.read(interestsProvider);
    final user = ref.read(currentUserProvider).valueOrNull;
    _selected.addAll(cached.isNotEmpty ? cached : user?.interests ?? const []);
  }

  void _toggleInterest(String interest) {
    ref.read(hapticsServiceProvider).selection();
    setState(() {
      if (_selected.contains(interest)) {
        _selected.remove(interest);
      } else {
        _selected.add(interest);
      }
    });
  }

  Future<void> _proceed() async {
    ref.read(hapticsServiceProvider).mediumImpact();
    final selectedInterests = _selected.toList();

    // Save selections into both providers
    ref.read(interestsProvider.notifier).state = selectedInterests;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      ref.read(currentUserProvider.notifier).updateUser(
            user.copyWith(
              interests: selectedInterests,
              onboardingStage: 'preferences',
            ),
          );
    }

    try {
      await ref.read(apiClientProvider).updateProfile({
        'interests': selectedInterests,
        'onboardingStage': 'preferences',
      });
    } catch (_) {}

    if (!context.mounted) return;
    context.push('/onboarding/preferences');
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
        title: const Text('Your Interests'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: MimzSpacing.md),
                    _buildProgressBar(),
                    const SizedBox(height: MimzSpacing.xl),
                    Text(
                      'What sparks\nyour curiosity?',
                      style: MimzTypography.displayMedium,
                    ),
                    const SizedBox(height: MimzSpacing.sm),
                    Text(
                      'Pick at least $_minInterests topics. The more you pick, the better your questions get.',
                      style: MimzTypography.bodyMedium
                          .copyWith(color: MimzColors.textSecondary),
                    ),
                    const SizedBox(height: MimzSpacing.xl),
                    ..._taxonomy.map((cat) => _buildCategorySection(cat)),
                    const SizedBox(height: MimzSpacing.xl),
                  ],
                ),
              ),
            ),
            // Sticky bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  MimzSpacing.xl, MimzSpacing.md, MimzSpacing.xl, MimzSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_selected.length} selected',
                        style: MimzTypography.bodySmall.copyWith(
                          color: _canContinue
                              ? MimzColors.mossCore
                              : MimzColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!_canContinue) ...[
                        Text(
                          ' · pick ${_minInterests - _selected.length} more',
                          style: MimzTypography.bodySmall
                              .copyWith(color: MimzColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: MimzSpacing.sm),
                  MimzButton(
                    label: 'Next: Gameplay Preferences  →',
                    onPressed: _canContinue ? _proceed : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      ({String category, IconData icon, List<String> tags}) cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MimzSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cat.icon, color: MimzColors.mossCore, size: 18),
              const SizedBox(width: MimzSpacing.sm),
              Text(
                cat.category.toUpperCase(),
                style: MimzTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: MimzColors.deepInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: MimzSpacing.md),
          Wrap(
            spacing: MimzSpacing.sm,
            runSpacing: MimzSpacing.sm,
            children: cat.tags.map((tag) {
              final isSelected = _selected.contains(tag);
              return GestureDetector(
                onTap: () => _toggleInterest(tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: MimzSpacing.base, vertical: MimzSpacing.sm),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? MimzColors.mossCore : MimzColors.white,
                    borderRadius: BorderRadius.circular(MimzRadius.pill),
                    border: Border.all(
                      color: isSelected
                          ? MimzColors.mossCore
                          : MimzColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check,
                            color: MimzColors.white, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        tag,
                        style: MimzTypography.labelLarge.copyWith(
                          color: isSelected
                              ? MimzColors.white
                              : MimzColors.deepInk,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STEP 2 OF 5', style: MimzTypography.caption),
            Text(
              '40% Complete',
              style: MimzTypography.caption
                  .copyWith(color: MimzColors.mossCore),
            ),
          ],
        ),
        const SizedBox(height: MimzSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0.4,
            backgroundColor: MimzColors.borderLight,
            valueColor: AlwaysStoppedAnimation(MimzColors.mossCore),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
