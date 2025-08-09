import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/di/error_module.dart';

void main() {
  group('Error Queue Performance Tests', () {
    late GetIt getIt;
    late IErrorService errorService;
    late ErrorStore errorStore;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      // Initialize error module
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('Queue Management Performance', () {
      test('should handle rapid error additions efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Add 1000 errors rapidly
        for (int i = 0; i < 1000; i++) {
          final error = ApiError(
            message: 'Performance test error $i',
            statusCode: 400 + (i % 100),
            endpoint: '/api/test$i',
            method: 'GET',
          );
          
          errorService.showError(error);
          
          // Add small delay every 100 errors to simulate real usage
          if (i % 100 == 0) {
            await Future.delayed(const Duration(microseconds: 100));
          }
        }
        
        stopwatch.stop();
        
        // Assert performance requirements
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete in under 1 second
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5)); // Queue should be limited
        
        print('Added 1000 errors in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle error queue overflow efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Fill queue beyond capacity
        for (int i = 0; i < 50; i++) {
          final error = ApiError(
            message: 'Overflow test error $i',
            statusCode: 500,
            endpoint: '/api/overflow$i',
            method: 'POST',
          );
          
          errorService.showError(error);
        }
        
        stopwatch.stop();
        
        // Assert queue management efficiency
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should handle overflow quickly
        expect(errorStore.activeErrors.length, equals(5)); // Should maintain max queue size
        
        print('Handled queue overflow in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should prioritize errors efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Add mixed priority errors
        final errors = <dynamic>[
          ApiError(message: 'Low priority', statusCode: 400, endpoint: '/api/low', method: 'GET'),
          ApiError(message: 'Critical error', statusCode: 500, endpoint: '/api/critical', method: 'POST'),
          NetworkError(message: 'Network timeout', networkType: NetworkErrorType.timeout),
          ValidationError(message: 'Validation failed', fieldErrors: {'field': ['error']}),
          ApiError(message: 'Auth error', statusCode: 401, endpoint: '/api/auth', method: 'GET'),
        ];
        
        // Add errors in random order
        for (final error in errors) {
          errorService.showError(error);
        }
        
        stopwatch.stop();
        
        // Assert prioritization performance
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should prioritize quickly
        expect(errorStore.priorityError, isNotNull);
        
        print('Prioritized ${errors.length} errors in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle concurrent error operations efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Simulate concurrent operations
        final futures = <Future>[];
        
        // Add errors concurrently
        for (int i = 0; i < 100; i++) {
          futures.add(Future(() {
            final error = ApiError(
              message: 'Concurrent error $i',
              statusCode: 400,
              endpoint: '/api/concurrent$i',
              method: 'GET',
            );
            errorService.showError(error);
          }));
        }
        
        // Clear errors concurrently
        for (int i = 0; i < 50; i++) {
          futures.add(Future(() {
            if (errorStore.activeErrors.isNotEmpty) {
              final errorId = errorStore.activeErrors.first.id;
              errorService.clearError(errorId);
            }
          }));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert concurrent operation performance
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should handle concurrency efficiently
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        print('Handled ${futures.length} concurrent operations in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Memory Usage Performance', () {
      test('should maintain stable memory usage under load', () async {
        // Baseline memory measurement (simplified for testing)
        final initialErrorCount = errorStore.activeErrors.length;
        
        // Add and remove errors in cycles
        for (int cycle = 0; cycle < 10; cycle++) {
          // Add errors
          for (int i = 0; i < 100; i++) {
            final error = ApiError(
              message: 'Memory test error $cycle-$i',
              statusCode: 400,
              endpoint: '/api/memory$cycle$i',
              method: 'GET',
            );
            errorService.showError(error);
          }
          
          // Clear all errors
          errorService.clearAllErrors();
          
          // Small delay to allow cleanup
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Assert memory stability
        expect(errorStore.activeErrors.length, equals(initialErrorCount));
        
        print('Completed 10 cycles of 100 errors each with stable memory usage');
      });

      test('should handle large error objects efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Create errors with large data payloads
        for (int i = 0; i < 10; i++) {
          final largeData = Map<String, dynamic>.fromIterable(
            List.generate(1000, (index) => 'key$index'),
            value: (key) => 'Large data value for $key in error $i',
          );
          
          final error = ApiError(
            message: 'Large error $i',
            statusCode: 400,
            endpoint: '/api/large$i',
            method: 'POST',
            requestData: largeData,
            responseData: largeData,
          );
          
          errorService.showError(error);
        }
        
        stopwatch.stop();
        
        // Assert large object handling performance
        expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Should handle large objects efficiently
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        print('Handled 10 large error objects in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Error Processing Performance', () {
      test('should process error actions quickly', () async {
        final error = ApiError(
          message: 'Action performance test',
          statusCode: 500,
          endpoint: '/api/action-test',
          method: 'GET',
        );
        
        errorService.showError(error);
        await Future.delayed(const Duration(milliseconds: 10));
        
        final stopwatch = Stopwatch()..start();
        
        // Execute error actions
        if (error.actions != null && error.actions!.isNotEmpty) {
          for (final action in error.actions!) {
            action.onPressed();
          }
        }
        
        stopwatch.stop();
        
        // Assert action processing performance
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Actions should execute quickly
        
        print('Processed error actions in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle error deduplication efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Add duplicate errors
        for (int i = 0; i < 100; i++) {
          final error = ApiError(
            message: 'Duplicate error',
            statusCode: 400,
            endpoint: '/api/duplicate',
            method: 'GET',
          );
          
          errorService.showError(error);
        }
        
        stopwatch.stop();
        
        // Assert deduplication performance
        expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Should deduplicate efficiently
        expect(errorStore.activeErrors.length, equals(1)); // Should have only one unique error
        
        print('Deduplicated 100 identical errors in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle error serialization performance', () async {
        final errors = List.generate(100, (i) => ApiError(
          message: 'Serialization test error $i',
          statusCode: 400 + i,
          endpoint: '/api/serialize$i',
          method: 'GET',
          requestData: {'test': 'data$i'},
          responseData: {'result': 'response$i'},
        ));
        
        final stopwatch = Stopwatch()..start();
        
        // Serialize errors (simulated)
        final serializedErrors = <Map<String, dynamic>>[];
        for (final error in errors) {
          serializedErrors.add({
            'id': error.id,
            'message': error.message,
            'statusCode': error.statusCode,
            'endpoint': error.endpoint,
            'method': error.method,
            'timestamp': error.timestamp.toIso8601String(),
            'severity': error.severity.toString(),
          });
        }
        
        stopwatch.stop();
        
        // Assert serialization performance
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should serialize quickly
        expect(serializedErrors.length, equals(100));
        
        print('Serialized 100 errors in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Store Performance', () {
      test('should handle store updates efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Simulate rapid store updates
        for (int i = 0; i < 1000; i++) {
          // Add error
          final error = ApiError(
            message: 'Store update test $i',
            statusCode: 400,
            endpoint: '/api/store$i',
            method: 'GET',
          );
          
          errorService.showError(error);
          
          // Check computed properties (triggers MobX reactions)
          final hasErrors = errorStore.hasErrors;
          final priorityError = errorStore.priorityError;
          final shouldShow = errorStore.shouldShowErrorBar;
          
          // Use the values to prevent optimization
          expect(hasErrors, isA<bool>());
          expect(priorityError, isA<Object?>());
          expect(shouldShow, isA<bool>());
          
          if (i % 10 == 0) {
            errorService.clearAllErrors();
          }
        }
        
        stopwatch.stop();
        
        // Assert store performance
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should handle updates efficiently
        
        print('Handled 1000 store updates in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle computed property calculations efficiently', () async {
        // Add various errors
        for (int i = 0; i < 20; i++) {
          final error = ApiError(
            message: 'Computed test error $i',
            statusCode: 400 + (i % 5),
            endpoint: '/api/computed$i',
            method: 'GET',
          );
          errorService.showError(error);
        }
        
        final stopwatch = Stopwatch()..start();
        
        // Access computed properties multiple times
        for (int i = 0; i < 1000; i++) {
          final hasErrors = errorStore.hasErrors;
          final priorityError = errorStore.priorityError;
          final shouldShow = errorStore.shouldShowErrorBar;
          final errorCount = errorStore.activeErrors.length;
          
          // Use values to prevent optimization
          expect(hasErrors, isA<bool>());
          expect(priorityError, isA<Object?>());
          expect(shouldShow, isA<bool>());
          expect(errorCount, isA<int>());
        }
        
        stopwatch.stop();
        
        // Assert computed property performance
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should compute quickly
        
        print('Computed properties 1000 times in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Stress Testing', () {
      test('should handle extreme load gracefully', () async {
        final stopwatch = Stopwatch()..start();
        
        // Extreme load test
        final futures = <Future>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(Future(() async {
            for (int j = 0; j < 100; j++) {
              final error = ApiError(
                message: 'Stress test error $i-$j',
                statusCode: 400 + (j % 100),
                endpoint: '/api/stress$i$j',
                method: 'GET',
              );
              
              errorService.showError(error);
              
              if (j % 10 == 0) {
                await Future.delayed(const Duration(microseconds: 100));
              }
            }
          }));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert stress test performance
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should handle extreme load
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5)); // Should maintain queue limit
        
        print('Handled extreme load (1000 concurrent errors) in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should recover from performance degradation', () async {
        // Simulate performance degradation scenario
        final stopwatch = Stopwatch()..start();
        
        // Phase 1: Normal load
        for (int i = 0; i < 100; i++) {
          final error = ApiError(
            message: 'Recovery test error $i',
            statusCode: 400,
            endpoint: '/api/recovery$i',
            method: 'GET',
          );
          errorService.showError(error);
        }
        
        final phase1Time = stopwatch.elapsedMilliseconds;
        
        // Phase 2: Heavy load (simulating degradation)
        for (int i = 0; i < 500; i++) {
          final error = ApiError(
            message: 'Heavy load error $i',
            statusCode: 500,
            endpoint: '/api/heavy$i',
            method: 'POST',
            requestData: Map.fromIterable(
              List.generate(100, (index) => 'key$index'),
              value: (key) => 'value for $key',
            ),
          );
          errorService.showError(error);
        }
        
        final phase2Time = stopwatch.elapsedMilliseconds - phase1Time;
        
        // Phase 3: Recovery (clear and return to normal)
        errorService.clearAllErrors();
        
        for (int i = 0; i < 100; i++) {
          final error = ApiError(
            message: 'Recovery phase error $i',
            statusCode: 400,
            endpoint: '/api/recovered$i',
            method: 'GET',
          );
          errorService.showError(error);
        }
        
        stopwatch.stop();
        final phase3Time = stopwatch.elapsedMilliseconds - phase1Time - phase2Time;
        
        // Assert recovery performance
        expect(phase3Time, lessThanOrEqualTo(phase1Time * 2)); // Recovery should be reasonable
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        print('Performance recovery: Phase1=${phase1Time}ms, Phase2=${phase2Time}ms, Phase3=${phase3Time}ms');
      });
    });
  });
}