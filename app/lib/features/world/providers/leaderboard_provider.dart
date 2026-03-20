import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

class LeaderboardEntryModel {
  final String userId;
  final String displayName;
  final int score;
  final int rank;
  final String? districtName;

  LeaderboardEntryModel({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.rank,
    this.districtName,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json, int defaultRank) {
    return LeaderboardEntryModel(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Unknown',
      score: json['score'] ?? 0,
      rank: json['rank'] ?? defaultRank,
      districtName: json['districtName'],
    );
  }
}

class LeaderboardScopeModel {
  final String scope;
  final String label;
  final String? topic;
  final String? eventId;

  const LeaderboardScopeModel({
    required this.scope,
    required this.label,
    this.topic,
    this.eventId,
  });
}

const leaderboardScopes = <LeaderboardScopeModel>[
  LeaderboardScopeModel(scope: 'global', label: 'GLOBAL'),
  LeaderboardScopeModel(scope: 'weekly', label: 'WEEKLY'),
  LeaderboardScopeModel(scope: 'topic', label: 'TOPIC', topic: 'Technology & Engineering'),
  LeaderboardScopeModel(scope: 'event', label: 'EVENT'),
  LeaderboardScopeModel(scope: 'squad', label: 'SQUAD'),
];

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntryModel>, LeaderboardScopeModel>((ref, scope) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final response = await apiClient.getLeaderboard(
      scope: scope.scope,
      topic: scope.topic,
      event: scope.eventId,
    );
    final entries = response['entries'] as List<dynamic>? ?? [];
    return List.generate(entries.length, (index) {
      return LeaderboardEntryModel.fromJson(entries[index] as Map<String, dynamic>, index + 1);
    });
  } catch (_) {
    if (scope.scope != 'squad') {
      return [];
    }

    final squad = await apiClient.getMySquad();
    if (squad == null) return [];
    final members = squad['members'] as List<dynamic>? ?? [];
    final sorted = List<Map<String, dynamic>>.from(
      members.map((member) => member as Map<String, dynamic>),
    )..sort((a, b) => ((b['xpContributed'] as int?) ?? 0).compareTo((a['xpContributed'] as int?) ?? 0));

    return List.generate(sorted.length, (index) {
      final member = sorted[index];
      return LeaderboardEntryModel(
        userId: member['userId'] ?? '',
        displayName: member['displayName'] ?? 'Unknown',
        score: (member['xpContributed'] as int?) ?? 0,
        rank: index + 1,
        districtName: null,
      );
    });
  }
});
