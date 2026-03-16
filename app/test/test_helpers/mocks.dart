import 'package:mocktail/mocktail.dart';
import 'package:mimz_app/services/api_client.dart';
import 'package:mimz_app/services/auth_service.dart';
import 'package:mimz_app/services/audio_service.dart';
import 'package:mimz_app/services/location_service.dart';
import 'package:mimz_app/services/gemini_live_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mimz_app/services/settings_service.dart';
import 'package:mimz_app/features/live/application/live_session_controller.dart';

import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

class MockApiClient extends Mock implements ApiClient {}
class MockAuthService extends Mock implements AuthService {}
class MockAudioService extends Mock implements AudioService {}
class MockLocationService extends Mock implements LocationService {}
class MockGeminiLiveClient extends Mock implements GeminiLiveClient {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockSettingsService extends Mock implements SettingsService {}

class MockLiveSessionController extends Mock implements LiveSessionController {}

void registerFallbackValues() {
  // Add fallbacks for any custom types used in mocktail's any() or captureAny()
}
