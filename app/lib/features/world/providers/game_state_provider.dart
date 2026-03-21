import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/providers.dart';
import '../../../data/models/game_state.dart';
import '../../../data/models/squad.dart';
import '../../../data/models/event.dart';

final gameStateProvider =
    AsyncNotifierProvider<GameStateNotifier, GameStateSnapshot?>(
  GameStateNotifier.new,
);

class GameStateNotifier extends AsyncNotifier<GameStateSnapshot?> {
  @override
  Future<GameStateSnapshot?> build() async {
    final cached = await GameStateCacheStore.instance.read();
    if (cached != null) {
      unawaited(
        ref.read(telemetryServiceProvider).track(
              'game_state_cache_hit',
              route: '/world',
              metadata: {
                'hasActiveEvent': cached.activeEvent != null,
                'hasPrimaryAction': true,
              },
              dedupeKey: 'game-state-cache-hit',
            ),
      );
      Future.microtask(() => refresh(source: 'background_refresh'));
      return cached;
    }
    return _fetch(
      bootstrapIfMissing: true,
      source: 'cold_start',
      instrument: true,
    );
  }

  Future<GameStateSnapshot?> load({
    bool force = false,
    bool bootstrapIfMissing = true,
  }) async {
    if (!force && state.valueOrNull != null) {
      return state.valueOrNull;
    }
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncLoading();
    }
    final next = await AsyncValue.guard(
      () => _fetch(
        bootstrapIfMissing: bootstrapIfMissing,
        source: previous == null ? 'bootstrap_resolve' : 'manual_refresh',
        instrument: previous == null,
      ),
    );
    state = next.hasError && previous != null ? AsyncData(previous) : next;
    return state.valueOrNull;
  }

  Future<void> refresh({String source = 'manual_refresh'}) async {
    await load(force: true, bootstrapIfMissing: source != 'manual_refresh');
  }

  void seed(GameStateSnapshot snapshot) {
    state = AsyncData(snapshot);
  }

  Future<GameStateSnapshot?> _fetch({
    required bool bootstrapIfMissing,
    required String source,
    bool instrument = false,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    final startedAt = DateTime.now();
    try {
      final response = await apiClient.getGameState();
      await GameStateCacheStore.instance.write(response);
      if (instrument) {
        unawaited(
          telemetry.track(
            'game_state_fetch_succeeded',
            route: '/world',
            metadata: {
              'source': source,
              'durationMs': DateTime.now().difference(startedAt).inMilliseconds,
              'bootstrapIfMissing': bootstrapIfMissing,
              'hasActiveEvent': response['activeEvent'] != null,
              'hasHeroBanner': response['worldHeroBanner'] != null,
            },
          ),
        );
      }
      return GameStateSnapshot.fromJson(response);
    } on DioException catch (e) {
      if (bootstrapIfMissing && e.response?.statusCode == 404) {
        await apiClient.bootstrap();
        final response = await apiClient.getGameState();
        await GameStateCacheStore.instance.write(response);
        if (instrument) {
          unawaited(
            telemetry.track(
              'game_state_fetch_bootstrapped',
              route: '/world',
              metadata: {
                'source': source,
                'durationMs': DateTime.now().difference(startedAt).inMilliseconds,
              },
            ),
          );
        }
        return GameStateSnapshot.fromJson(response);
      }
      if (instrument) {
        unawaited(
          telemetry.track(
            'game_state_fetch_failed',
            route: '/world',
            metadata: {
              'source': source,
              'durationMs': DateTime.now().difference(startedAt).inMilliseconds,
              'statusCode': e.response?.statusCode,
              'type': e.type.name,
            },
          ),
        );
      }
      rethrow;
    }
  }
}

class GameStateCacheStore {
  GameStateCacheStore._();

  static final instance = GameStateCacheStore._();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  static const _cacheKey = 'mimz_cached_game_state_v1';

  Future<GameStateSnapshot?> read() async {
    try {
      final raw = await _storage.read(key: _cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return GameStateSnapshot.fromJson(
        decoded.map((key, value) => MapEntry('$key', value)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> rawState) async {
    try {
      await _storage.write(key: _cacheKey, value: jsonEncode(rawState));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _cacheKey);
    } catch (_) {}
  }
}

final canonicalDistrictProvider = Provider((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.district;
});

final canonicalNextRecommendedRouteProvider = Provider<String?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.nextRecommendedRoute;
});

final showMeetMimzPromptProvider = Provider<bool>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.showMeetMimzPrompt ?? false;
});

final canonicalMissionProvider = Provider<String?>((ref) {
  final snapshot = ref.watch(gameStateProvider).valueOrNull;
  return snapshot?.missionSummary?.title ?? snapshot?.currentMission;
});

final canonicalMissionSummaryProvider = Provider<MissionSummaryModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.missionSummary;
});

final canonicalActiveEventProvider = Provider<MimzEvent?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.activeEvent;
});

final eventZonesProvider = Provider<List<EventZoneModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.eventZones ?? const [];
});

final activeConflictsProvider = Provider<List<ConflictStateModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.activeConflicts ?? const [];
});

final structureProgressProvider = Provider<StructureProgressModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.structureProgress;
});

final structureEffectsProvider = Provider<StructureEffectsModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.structureEffects;
});

final gameStateNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.notifications ?? const [];
});

final leaderboardSnippetsProvider = Provider<List<LeaderboardSummaryModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.leaderboardSnippets ?? const [];
});

final canonicalSquadSummaryProvider = Provider<SquadSummaryModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.squadSummary;
});

final rankStateProvider = Provider<RankStateModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.rankState;
});

final districtHealthSummaryProvider = Provider<DistrictHealthSummaryModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.districtHealthSummary;
});

final worldHeroBannerProvider = Provider<HeroBannerModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.worldHeroBanner;
});

final recommendedPrimaryActionProvider = Provider<RecommendedActionModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.recommendedPrimaryAction;
});

final recommendedSecondaryActionProvider = Provider<RecommendedActionModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.recommendedSecondaryAction;
});

final canonicalSquadProvider = Provider<Squad?>((ref) {
  return ref.watch(canonicalSquadSummaryProvider)?.squad;
});

final canonicalSquadMembersProvider = Provider<List<SquadMember>>((ref) {
  return ref.watch(canonicalSquadSummaryProvider)?.members ?? const [];
});

final canonicalSquadMissionsProvider = Provider<List<SquadMission>>((ref) {
  return ref.watch(canonicalSquadSummaryProvider)?.missions ?? const [];
});
