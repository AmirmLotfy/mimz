import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../data/models/user.dart';

/// Profile provider delegates to currentUser
final profileProvider = Provider<AsyncValue<MimzUser>>((ref) {
  return ref.watch(currentUserProvider);
});

/// Stats derived from user
final userStatsProvider = Provider<Map<String, String>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull ?? MimzUser.demo;
  return {
    'TOTAL XP': '${user.xp}',
    'STREAK': '${user.streak}',
    'SECTORS': '${user.sectors}',
  };
});
