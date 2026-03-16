import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../data/models/event.dart';
import '../../../design_system/tokens.dart';
import '../../../services/haptics_service.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final MimzEvent event;
  final bool isLive;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.isLive = false,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _joining = false;

  Future<void> _joinOrRegister() async {
    setState(() => _joining = true);
    ref.read(hapticsServiceProvider).mediumImpact();
    try {
      await ref.read(apiClientProvider).joinEvent(widget.event.id);
      if (!mounted) return;
      ref.read(hapticsServiceProvider).success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isLive
                ? 'Joining "${widget.event.title}"...'
                : 'Registered for "${widget.event.title}"!',
          ),
          backgroundColor: MimzColors.mossCore,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ref.read(hapticsServiceProvider).error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not join event: $e')),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Event Details'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  MimzSpacing.xl,
                  MimzSpacing.xl,
                  MimzSpacing.xl,
                  MimzSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MimzSpacing.md,
                          vertical: MimzSpacing.xs,
                        ),
                        margin: const EdgeInsets.only(bottom: MimzSpacing.md),
                        decoration: BoxDecoration(
                          color: MimzColors.persimmonHit,
                          borderRadius: BorderRadius.circular(MimzRadius.sm),
                        ),
                        child: Text(
                          'LIVE NOW',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(event.title, style: MimzTypography.displaySmall),
                    const SizedBox(height: MimzSpacing.md),
                    Text(
                      event.description.isNotEmpty
                          ? event.description
                          : 'No additional event details are available yet.',
                      style: MimzTypography.bodyMedium.copyWith(
                        color: MimzColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: MimzSpacing.lg),
                    Row(
                      children: [
                        const Icon(Icons.people, color: MimzColors.mossCore, size: 18),
                        const SizedBox(width: MimzSpacing.sm),
                        Text('${event.participants} players', style: MimzTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MimzSpacing.xl,
                MimzSpacing.md,
                MimzSpacing.xl,
                MimzSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _joining ? null : _joinOrRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MimzColors.mossCore,
                    foregroundColor: MimzColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MimzRadius.md),
                    ),
                  ),
                  child: Text(
                    _joining
                        ? 'Please wait...'
                        : (widget.isLive ? 'JOIN NOW' : 'REGISTER'),
                    style: MimzTypography.buttonText.copyWith(color: MimzColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
