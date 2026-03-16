import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

/// Tracks which permissions have been granted — persisted across restarts.
final permissionsProvider = StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});

class PermissionsState {
  final bool location;
  final bool microphone;
  final bool camera;

  const PermissionsState({
    this.location = false,
    this.microphone = false,
    this.camera = false,
  });

  bool get allGranted => location && microphone && camera;
  int get grantedCount => [location, microphone, camera].where((p) => p).length;

  PermissionsState copyWith({bool? location, bool? microphone, bool? camera}) =>
      PermissionsState(
        location: location ?? this.location,
        microphone: microphone ?? this.microphone,
        camera: camera ?? this.camera,
      );
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _kLocationRequested = 'perm_location_requested';
  static const _kMicrophoneRequested = 'perm_microphone_requested';
  static const _kCameraRequested = 'perm_camera_requested';

  PermissionsNotifier() : super(const PermissionsState()) {
    refresh();
  }

  /// Re-sync state with the current OS permissions.
  Future<void> refresh() async {
    final osLoc = await Permission.location.isGranted || await Permission.location.isLimited;
    final osMic = await Permission.microphone.isGranted;
    final osCam = await Permission.camera.isGranted;

    if (mounted) {
      state = PermissionsState(
        location: osLoc,
        microphone: osMic,
        camera: osCam,
      );
    }
  }

  Future<void> markLocationRequested() async {
    await _storage.write(key: _kLocationRequested, value: 'true');
    await refresh();
  }

  Future<void> markMicrophoneRequested() async {
    await _storage.write(key: _kMicrophoneRequested, value: 'true');
    await refresh();
  }

  Future<void> markCameraRequested() async {
    await _storage.write(key: _kCameraRequested, value: 'true');
    await refresh();
  }

  Future<void> grantLocation() async => markLocationRequested();
  Future<void> grantMicrophone() async => markMicrophoneRequested();
  Future<void> grantCamera() async => markCameraRequested();

  /// Reset all permissions — called on sign-out
  Future<void> resetAll() async {
    await _storage.delete(key: _kLocationRequested);
    await _storage.delete(key: _kMicrophoneRequested);
    await _storage.delete(key: _kCameraRequested);
    if (mounted) state = const PermissionsState();
  }
}

/// Current onboarding step index
final onboardingStepProvider = StateProvider<int>((ref) => 0);

/// User's selected interests during onboarding
final interestsProvider = StateProvider<List<String>>((ref) => []);

// ─── Onboarding Data State ────────────────────────────────

class OnboardingData {
  final String? preferredName;
  final String? ageBand;
  final String? studyWorkStatus;
  final String? majorOrProfession;
  final String difficultyPreference;
  final String squadPreference;
  final String districtName;

  const OnboardingData({
    this.preferredName,
    this.ageBand,
    this.studyWorkStatus,
    this.majorOrProfession,
    this.difficultyPreference = 'dynamic',
    this.squadPreference = 'social',
    this.districtName = '',
  });

  OnboardingData copyWith({
    String? preferredName,
    String? ageBand,
    String? studyWorkStatus,
    String? majorOrProfession,
    String? difficultyPreference,
    String? squadPreference,
    String? districtName,
  }) {
    return OnboardingData(
      preferredName: preferredName ?? this.preferredName,
      ageBand: ageBand ?? this.ageBand,
      studyWorkStatus: studyWorkStatus ?? this.studyWorkStatus,
      majorOrProfession: majorOrProfession ?? this.majorOrProfession,
      difficultyPreference: difficultyPreference ?? this.difficultyPreference,
      squadPreference: squadPreference ?? this.squadPreference,
      districtName: districtName ?? this.districtName,
    );
  }
}

class OnboardingDataNotifier extends StateNotifier<OnboardingData> {
  OnboardingDataNotifier() : super(const OnboardingData());

  void updateData(OnboardingData newData) {
    state = newData;
  }
  
  void updateField({
    String? preferredName,
    String? ageBand,
    String? studyWorkStatus,
    String? majorOrProfession,
    String? difficultyPreference,
    String? squadPreference,
    String? districtName,
  }) {
    state = state.copyWith(
      preferredName: preferredName,
      ageBand: ageBand,
      studyWorkStatus: studyWorkStatus,
      majorOrProfession: majorOrProfession,
      difficultyPreference: difficultyPreference,
      squadPreference: squadPreference,
      districtName: districtName,
    );
  }

  void reset() {
    state = const OnboardingData();
  }
}

final onboardingDataProvider = StateNotifierProvider<OnboardingDataNotifier, OnboardingData>((ref) {
  return OnboardingDataNotifier();
});
