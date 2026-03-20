import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mimz_app/features/auth/providers/auth_provider.dart';

void main() {
  group('bootstrapFailureMessage', () {
    test('returns explicit BootstrapFailure message', () {
      const failure = BootstrapFailure(message: 'Custom bootstrap error');
      expect(bootstrapFailureMessage(failure), 'Custom bootstrap error');
    });

    test('maps 401 responses to sign-in expired guidance', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/auth/bootstrap'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/bootstrap'),
          statusCode: 401,
        ),
      );
      expect(
        bootstrapFailureMessage(err),
        'Sign-in expired. Please sign in again.',
      );
    });

    test('maps network timeout/connectivity to retry guidance', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/auth/bootstrap'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        bootstrapFailureMessage(err),
        'Could not reach the server. Check your connection and retry.',
      );
    });
  });
}
