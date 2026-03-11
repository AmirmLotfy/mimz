import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/district.dart';

/// Current district data
final districtProvider = StateNotifierProvider<DistrictNotifier, AsyncValue<District>>((ref) {
  return DistrictNotifier(ref);
});

class DistrictNotifier extends StateNotifier<AsyncValue<District>> {
  final Ref _ref;

  DistrictNotifier(this._ref) : super(AsyncValue.data(District.demo)) {
    _fetchDistrict();
  }

  Future<void> _fetchDistrict() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getDistrict();
      state = AsyncValue.data(District.fromJson(response));
    } catch (e) {
      // Keep demo data on failure
    }
  }

  Future<void> refresh() async => _fetchDistrict();
}

/// Current mission text
final currentMissionProvider = StateProvider<String>((ref) => 'The Verdant Sproutlings');
