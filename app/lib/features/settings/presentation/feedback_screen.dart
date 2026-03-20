import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../design_system/tokens.dart';
import '../../../services/haptics_service.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _category = 'general';
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    ref.read(hapticsServiceProvider).mediumImpact();

    try {
      await ref.read(apiClientProvider).post('/feedback', {
        'category': _category,
        'message': _messageController.text.trim(),
      });
      if (!mounted) return;
      ref.read(hapticsServiceProvider).success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks, your feedback was sent.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ref.read(hapticsServiceProvider).error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send feedback: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        title: const Text('Send Feedback'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MimzSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help us improve Mimz',
                  style: MimzTypography.displaySmall,
                ),
                const SizedBox(height: MimzSpacing.sm),
                Text(
                  'Share bugs, ideas, or anything that felt off. We review every report.',
                  style: MimzTypography.bodyMedium.copyWith(
                    color: MimzColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MimzSpacing.xl),
                Text(
                  'Category',
                  style: MimzTypography.headlineSmall,
                ),
                const SizedBox(height: MimzSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'bug', child: Text('Bug report')),
                    DropdownMenuItem(value: 'ux', child: Text('UX feedback')),
                    DropdownMenuItem(value: 'feature', child: Text('Feature request')),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _category = value ?? 'general'),
                ),
                const SizedBox(height: MimzSpacing.lg),
                Text(
                  'Message',
                  style: MimzTypography.headlineSmall,
                ),
                const SizedBox(height: MimzSpacing.sm),
                TextFormField(
                  controller: _messageController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 1200,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    hintText: 'Describe what happened, what you expected, and your device context if relevant.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Please enter a feedback message.';
                    if (trimmed.length < 10) return 'Please add a bit more detail.';
                    return null;
                  },
                ),
                const SizedBox(height: MimzSpacing.lg),
                MimzButton(
                  label: _submitting ? 'Sending...' : 'Submit Feedback',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
