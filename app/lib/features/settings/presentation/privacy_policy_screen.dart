import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../design_system/tokens.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Privacy Policy'),
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
            Text('MIMZ PRIVACY PROTOCOLS', style: MimzTypography.headlineLarge),
            const SizedBox(height: MimzSpacing.base),
            Text('Version 1.0.0 — Last Updated: March 2026', style: MimzTypography.caption),
            const SizedBox(height: MimzSpacing.xl),
            
            _section('1. Data Sovereignty', 'Your district data is yours. Mimz collects anonymized location data only to facilitate local squad connections and game events. We do not sell your personal movement history.'),
            
            _section('2. Voice & Vision', 'Audio and camera data are processed in real-time by the Mimz AI Engine (powered by Gemini) to identify objects and transcribe quiz answers. This data is not stored permanently on Mimz servers unless explicitly saved by you in your Vision Quest gallery.'),
            
            _section('3. Squad Transparency', 'Other players in your district can see your username, handle, and XP. Your precise location is never shared without your explicit "Live Session" activation.'),
            
            _section('4. Protocol Security', 'All transmissions between the Mimz app and our backend are encrypted using industry-standard TLS protocols.'),
            
            const SizedBox(height: MimzSpacing.xxl),
            Text(
              'Questions about your data?',
              style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
            ),
            const SizedBox(height: MimzSpacing.xs),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(
                  'mailto:privacy@mimz.app?subject=Mimz%20Privacy%20Request',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                'privacy@mimz.app',
                style: MimzTypography.bodyMedium.copyWith(
                  color: MimzColors.mossCore,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.xxl),
          ],
        ),
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: MimzTypography.headlineSmall.copyWith(color: MimzColors.mossCore)),
        const SizedBox(height: MimzSpacing.sm),
        Text(content, style: MimzTypography.bodyMedium),
        const SizedBox(height: MimzSpacing.lg),
      ],
    );
  }
}
