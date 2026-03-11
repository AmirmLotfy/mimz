import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which permissions have been granted
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
  PermissionsNotifier() : super(const PermissionsState());

  void grantLocation() => state = state.copyWith(location: true);
  void grantMicrophone() => state = state.copyWith(microphone: true);
  void grantCamera() => state = state.copyWith(camera: true);
}

/// Current onboarding step index
final onboardingStepProvider = StateProvider<int>((ref) => 0);

/// User's selected interests during onboarding
final interestsProvider = StateProvider<List<String>>((ref) => []);
