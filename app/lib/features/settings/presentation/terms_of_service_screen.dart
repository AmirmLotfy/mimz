import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Terms of Service'),
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
            Text('MIMZ USAGE AGREEMENT', style: MimzTypography.headlineLarge),
            const SizedBox(height: MimzSpacing.base),
            Text('Effective: March 1, 2026', style: MimzTypography.caption),
            const SizedBox(height: MimzSpacing.xl),
            
            _section('1. The Protocol', 'By using Mimz, you agree to participate in a live, community-driven educational game. You are responsible for your interactions with other players in the physical world.'),
            
            _section('2. Conduct', 'Mimz is a space for curiosity. Harassment, district vandalism (digital), or cheating via spoofing location is strictly prohibited and will result in Protocol Decoupling (account ban).'),
            
            _section('3. Safety First', 'Do not play Mimz while driving or in dangerous areas. Always be aware of your surroundings. Mimz is not liable for physical injury occurring during gameplay.'),
            
            _section('4. Intellectual Property', 'All Mimz assets, including AI-generated questions and district emblems, remain the property of the Mimz Project.'),
            
            const SizedBox(height: MimzSpacing.xxl),
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
