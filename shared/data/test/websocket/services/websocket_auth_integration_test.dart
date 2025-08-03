import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';

@GenerateMocks([SharedPreferenceHelper])
import 'websocket_auth_integration_test.mocks.dart';

void main() {
  group('WebSocketAuthIntegration', () {
    late WebSocketAuthIntegration authIntegration;
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;

    setUp(() {
      mockSharedPreferenceHelper = MockSharedPreferenceHelper();
      authIntegration = WebSocketAuthIntegration(mockSharedPreferenceHelper);
    });

    group('Token Management', () {
      test('should get auth token successfully', () async {
        const testToken = 'test-jwt-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);

        final token = await authIntegration.getAuthToken();

        expect(token, equals(testToken));
        verify(mockSharedPreferenceHelper.authToken).called(1);
      });

      test('should return null when no token available', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => null);

        final token = await authIntegration.getAuthToken();

        expect(token, isNull);
        verify(mockSharedPreferenceHelper.authToken).called(1);
      });

      test('should return null when token is empty', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => '');

        final token = await authIntegration.getAuthToken();

        expect(token, isNull);
        verify(mockSharedPreferenceHelper.authToken).called(1);
      });

      test('should handle token retrieval errors', () async {
        when(mockSharedPreferenceHelper.authToken)
            .thenThrow(Exception('Storage error'));

        final token = await authIntegration.getAuthToken();

        expect(token, isNull);
        verify(mockSharedPreferenceHelper.authToken).called(1);
      });
    });

    group('Login Status', () {
      test('should check login status successfully', () async {
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);

        final isLoggedIn = await authIntegration.isLoggedIn();

        expect(isLoggedIn, isTrue);
        verify(mockSharedPreferenceHelper.isLoggedIn).called(1);
      });

      test('should return false when not logged in', () async {
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => false);

        final isLoggedIn = await authIntegration.isLoggedIn();

        expect(isLoggedIn, isFalse);
        verify(mockSharedPreferenceHelper.isLoggedIn).called(1);
      });

      test('should handle login status check errors', () async {
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenThrow(Exception('Storage error'));

        final isLoggedIn = await authIntegration.isLoggedIn();

        expect(isLoggedIn, isFalse);
        verify(mockSharedPreferenceHelper.isLoggedIn).called(1);
      });
    });

    group('Auth State Changes', () {
      test('should forward auth state changes', () async {
        final authStateController = StreamController<bool>.broadcast();
        when(mockSharedPreferenceHelper.authStateChanges)
            .thenAnswer((_) => authStateController.stream);

        final authStateChanges = <bool>[];
        final subscription = authIntegration.authStateChanges.listen(authStateChanges.add);

        // Emit auth state changes
        authStateController.add(true);
        authStateController.add(false);
        authStateController.add(true);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authStateChanges, equals([true, false, true]));

        await subscription.cancel();
        await authStateController.close();
      });
    });

    group('Token Refresh', () {
      test('should return null for token refresh (not implemented)', () async {
        final refreshedToken = await authIntegration.refreshToken();
        expect(refreshedToken, isNull);
      });
    });

    group('Factory Methods', () {
      test('should create token getter function', () {
        const testToken = 'test-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);

        final tokenGetter = authIntegration.createTokenGetter();
        expect(tokenGetter, isA<Future<String?> Function()>());

        // Test the created function
        tokenGetter().then((token) {
          expect(token, equals(testToken));
        });
      });

      test('should create token refresher function', () {
        final tokenRefresher = authIntegration.createTokenRefresher();
        
        // Should return null since refresh is not implemented
        expect(tokenRefresher, isNull);
      });
    });

    group('Integration', () {
      test('should work with WebSocket service creation', () async {
        const testToken = 'integration-test-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);

        final tokenGetter = authIntegration.createTokenGetter();
        final tokenRefresher = authIntegration.createTokenRefresher();

        // Test that the functions work as expected
        final token = await tokenGetter();
        expect(token, equals(testToken));
        expect(tokenRefresher, isNull);

        verify(mockSharedPreferenceHelper.authToken).called(1);
      });

      test('should handle auth integration lifecycle', () async {
        // Test login status
        when(mockSharedPreferenceHelper.isLoggedIn)
            .thenAnswer((_) async => true);
        
        final isLoggedIn = await authIntegration.isLoggedIn();
        expect(isLoggedIn, isTrue);

        // Test token retrieval
        const testToken = 'lifecycle-test-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);

        final token = await authIntegration.getAuthToken();
        expect(token, equals(testToken));

        // Test token refresh (should return null)
        final refreshedToken = await authIntegration.refreshToken();
        expect(refreshedToken, isNull);

        verify(mockSharedPreferenceHelper.isLoggedIn).called(1);
        verify(mockSharedPreferenceHelper.authToken).called(1);
      });
    });

    group('Error Resilience', () {
      test('should handle multiple concurrent token requests', () async {
        const testToken = 'concurrent-test-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);

        // Make multiple concurrent requests
        final futures = List.generate(5, (_) => authIntegration.getAuthToken());
        final results = await Future.wait(futures);

        // All should return the same token
        expect(results, everyElement(equals(testToken)));
        
        // Should have called the helper for each request
        verify(mockSharedPreferenceHelper.authToken).called(5);
      });

      test('should handle mixed success and failure scenarios', () async {
        // First call succeeds
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'success-token');

        final token1 = await authIntegration.getAuthToken();
        expect(token1, equals('success-token'));

        // Second call fails
        when(mockSharedPreferenceHelper.authToken)
            .thenThrow(Exception('Storage error'));

        final token2 = await authIntegration.getAuthToken();
        expect(token2, isNull);

        verify(mockSharedPreferenceHelper.authToken).called(2);
      });
    });
  });
}