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

final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getLeaderboard();
  final entries = response['entries'] as List<dynamic>? ?? [];
  
  return List.generate(entries.length, (index) {
    return LeaderboardEntryModel.fromJson(entries[index] as Map<String, dynamic>, index + 1);
  });
});
