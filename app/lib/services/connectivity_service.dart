import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

enum ConnectivityStatus {
  online,
  noInternet,
  backendUnavailable,
}

class ConnectivityService extends StateNotifier<ConnectivityStatus> {
  final ApiClient _apiClient;
  Timer? _timer;

  ConnectivityService(this._apiClient) : super(ConnectivityStatus.online) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    // 1. Check Internet Connection
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasInternet = true;
      }
    } catch (_) {
      hasInternet = false;
    }

    if (!hasInternet) {
      if (state != ConnectivityStatus.noInternet) {
        state = ConnectivityStatus.noInternet;
      }
      return;
    }

    // 2. Check Backend Health
    final isBackendHealthy = await _apiClient.checkHealth();
    
    if (!isBackendHealthy) {
      if (state != ConnectivityStatus.backendUnavailable) {
        state = ConnectivityStatus.backendUnavailable;
      }
      return;
    }

    // 3. Online
    if (state != ConnectivityStatus.online) {
      state = ConnectivityStatus.online;
    }
  }

  Future<void> retryNow() async {
    await _checkStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
