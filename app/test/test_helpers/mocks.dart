import 'package:mocktail/mocktail.dart';
import 'package:mimz_app/services/api_client.dart';
import 'package:mimz_app/services/auth_service.dart';
import 'package:mimz_app/services/audio_service.dart';
import 'package:mimz_app/services/location_service.dart';
import 'package:mimz_app/services/gemini_live_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockAuthService extends Mock implements AuthService {}
class MockAudioService extends Mock implements AudioService {}
class MockLocationService extends Mock implements LocationService {}
class MockGeminiLiveClient extends Mock implements GeminiLiveClient {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void registerFallbackValues() {
  // Add fallbacks for any custom types used in mocktail's any() or captureAny()
}
