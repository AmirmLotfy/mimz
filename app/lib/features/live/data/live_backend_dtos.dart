// Request/response DTOs for the live backend endpoints.
//
// Strongly typed models prevent ad-hoc map access throughout the codebase.

// ─── Ephemeral Token ─────────────────────────────────────

class EphemeralTokenRequest {
  final String sessionType; // 'onboarding', 'quiz', 'vision_quest'

  const EphemeralTokenRequest({required this.sessionType});

  Map<String, dynamic> toJson() => {'sessionType': sessionType};
}

class EphemeralTokenResponse {
  final String token;
  final String model;
  final DateTime expiresAt;
  final List<Map<String, dynamic>> tools;

  EphemeralTokenResponse({
    required this.token,
    required this.model,
    required this.expiresAt,
    required this.tools,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  factory EphemeralTokenResponse.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>? ?? json;
    return EphemeralTokenResponse(
      token: session['token'] as String,
      model: session['model'] as String? ??
          (throw const FormatException('Backend must provide model in ephemeral token response')),
      expiresAt: DateTime.parse(session['expiresAt'] as String),
      tools: (session['tools'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}

// ─── Tool Execution ──────────────────────────────────────

class ToolExecutionRequest {
  final String toolName;
  final Map<String, dynamic> arguments;
  final String sessionId;
  final String correlationId;

  const ToolExecutionRequest({
    required this.toolName,
    required this.arguments,
    required this.sessionId,
    required this.correlationId,
  });

  Map<String, dynamic> toJson() => {
    'toolName': toolName,
    'args': arguments,
    'sessionId': sessionId,
    'correlationId': correlationId,
  };
}

class ToolExecutionResponse {
  final bool success;
  final Map<String, dynamic> data;
  final String? error;
  final String? correlationId;

  const ToolExecutionResponse({
    required this.success,
    required this.data,
    this.error,
    this.correlationId,
  });

  factory ToolExecutionResponse.fromJson(Map<String, dynamic> json) {
    return ToolExecutionResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>? ?? json,
      error: json['error'] as String?,
      correlationId: json['correlationId'] as String?,
    );
  }
}

// ─── Round Lifecycle ─────────────────────────────────────

class RoundStartPayload {
  final String roundId;
  final String topic;
  final String difficulty;
  final int questionCount;

  const RoundStartPayload({
    required this.roundId,
    required this.topic,
    required this.difficulty,
    required this.questionCount,
  });

  factory RoundStartPayload.fromJson(Map<String, dynamic> json) {
    return RoundStartPayload(
      roundId: json['roundId'] as String? ?? '',
      topic: json['topic'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'medium',
      questionCount: json['questionCount'] as int? ?? 5,
    );
  }
}

class RoundEndPayload {
  final String roundId;
  final int totalScore;
  final int questionsAnswered;
  final int correctAnswers;
  final int maxStreak;
  final int sectorsEarned;
  final Map<String, int> materialsEarned;

  const RoundEndPayload({
    required this.roundId,
    required this.totalScore,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.maxStreak,
    required this.sectorsEarned,
    required this.materialsEarned,
  });

  factory RoundEndPayload.fromJson(Map<String, dynamic> json) {
    return RoundEndPayload(
      roundId: json['roundId'] as String? ?? '',
      totalScore: json['totalScore'] as int? ?? 0,
      questionsAnswered: json['questionsAnswered'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? 0,
      sectorsEarned: json['sectorsEarned'] as int? ?? 0,
      materialsEarned: (json['materialsEarned'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ?? {},
    );
  }
}

// ─── Onboarding ──────────────────────────────────────────

class OnboardingSavePayload {
  final List<String> interests;
  final String districtName;
  final String displayName;

  const OnboardingSavePayload({
    required this.interests,
    required this.districtName,
    required this.displayName,
  });

  factory OnboardingSavePayload.fromJson(Map<String, dynamic> json) {
    return OnboardingSavePayload(
      interests: (json['interests'] as List?)?.cast<String>() ?? [],
      districtName: json['districtName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }
}

// ─── Vision Quest ────────────────────────────────────────

class VisionQuestValidationPayload {
  final String questId;
  final String objectIdentified;
  final double confidence;
  final bool isValid;
  final String? structureUnlocked;
  final String? tier;

  const VisionQuestValidationPayload({
    required this.questId,
    required this.objectIdentified,
    required this.confidence,
    required this.isValid,
    this.structureUnlocked,
    this.tier,
  });

  factory VisionQuestValidationPayload.fromJson(Map<String, dynamic> json) {
    return VisionQuestValidationPayload(
      questId: json['questId'] as String? ?? '',
      objectIdentified: json['objectIdentified'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isValid: json['isValid'] as bool? ?? false,
      structureUnlocked: json['structureUnlocked'] as String?,
      tier: json['tier'] as String?,
    );
  }
}

// ─── Session Log ─────────────────────────────────────────

class SessionLogEntry {
  final String sessionId;
  final String event;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SessionLogEntry({
    required this.sessionId,
    required this.event,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'event': event,
    'timestamp': timestamp.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };
}
