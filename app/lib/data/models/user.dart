/// User model
class MimzUser {
  static const _unset = Object();
  final String id;
  final String displayName;
  final String handle;
  final String? email;
  final int xp;
  final int streak;
  final int sectors;
  final String districtName;
  final List<String> interests;
  
  // Profile Media
  final String? profileImageUrl;
  final String? storagePath;

  // Personalization
  final String? preferredName;
  final String? ageBand;
  final String? studyWorkStatus;
  final String? majorOrProfession;

  // Preferences
  final String difficultyPreference;
  final String squadPreference;
  final String? voicePreference;

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
    this.profileImageUrl,
    this.storagePath,
    this.preferredName,
    this.ageBand,
    this.studyWorkStatus,
    this.majorOrProfession,
    this.difficultyPreference = 'dynamic',
    this.squadPreference = 'social',
    this.voicePreference,
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
        profileImageUrl: json['profileImageUrl'] as String?,
        storagePath: json['storagePath'] as String?,
        preferredName: json['preferredName'] as String?,
        ageBand: json['ageBand'] as String?,
        studyWorkStatus: json['studyWorkStatus'] as String?,
        majorOrProfession: json['majorOrProfession'] as String?,
        difficultyPreference: json['difficultyPreference'] as String? ?? 'dynamic',
        squadPreference: json['squadPreference'] as String? ?? 'social',
        voicePreference: json['voicePreference'] as String?,
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
        'profileImageUrl': profileImageUrl,
        'storagePath': storagePath,
        'preferredName': preferredName,
        'ageBand': ageBand,
        'studyWorkStatus': studyWorkStatus,
        'majorOrProfession': majorOrProfession,
        'difficultyPreference': difficultyPreference,
        'squadPreference': squadPreference,
        'voicePreference': voicePreference,
        'createdAt': createdAt.toIso8601String(),
      };

  MimzUser copyWith({
    String? displayName,
    String? handle,
    Object? email = _unset,
    int? xp,
    int? streak,
    int? sectors,
    String? districtName,
    List<String>? interests,
    Object? profileImageUrl = _unset,
    Object? storagePath = _unset,
    Object? preferredName = _unset,
    Object? ageBand = _unset,
    Object? studyWorkStatus = _unset,
    Object? majorOrProfession = _unset,
    String? difficultyPreference,
    String? squadPreference,
    Object? voicePreference = _unset,
  }) =>
      MimzUser(
        id: id,
        displayName: displayName ?? this.displayName,
        handle: handle ?? this.handle,
        email: identical(email, _unset) ? this.email : email as String?,
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        sectors: sectors ?? this.sectors,
        districtName: districtName ?? this.districtName,
        interests: interests ?? this.interests,
        profileImageUrl: identical(profileImageUrl, _unset)
            ? this.profileImageUrl
            : profileImageUrl as String?,
        storagePath: identical(storagePath, _unset)
            ? this.storagePath
            : storagePath as String?,
        preferredName: identical(preferredName, _unset)
            ? this.preferredName
            : preferredName as String?,
        ageBand: identical(ageBand, _unset) ? this.ageBand : ageBand as String?,
        studyWorkStatus: identical(studyWorkStatus, _unset)
            ? this.studyWorkStatus
            : studyWorkStatus as String?,
        majorOrProfession: identical(majorOrProfession, _unset)
            ? this.majorOrProfession
            : majorOrProfession as String?,
        difficultyPreference: difficultyPreference ?? this.difficultyPreference,
        squadPreference: squadPreference ?? this.squadPreference,
        voicePreference: identical(voicePreference, _unset)
            ? this.voicePreference
            : voicePreference as String?,
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
