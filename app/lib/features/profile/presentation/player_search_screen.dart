import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/tokens.dart';
import '../../../core/providers.dart';

class PlayerSearchScreen extends ConsumerStatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  ConsumerState<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends ConsumerState<PlayerSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final results = await ref.read(apiClientProvider).searchPlayers(query);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      // Non-fatal
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(title: const Text('Discover Players')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MimzSpacing.base),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
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
                  borderSide:
                      const BorderSide(color: MimzColors.mossCore, width: 2),
                ),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(MimzSpacing.xl),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_results.isEmpty && _controller.text.length >= 2)
            Padding(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              child: Text(
                'No players found.',
                style: MimzTypography.bodyMedium
                    .copyWith(color: MimzColors.textSecondary),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: MimzSpacing.base),
                itemCount: _results.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: MimzColors.borderLight),
                itemBuilder: (context, index) {
                  final player = _results[index];
                  return _PlayerTile(player: player);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Map<String, dynamic> player;

  const _PlayerTile({required this.player});

  @override
  Widget build(BuildContext context) {
    final name = player['displayName'] as String? ?? 'Explorer';
    final xp = player['xp'] as int? ?? 0;
    final streak = player['streak'] as int? ?? 0;
    final district = player['districtName'] as String? ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.base,
        vertical: MimzSpacing.sm,
      ),
      leading: CircleAvatar(
        backgroundColor: MimzColors.mossCore.withValues(alpha: 0.15),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'M',
          style: MimzTypography.headlineSmall
              .copyWith(color: MimzColors.mossCore),
        ),
      ),
      title: Text(name, style: MimzTypography.bodyLarge),
      subtitle: Row(
        children: [
          Icon(Icons.star, size: 14, color: MimzColors.dustyGold),
          const SizedBox(width: 4),
          Text('$xp XP',
              style:
                  MimzTypography.caption.copyWith(color: MimzColors.dustyGold)),
          if (streak > 0) ...[
            const SizedBox(width: 12),
            const Icon(Icons.local_fire_department,
                size: 14, color: MimzColors.persimmonHit),
            const SizedBox(width: 2),
            Text('$streak',
                style: MimzTypography.caption
                    .copyWith(color: MimzColors.persimmonHit)),
          ],
          if (district.isNotEmpty) ...[
            const SizedBox(width: 12),
            Icon(Icons.location_on, size: 14, color: MimzColors.textTertiary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                district,
                style: MimzTypography.caption
                    .copyWith(color: MimzColors.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing:
          const Icon(Icons.chevron_right, color: MimzColors.textTertiary),
    );
  }
}
