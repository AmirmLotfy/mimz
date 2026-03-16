import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/haptics_service.dart';
import '../../../core/providers.dart';

/// Profile edit screen — update display name, preferred name, major, district name.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _displayNameCtrl = TextEditingController();
  final _preferredNameCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _districtNameCtrl = TextEditingController();
  bool _isSaving = false;
  
  List<String> _selectedInterests = [];
  String _difficulty = 'dynamic';
  String _voice = 'standard';

  static const _availableInterests = [
    'Technology', 'Science', 'History', 'Architecture', 'Music', 'Design',
    'Gaming', 'Art', 'Nature', 'Literature', 'Film', 'Space',
  ];

  static const _difficulties = ['easy', 'dynamic', 'hard'];
  static const _voices = ['standard', 'relaxed', 'authoritative'];

  String _normalizeDifficulty(String value) {
    switch (value) {
      case 'casual':
        return 'easy';
      case 'hardcore':
        return 'hard';
      default:
        return _difficulties.contains(value) ? value : 'dynamic';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateFields());
  }

  void _populateFields() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _displayNameCtrl.text = user.displayName;
    _preferredNameCtrl.text = user.preferredName ?? '';
    _majorCtrl.text = user.majorOrProfession ?? '';
    _districtNameCtrl.text = user.districtName;
    _selectedInterests = List.from(user.interests);
    _difficulty = _normalizeDifficulty(user.difficultyPreference);
    _voice = user.voicePreference ?? 'standard';
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _preferredNameCtrl.dispose();
    _majorCtrl.dispose();
    _districtNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final displayName = _displayNameCtrl.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider).valueOrNull;
    final previousUser = user;
    final preferredName = _preferredNameCtrl.text.trim().isEmpty
        ? null
        : _preferredNameCtrl.text.trim();
    final major = _majorCtrl.text.trim().isEmpty ? null : _majorCtrl.text.trim();
    final districtName = _districtNameCtrl.text.trim().isEmpty
        ? user?.districtName ?? ''
        : _districtNameCtrl.text.trim();

    if (user != null) {
      ref.read(currentUserProvider.notifier).updateUser(
            user.copyWith(
              displayName: displayName,
              preferredName: preferredName,
              majorOrProfession: major,
              districtName: districtName,
              interests: _selectedInterests,
              difficultyPreference: _difficulty,
              voicePreference: _voice,
            ),
          );
    }

    try {
      await ref.read(apiClientProvider).patch('/profile', {
        'displayName': displayName,
        'preferredName': preferredName,
        'majorOrProfession': major,
        'districtName': districtName,
        'interests': _selectedInterests,
        'difficultyPreference': _difficulty,
        'voicePreference': _voice,
      });

      ref.read(hapticsServiceProvider).success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: MimzColors.mossCore,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (previousUser != null) {
        ref.read(currentUserProvider.notifier).updateUser(previousUser);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MimzSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                label: 'Display Name',
                controller: _displayNameCtrl,
                hint: 'How others see you in Mimz',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: MimzSpacing.base),
              _buildField(
                label: 'Preferred Name',
                controller: _preferredNameCtrl,
                hint: 'What Mimz calls you (optional)',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: MimzSpacing.base),
              _buildField(
                label: 'Field / Profession',
                controller: _majorCtrl,
                hint: 'e.g. Computer Science, Medicine…',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: MimzSpacing.base),
              _buildField(
                label: 'District Name',
                controller: _districtNameCtrl,
                hint: 'Your territory on the map',
                icon: Icons.location_city,
              ),
              const SizedBox(height: MimzSpacing.xl),
              
              Text('Interests', style: MimzTypography.headlineSmall),
              const SizedBox(height: MimzSpacing.sm),
              Wrap(
                spacing: MimzSpacing.sm,
                runSpacing: MimzSpacing.sm,
                children: _availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (val) {
                      ref.read(hapticsServiceProvider).selection();
                      setState(() {
                        if (val) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                    selectedColor: MimzColors.mossCore.withValues(alpha: 0.2),
                    checkmarkColor: MimzColors.mossCore,
                    labelStyle: MimzTypography.bodySmall.copyWith(
                      color: isSelected ? MimzColors.mossCore : MimzColors.deepInk,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: MimzSpacing.xl),
              
              Text('Gameplay Preferences', style: MimzTypography.headlineSmall),
              const SizedBox(height: MimzSpacing.sm),
              _buildDropdown(
                label: 'AI Difficulty',
                value: _difficulty,
                items: _difficulties,
                onChanged: (val) => setState(() => _difficulty = val!),
              ),
              const SizedBox(height: MimzSpacing.base),
              _buildDropdown(
                label: 'AI Voice Style',
                value: _voice,
                items: _voices,
                onChanged: (val) => setState(() => _voice = val!),
              ),
              
              const SizedBox(height: MimzSpacing.xxl),
              MimzButton(
                label: _isSaving ? 'Saving…' : 'Save Changes',
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: MimzColors.mossCore, size: 16),
          const SizedBox(width: 6),
          Text(label, style: MimzTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: MimzSpacing.xs),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: MimzSpacing.sm),
          ),
          style: MimzTypography.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MimzTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: (val) {
            ref.read(hapticsServiceProvider).selection();
            onChanged(val);
          },
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        ),
      ],
    );
  }
}
