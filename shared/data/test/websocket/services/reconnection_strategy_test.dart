import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/websocket.dart';

void main() {
  group('ReconnectionStrategy', () {
    late ReconnectionStrategy strategy;

    setUp(() {
      strategy = ReconnectionStrategy();
    });

    group('Default Configuration', () {
      test('should use default backoff intervals', () {
        // Allow for jitter (±10%)
        expect(strategy.calculateDelay(1).inMilliseconds, inInclusiveRange(1000, 1100));
        expect(strategy.calculateDelay(2).inMilliseconds, inInclusiveRange(2000, 2200));
        expect(strategy.calculateDelay(3).inMilliseconds, inInclusiveRange(5000, 5500));
        expect(strategy.calculateDelay(4).inMilliseconds, inInclusiveRange(10000, 11000));
        expect(strategy.calculateDelay(5).inMilliseconds, inInclusiveRange(30000, 33000));
        expect(strategy.calculateDelay(6).inMilliseconds, inInclusiveRange(60000, 66000));
      });

      test('should return zero delay for invalid attempt numbers', () {
        expect(strategy.calculateDelay(0), equals(Duration.zero));
        expect(strategy.calculateDelay(-1), equals(Duration.zero));
      });

      test('should use exponential backoff after predefined intervals', () {
        // After 6 predefined intervals, should use exponential backoff
        final delay7 = strategy.calculateDelay(7);
        final delay8 = strategy.calculateDelay(8);
        
        // Should be exponential (2^1 = 2 seconds, 2^2 = 4 seconds)
        expect(delay7.inSeconds, greaterThanOrEqualTo(2));
        expect(delay8.inSeconds, greaterThanOrEqualTo(4));
      });

      test('should cap exponential backoff at 5 minutes', () {
        // Very high attempt number should be capped at 5 minutes (300 seconds)
        final delay = strategy.calculateDelay(20);
        expect(delay.inSeconds, lessThanOrEqualTo(300 + 30)); // +30 for jitter
      });
    });

    group('Custom Configuration', () {
      test('should use custom backoff intervals', () {
        final customIntervals = [
          const Duration(milliseconds: 500),
          const Duration(seconds: 1),
          const Duration(seconds: 3),
        ];
        
        final customStrategy = ReconnectionStrategy(
          backoffIntervals: customIntervals,
        );

        // Allow for jitter (±10%)
        expect(customStrategy.calculateDelay(1).inMilliseconds, inInclusiveRange(500, 550));
        expect(customStrategy.calculateDelay(2).inMilliseconds, inInclusiveRange(1000, 1100));
        expect(customStrategy.calculateDelay(3).inMilliseconds, inInclusiveRange(3000, 3300));
      });

      test('should use custom jitter factor', () {
        final noJitterStrategy = ReconnectionStrategy(jitterFactor: 0.0);
        final highJitterStrategy = ReconnectionStrategy(jitterFactor: 0.5);

        // With no jitter, delays should be exact
        expect(noJitterStrategy.calculateDelay(1), equals(const Duration(seconds: 1)));
        expect(noJitterStrategy.calculateDelay(2), equals(const Duration(seconds: 2)));

        // With high jitter, delays should vary (but we can't test exact values due to randomness)
        final delay1 = highJitterStrategy.calculateDelay(1);
        final delay2 = highJitterStrategy.calculateDelay(1);
        
        // Both should be around 1 second but may differ due to jitter
        expect(delay1.inMilliseconds, greaterThanOrEqualTo(1000));
        expect(delay1.inMilliseconds, lessThanOrEqualTo(1500)); // 1s + 50% jitter
      });
    });

    group('Jitter Behavior', () {
      test('should add jitter to delays', () {
        final delays = <Duration>[];
        
        // Generate multiple delays for the same attempt
        for (int i = 0; i < 10; i++) {
          delays.add(strategy.calculateDelay(1));
        }

        // Not all delays should be exactly the same due to jitter
        final uniqueDelays = delays.toSet();
        expect(uniqueDelays.length, greaterThan(1));

        // All delays should be around 1 second (±10% jitter)
        for (final delay in delays) {
          expect(delay.inMilliseconds, greaterThanOrEqualTo(1000));
          expect(delay.inMilliseconds, lessThanOrEqualTo(1100)); // 1s + 10% jitter
        }
      });

      test('should handle zero jitter factor', () {
        final noJitterStrategy = ReconnectionStrategy(jitterFactor: 0.0);
        
        // Multiple calls should return the same delay
        final delay1 = noJitterStrategy.calculateDelay(1);
        final delay2 = noJitterStrategy.calculateDelay(1);
        final delay3 = noJitterStrategy.calculateDelay(1);

        expect(delay1, equals(delay2));
        expect(delay2, equals(delay3));
      });
    });

    group('Reconnection Decision', () {
      test('should allow reconnection within max attempts', () {
        expect(strategy.shouldAttemptReconnection(1, 5), isTrue);
        expect(strategy.shouldAttemptReconnection(3, 5), isTrue);
        expect(strategy.shouldAttemptReconnection(5, 5), isTrue);
      });

      test('should not allow reconnection beyond max attempts', () {
        expect(strategy.shouldAttemptReconnection(6, 5), isFalse);
        expect(strategy.shouldAttemptReconnection(10, 5), isFalse);
      });

      test('should handle edge cases', () {
        expect(strategy.shouldAttemptReconnection(0, 5), isFalse);
        expect(strategy.shouldAttemptReconnection(-1, 5), isFalse);
        expect(strategy.shouldAttemptReconnection(1, 0), isFalse);
        expect(strategy.shouldAttemptReconnection(1, -1), isFalse);
      });

      test('should not allow reconnection for non-recoverable errors', () {
        final nonRecoverableError = WebSocketError(
          type: WebSocketErrorType.invalidMessage,
          message: 'Invalid message',
          timestamp: DateTime.now(),
          isRecoverable: false,
        );

        expect(strategy.shouldAttemptReconnection(1, 5, lastError: nonRecoverableError), isFalse);
      });

      test('should allow reconnection for recoverable errors', () {
        final recoverableError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        expect(strategy.shouldAttemptReconnection(1, 5, lastError: recoverableError), isTrue);
      });
    });

    group('Max Delay', () {
      test('should return correct max delay for default configuration', () {
        expect(strategy.maxDelay, equals(const Duration(minutes: 5)));
      });

      test('should return custom max delay when specified', () {
        final customStrategy = ReconnectionStrategy(
          maxDelay: const Duration(seconds: 30),
        );

        expect(customStrategy.maxDelay, equals(const Duration(seconds: 30)));
      });

      test('should return default max delay when not specified', () {
        final defaultStrategy = ReconnectionStrategy();
        expect(defaultStrategy.maxDelay, equals(const Duration(minutes: 5)));
      });
    });

    group('Reset Functionality', () {
      test('should reset without errors', () {
        strategy.reset();
        
        // Strategy should still work after reset (allow for jitter)
        expect(strategy.calculateDelay(1).inMilliseconds, inInclusiveRange(1000, 1100));
        expect(strategy.shouldAttemptReconnection(1, 5), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle very large attempt numbers', () {
        final delay = strategy.calculateDelay(20); // Use a reasonable large number
        
        // Should be capped and not cause overflow
        expect(delay.inSeconds, lessThanOrEqualTo(330)); // 300s + jitter
        expect(delay.inSeconds, greaterThanOrEqualTo(300));
      });

      test('should handle single interval configuration', () {
        final singleIntervalStrategy = ReconnectionStrategy(
          backoffIntervals: [const Duration(seconds: 2)],
        );

        expect(singleIntervalStrategy.calculateDelay(1).inMilliseconds, inInclusiveRange(2000, 2200));
        
        // Should use exponential backoff after the single interval
        final delay2 = singleIntervalStrategy.calculateDelay(2);
        expect(delay2.inSeconds, greaterThanOrEqualTo(2)); // 2^1 = 2 seconds
      });
    });

    group('Error-Aware Delay Calculation', () {
      test('should adjust delay for authentication errors', () {
        final authError = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Auth failed',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final normalDelay = strategy.calculateDelay(1);
        final authDelay = strategy.calculateDelayWithError(1, authError);
        
        // Auth error delay should be shorter (50% of normal)
        expect(authDelay.inMilliseconds, lessThan(normalDelay.inMilliseconds));
      });

      test('should adjust delay for server errors', () {
        final serverError = WebSocketError(
          type: WebSocketErrorType.serverError,
          message: 'Server error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final normalDelay = strategy.calculateDelay(1);
        final serverDelay = strategy.calculateDelayWithError(1, serverError);
        
        // Server error delay should be longer (150% of normal)
        expect(serverDelay.inMilliseconds, greaterThan(normalDelay.inMilliseconds));
      });

      test('should use standard delay for timeout errors', () {
        final timeoutError = WebSocketError(
          type: WebSocketErrorType.connectionTimeout,
          message: 'Timeout',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final normalDelay = strategy.calculateDelay(1);
        final timeoutDelay = strategy.calculateDelayWithError(1, timeoutError);
        
        // Should be approximately the same (within jitter range)
        expect((timeoutDelay.inMilliseconds - normalDelay.inMilliseconds).abs(), lessThan(200));
      });

      test('should adjust delay for heartbeat timeout errors', () {
        final heartbeatError = WebSocketError(
          type: WebSocketErrorType.heartbeatTimeout,
          message: 'Heartbeat timeout',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final normalDelay = strategy.calculateDelay(1);
        final heartbeatDelay = strategy.calculateDelayWithError(1, heartbeatError);
        
        // Heartbeat error delay should be shorter (70% of normal)
        expect(heartbeatDelay.inMilliseconds, lessThan(normalDelay.inMilliseconds));
      });
    });

    group('Error-Based Reconnection Decision', () {
      test('should not reconnect for non-recoverable error types', () {
        final nonRecoverableTypes = [
          WebSocketErrorType.invalidMessage,
          WebSocketErrorType.maxReconnectAttemptsExceeded,
          WebSocketErrorType.tokenRefreshFailed,
        ];

        for (final errorType in nonRecoverableTypes) {
          final error = WebSocketError(
            type: errorType,
            message: 'Test error',
            timestamp: DateTime.now(),
            isRecoverable: true, // Even if marked recoverable
          );

          expect(strategy.shouldReconnectForError(error, 1, 5), isFalse);
        }
      });

      test('should reconnect for recoverable error types', () {
        final recoverableTypes = [
          WebSocketErrorType.networkError,
          WebSocketErrorType.connectionTimeout,
          WebSocketErrorType.authenticationFailed,
          WebSocketErrorType.serverError,
          WebSocketErrorType.heartbeatTimeout,
          WebSocketErrorType.unexpectedDisconnection,
        ];

        for (final errorType in recoverableTypes) {
          final error = WebSocketError(
            type: errorType,
            message: 'Test error',
            timestamp: DateTime.now(),
            isRecoverable: true,
          );

          expect(strategy.shouldReconnectForError(error, 1, 5), isTrue);
        }
      });

      test('should not reconnect when max attempts exceeded', () {
        final recoverableError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        expect(strategy.shouldReconnectForError(recoverableError, 6, 5), isFalse);
      });

      test('should not reconnect for non-recoverable errors', () {
        final nonRecoverableError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: false,
        );

        expect(strategy.shouldReconnectForError(nonRecoverableError, 1, 5), isFalse);
      });
    });

    group('Bounds and Limits', () {
      test('should respect minimum delay', () {
        final customStrategy = ReconnectionStrategy(
          minDelay: const Duration(seconds: 2),
        );

        final delay = customStrategy.calculateDelay(1);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(2000));
      });

      test('should respect maximum delay', () {
        final customStrategy = ReconnectionStrategy(
          maxDelay: const Duration(seconds: 30),
        );

        // Very high attempt number should be capped
        final delay = customStrategy.calculateDelay(20);
        expect(delay.inSeconds, lessThanOrEqualTo(33)); // 30s + jitter
      });

      test('should provide access to configured bounds', () {
        final customStrategy = ReconnectionStrategy(
          minDelay: const Duration(seconds: 1),
          maxDelay: const Duration(minutes: 2),
        );

        expect(customStrategy.minDelay, equals(const Duration(seconds: 1)));
        expect(customStrategy.maxDelay, equals(const Duration(minutes: 2)));
      });

      test('should provide access to backoff intervals', () {
        final customIntervals = [
          const Duration(seconds: 1),
          const Duration(seconds: 3),
          const Duration(seconds: 7),
        ];

        final customStrategy = ReconnectionStrategy(
          backoffIntervals: customIntervals,
        );

        expect(customStrategy.backoffIntervals, equals(customIntervals));
      });
    });

    group('Performance', () {
      test('should calculate delays efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Calculate many delays
        for (int i = 1; i <= 100; i++) {
          strategy.calculateDelay(i);
        }
        
        stopwatch.stop();
        
        // Should complete quickly (less than 100ms for 100 calculations)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should calculate error-aware delays efficiently', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final stopwatch = Stopwatch()..start();
        
        // Calculate many delays with error
        for (int i = 1; i <= 100; i++) {
          strategy.calculateDelayWithError(i, error);
        }
        
        stopwatch.stop();
        
        // Should complete quickly (less than 100ms for 100 calculations)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}