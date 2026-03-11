/// User model
class MimzUser {
  final String id;
  final String displayName;
  final String handle;
  final String? email;
  final int xp;
  final int streak;
  final int sectors;
  final String districtName;
  final List<String> interests;
  final DateTime createdAt;

  const MimzUser({
    required this.id,
    required this.displayName,
    required this.handle,
    this.email,
    this.xp = 0,
    this.streak = 0,
    this.sectors = 0,
    this.districtName = '',
    this.interests = const [],
    required this.createdAt,
  });

  factory MimzUser.fromJson(Map<String, dynamic> json) => MimzUser(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? 'Explorer',
        handle: json['handle'] as String? ?? '@explorer',
        email: json['email'] as String?,
        xp: json['xp'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
        sectors: json['sectors'] as int? ?? 0,
        districtName: json['districtName'] as String? ?? '',
        interests: (json['interests'] as List?)?.cast<String>() ?? [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'handle': handle,
        'email': email,
        'xp': xp,
        'streak': streak,
        'sectors': sectors,
        'districtName': districtName,
        'interests': interests,
        'createdAt': createdAt.toIso8601String(),
      };

  MimzUser copyWith({
    String? displayName,
    String? handle,
    String? email,
    int? xp,
    int? streak,
    int? sectors,
    String? districtName,
    List<String>? interests,
  }) =>
      MimzUser(
        id: id,
        displayName: displayName ?? this.displayName,
        handle: handle ?? this.handle,
        email: email ?? this.email,
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        sectors: sectors ?? this.sectors,
        districtName: districtName ?? this.districtName,
        interests: interests ?? this.interests,
        createdAt: createdAt,
      );

  /// Demo user for development
  static MimzUser get demo => MimzUser(
        id: 'demo_001',
        displayName: 'Explorer',
        handle: '@mimz_explorer',
        email: 'user@mimz.app',
        xp: 12450,
        streak: 7,
        sectors: 3,
        districtName: 'Verdant Reach',
        interests: ['Technology', 'Science', 'History', 'Architecture', 'Music', 'Design'],
        createdAt: DateTime.now(),
      );
}
