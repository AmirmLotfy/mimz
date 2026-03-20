import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../services/haptics_service.dart';
import '../providers/onboarding_provider.dart';

/// Screen — Basic profile personalization (name, age band, status, major)
class BasicProfileSetupScreen extends ConsumerStatefulWidget {
  const BasicProfileSetupScreen({super.key});

  @override
  ConsumerState<BasicProfileSetupScreen> createState() =>
      _BasicProfileSetupScreenState();
}

class _BasicProfileSetupScreenState
    extends ConsumerState<BasicProfileSetupScreen> {
  final _nameController = TextEditingController();

  String? _selectedAgeBand;
  String? _selectedStatus;
  final _majorController = TextEditingController();

  static const _ageBands = ['Under 18', '18–24', '25–34', '35–44', '45+'];
  static const _statuses = [
    'Student',
    'Recent Graduate',
    'Professional',
    'Researcher',
    'Entrepreneur',
    'Creator',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _selectedAgeBand != null &&
      _selectedStatus != null;

  void _proceed() {
    ref.read(hapticsServiceProvider).mediumImpact();
    // Save to onboarding state
    ref.read(onboardingDataProvider.notifier).updateField(
          preferredName: _nameController.text.trim(),
          ageBand: _selectedAgeBand,
          studyWorkStatus: _selectedStatus,
          majorOrProfession: _majorController.text.trim().isEmpty
              ? null
              : _majorController.text.trim(),
        );
    context.push('/onboarding/interests');
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
        title: const Text('About You'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MimzSpacing.md),
              _buildProgressBar(step: 1, total: 5, label: 'STEP 1 OF 5'),
              const SizedBox(height: MimzSpacing.xl),
              Text(
                'Tell us about\nyourself',
                style: MimzTypography.displayMedium,
              ),
              const SizedBox(height: MimzSpacing.sm),
              Text(
                'This helps us tailor your learning challenges and district persona.',
                style: MimzTypography.bodyMedium
                    .copyWith(color: MimzColors.textSecondary),
              ),
              const SizedBox(height: MimzSpacing.xxl),

              // Preferred Name
              _sectionLabel('What should we call you?'),
              const SizedBox(height: MimzSpacing.sm),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. Jordan, Reem, Alex...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: MimzSpacing.xl),

              // Age Band
              _sectionLabel('Age range'),
              const SizedBox(height: MimzSpacing.sm),
              Wrap(
                spacing: MimzSpacing.sm,
                runSpacing: MimzSpacing.sm,
                children: _ageBands.map((band) {
                  final selected = _selectedAgeBand == band;
                  return _SelectChip(
                    label: band,
                    selected: selected,
                    onTap: () {
                      ref.read(hapticsServiceProvider).selection();
                      setState(() => _selectedAgeBand = band);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: MimzSpacing.xl),

              // Status
              _sectionLabel('What best describes you?'),
              const SizedBox(height: MimzSpacing.sm),
              Wrap(
                spacing: MimzSpacing.sm,
                runSpacing: MimzSpacing.sm,
                children: _statuses.map((s) {
                  final selected = _selectedStatus == s;
                  return _SelectChip(
                    label: s,
                    selected: selected,
                    onTap: () {
                      ref.read(hapticsServiceProvider).selection();
                      setState(() => _selectedStatus = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: MimzSpacing.xl),

              // Major / Field (optional)
              _sectionLabel('Field of study or profession (optional)'),
              const SizedBox(height: MimzSpacing.sm),
              _buildTextField(
                controller: _majorController,
                hint: 'e.g. Computer Science, Marketing, Med...',
              ),

              const SizedBox(height: MimzSpacing.xxl),
              MimzButton(
                label: 'Next: Pick Your Interests  →',
                onPressed: _canContinue ? _proceed : null,
              ),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: MimzTypography.headlineSmall,
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    void Function(String)? onChanged,
  }) =>
      TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: MimzColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MimzRadius.md),
            borderSide: const BorderSide(color: MimzColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MimzRadius.md),
            borderSide: const BorderSide(color: MimzColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MimzRadius.md),
            borderSide: const BorderSide(color: MimzColors.mossCore, width: 2),
          ),
        ),
        style: MimzTypography.bodyLarge,
      );

  Widget _buildProgressBar({
    required int step,
    required int total,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: MimzTypography.caption),
            Text(
              '${((step / total) * 100).round()}% Complete',
              style: MimzTypography.caption
                  .copyWith(color: MimzColors.mossCore),
            ),
          ],
        ),
        const SizedBox(height: MimzSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: step / total,
            backgroundColor: MimzColors.borderLight,
            valueColor:
                const AlwaysStoppedAnimation(MimzColors.mossCore),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: MimzSpacing.base, vertical: MimzSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? MimzColors.mossCore
              : MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.pill),
          border: Border.all(
            color: selected ? MimzColors.mossCore : MimzColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_circle,
                  color: MimzColors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: MimzTypography.labelLarge.copyWith(
                color: selected ? MimzColors.white : MimzColors.deepInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
