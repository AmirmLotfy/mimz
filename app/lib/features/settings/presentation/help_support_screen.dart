import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MimzSpacing.xl,
            MimzSpacing.xl,
            MimzSpacing.xl,
            MimzSpacing.xxl,
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How can we help?', style: MimzTypography.displayMedium),
            const SizedBox(height: MimzSpacing.xl),
            
            _sectionTitle('FREQUENT QUESTIONS'),
            _faqItem('What is a District?', 'A District is your local gameplay zone. It spawns based on your real-world coordinates and contains unique events and rewards.'),
            _faqItem('How do I join a Squad?', 'You can join a squad through the Squad Hub. You can either enter a squad code or join nearby public squads.'),
            _faqItem('What is Vision Quest?', 'Vision Quest uses your camera to identify real-world objects. Successful identifications grant XP and special raw materials for your district.'),
            
            const SizedBox(height: MimzSpacing.xxl),
            _sectionTitle('STILL NEED HELP?'),
            const SizedBox(height: MimzSpacing.md),
            Container(
              padding: const EdgeInsets.all(MimzSpacing.base),
              decoration: BoxDecoration(
                color: MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.lg),
                border: Border.all(color: MimzColors.borderLight),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mail_outline, color: MimzColors.mossCore, size: 32),
                  const SizedBox(height: MimzSpacing.md),
                  Text('Contact Protocols', style: MimzTypography.headlineSmall),
                  const SizedBox(height: MimzSpacing.xs),
                  Text('Response time: Under 24 Mimz-cycles', style: MimzTypography.bodySmall),
                  const SizedBox(height: MimzSpacing.xl),
                  MimzButton(
                    label: 'Send Protocol Log (Feedback)',
                    onPressed: () {
                      context.push('/settings/feedback');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MimzSpacing.md),
      child: Text(title, style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700, color: MimzColors.textSecondary)),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: ExpansionTile(
        title: Text(question, style: MimzTypography.headlineSmall.copyWith(fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(MimzSpacing.base, 0, MimzSpacing.base, MimzSpacing.base),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(answer, style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary)),
        ],
      ),
    );
  }
}
