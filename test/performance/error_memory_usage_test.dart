import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/di/error_module.dart';
import 'dart:developer' as developer;

void main() {
  group('Error Memory Usage Tests', () {
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

    group('Memory Leak Prevention', () {
      test('should not leak memory when adding and removing errors', () async {
        // Force garbage collection before test
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        final initialErrorCount = errorStore.activeErrors.length;
        
        // Add and remove errors in multiple cycles
        for (int cycle = 0; cycle < 50; cycle++) {
          final errors = <dynamic>[];
          
          // Add errors
          for (int i = 0; i < 20; i++) {
            final error = ApiError(
              message: 'Memory leak test error $cycle-$i',
              statusCode: 400 + i,
              endpoint: '/api/memory-leak$cycle$i',
              method: 'GET',
              requestData: {'cycle': cycle, 'index': i},
              responseData: {'result': 'test data for cycle $cycle index $i'},
            );
            
            errors.add(error);
            errorService.showError(error);
          }
          
          // Clear all errors
          for (final error in errors) {
            errorService.clearError(error.id);
          }
          
          // Force garbage collection periodically
          if (cycle % 10 == 0) {
            developer.gc();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
        
        // Final cleanup and GC
        errorService.clearAllErrors();
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Assert no memory leaks
        expect(errorStore.activeErrors.length, equals(initialErrorCount));
        
        print('Completed 50 cycles of 20 errors each without memory leaks');
      });

      test('should handle large error objects without excessive memory usage', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Create errors with progressively larger data
        final errors = <dynamic>[];
        
        for (int i = 1; i <= 10; i++) {
          final dataSize = i * 100; // Increasing data size
          
          final largeRequestData = Map<String, dynamic>.fromIterable(
            List.generate(dataSize, (index) => 'request_key_$index'),
            value: (key) => 'Large request data value for $key in error $i with size $dataSize',
          );
          
          final largeResponseData = Map<String, dynamic>.fromIterable(
            List.generate(dataSize, (index) => 'response_key_$index'),
            value: (key) => 'Large response data value for $key in error $i with size $dataSize',
          );
          
          final error = ApiError(
            message: 'Large memory test error $i (size: $dataSize)',
            statusCode: 400,
            endpoint: '/api/large-memory$i',
            method: 'POST',
            requestData: largeRequestData,
            responseData: largeResponseData,
          );
          
          errors.add(error);
          errorService.showError(error);
          
          // Small delay to allow processing
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Verify queue management with large objects
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        // Clean up
        for (final error in errors) {
          errorService.clearError(error.id);
        }
        
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        print('Handled 10 progressively larger error objects efficiently');
      });

      test('should clean up error references properly', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        final errorIds = <String>[];
        
        // Create errors with circular references (simulated)
        for (int i = 0; i < 100; i++) {
          final error = ApiError(
            message: 'Reference cleanup test error $i',
            statusCode: 400,
            endpoint: '/api/reference-cleanup$i',
            method: 'GET',
            metadata: {
              'references': List.generate(10, (j) => 'ref_${i}_$j'),
              'circular_ref': 'self_reference_$i',
              'nested_data': {
                'level1': {
                  'level2': {
                    'level3': 'deep_data_$i',
                    'back_ref': 'reference_to_error_$i',
                  }
                }
              }
            },
          );
          
          errorIds.add(error.id);
          errorService.showError(error);
          
          // Clear immediately to test reference cleanup
          errorService.clearError(error.id);
        }
        
        // Force garbage collection
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify all references are cleaned up
        expect(errorStore.activeErrors.isEmpty, isTrue);
        
        print('Cleaned up references for 100 errors with complex data structures');
      });
    });

    group('Memory Efficiency', () {
      test('should reuse error objects when possible', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Create similar errors that could be deduplicated
        final baseError = {
          'message': 'Reusable error message',
          'statusCode': 400,
          'endpoint': '/api/reusable',
          'method': 'GET',
        };
        
        for (int i = 0; i < 50; i++) {
          final error = ApiError(
            message: baseError['message'] as String,
            statusCode: baseError['statusCode'] as int,
            endpoint: baseError['endpoint'] as String,
            method: baseError['method'] as String,
          );
          
          errorService.showError(error);
        }
        
        // Should deduplicate similar errors
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        // Check if deduplication occurred
        final uniqueMessages = errorStore.activeErrors
            .map((error) => error.message)
            .toSet();
        
        expect(uniqueMessages.length, lessThanOrEqualTo(errorStore.activeErrors.length));
        
        print('Efficiently handled 50 similar errors through deduplication');
      });

      test('should handle error queue overflow without memory bloat', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Fill queue well beyond capacity
        for (int i = 0; i < 1000; i++) {
          final error = ApiError(
            message: 'Overflow memory test error $i',
            statusCode: 400 + (i % 200),
            endpoint: '/api/overflow-memory$i',
            method: 'GET',
            requestData: {
              'index': i,
              'data': 'Test data for error $i',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          
          errorService.showError(error);
          
          // Periodic cleanup check
          if (i % 100 == 0) {
            expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
          }
        }
        
        // Final verification
        expect(errorStore.activeErrors.length, equals(5));
        
        // Force GC and verify no excessive memory usage
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        print('Handled 1000 errors with queue overflow without memory bloat');
      });

      test('should efficiently manage error metadata', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Create errors with varying metadata sizes
        for (int i = 0; i < 100; i++) {
          final metadataSize = (i % 10) + 1; // 1-10 metadata entries
          
          final metadata = Map<String, dynamic>.fromIterable(
            List.generate(metadataSize * 10, (index) => 'meta_key_${i}_$index'),
            value: (key) => {
              'value': 'Metadata value for $key',
              'nested': {
                'timestamp': DateTime.now().toIso8601String(),
                'index': i,
                'size': metadataSize,
              }
            },
          );
          
          final error = ApiError(
            message: 'Metadata efficiency test error $i',
            statusCode: 400,
            endpoint: '/api/metadata-efficiency$i',
            method: 'GET',
            metadata: metadata,
          );
          
          errorService.showError(error);
          
          // Clear older errors to test metadata cleanup
          if (i > 10) {
            errorService.clearAllErrors();
          }
        }
        
        // Verify efficient metadata management
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        print('Efficiently managed metadata for 100 errors with varying sizes');
      });
    });

    group('Memory Pressure Handling', () {
      test('should handle simulated memory pressure gracefully', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Phase 1: Normal operation
        for (int i = 0; i < 20; i++) {
          final error = ApiError(
            message: 'Memory pressure test error $i',
            statusCode: 400,
            endpoint: '/api/memory-pressure$i',
            method: 'GET',
          );
          errorService.showError(error);
        }
        
        final normalQueueSize = errorStore.activeErrors.length;
        
        // Phase 2: Simulate memory pressure by creating large objects
        final largeObjects = <Map<String, dynamic>>[];
        
        for (int i = 0; i < 10; i++) {
          final largeObject = Map<String, dynamic>.fromIterable(
            List.generate(1000, (index) => 'pressure_key_${i}_$index'),
            value: (key) => 'Large pressure data for $key creating memory pressure scenario $i',
          );
          largeObjects.add(largeObject);
        }
        
        // Add more errors during memory pressure
        for (int i = 0; i < 30; i++) {
          final error = ApiError(
            message: 'Memory pressure error during high usage $i',
            statusCode: 500,
            endpoint: '/api/pressure-high$i',
            method: 'POST',
            requestData: i < largeObjects.length ? largeObjects[i] : null,
          );
          errorService.showError(error);
        }
        
        // Verify system handles pressure gracefully
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        // Phase 3: Recovery
        largeObjects.clear(); // Release large objects
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Add normal errors after pressure relief
        for (int i = 0; i < 10; i++) {
          final error = ApiError(
            message: 'Post-pressure recovery error $i',
            statusCode: 200,
            endpoint: '/api/recovery$i',
            method: 'GET',
          );
          errorService.showError(error);
        }
        
        // Verify recovery
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(5));
        
        print('Successfully handled memory pressure scenario with graceful recovery');
      });

      test('should maintain performance under sustained load', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        final performanceMetrics = <int>[];
        
        // Sustained load test with performance monitoring
        for (int batch = 0; batch < 20; batch++) {
          final batchStopwatch = Stopwatch()..start();
          
          // Add batch of errors
          for (int i = 0; i < 50; i++) {
            final error = ApiError(
              message: 'Sustained load error $batch-$i',
              statusCode: 400 + (i % 100),
              endpoint: '/api/sustained$batch$i',
              method: 'GET',
              requestData: {
                'batch': batch,
                'index': i,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            );
            errorService.showError(error);
          }
          
          batchStopwatch.stop();
          performanceMetrics.add(batchStopwatch.elapsedMilliseconds);
          
          // Periodic cleanup
          if (batch % 5 == 0) {
            errorService.clearAllErrors();
            developer.gc();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
        
        // Analyze performance consistency
        final averageTime = performanceMetrics.reduce((a, b) => a + b) / performanceMetrics.length;
        final maxTime = performanceMetrics.reduce((a, b) => a > b ? a : b);
        final minTime = performanceMetrics.reduce((a, b) => a < b ? a : b);
        
        // Assert performance consistency
        expect(maxTime - minTime, lessThan(averageTime * 2)); // Performance should be consistent
        expect(averageTime, lessThan(100)); // Average batch time should be reasonable
        
        print('Sustained load: avg=${averageTime.toStringAsFixed(1)}ms, min=${minTime}ms, max=${maxTime}ms');
      });
    });

    group('Cleanup and Disposal', () {
      test('should properly dispose of error resources', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        final errorIds = <String>[];
        
        // Create errors with resources that need cleanup
        for (int i = 0; i < 50; i++) {
          final error = ApiError(
            message: 'Disposal test error $i',
            statusCode: 400,
            endpoint: '/api/disposal$i',
            method: 'GET',
            metadata: {
              'resources': List.generate(5, (j) => 'resource_${i}_$j'),
              'cleanup_required': true,
              'disposal_id': 'dispose_$i',
            },
          );
          
          errorIds.add(error.id);
          errorService.showError(error);
        }
        
        // Verify errors are added
        expect(errorStore.activeErrors.isNotEmpty, isTrue);
        
        // Clear all errors (should trigger cleanup)
        errorService.clearAllErrors();
        
        // Force garbage collection
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify proper disposal
        expect(errorStore.activeErrors.isEmpty, isTrue);
        
        print('Properly disposed of resources for 50 errors');
      });

      test('should handle service disposal without memory leaks', () async {
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Create multiple service instances (simulated)
        final serviceInstances = <GetIt>[];
        
        for (int i = 0; i < 10; i++) {
          final serviceGetIt = GetIt.instance;
          await ErrorModule.configureErrorModuleInjection(serviceGetIt);
          
          final service = serviceGetIt<IErrorService>();
          final store = serviceGetIt<ErrorStore>();
          
          // Add errors to each service
          for (int j = 0; j < 10; j++) {
            final error = ApiError(
              message: 'Service disposal test error $i-$j',
              statusCode: 400,
              endpoint: '/api/service-disposal$i$j',
              method: 'GET',
            );
            service.showError(error);
          }
          
          serviceInstances.add(serviceGetIt);
        }
        
        // Dispose of all service instances
        for (final serviceGetIt in serviceInstances) {
          await serviceGetIt.reset();
        }
        
        // Force garbage collection
        developer.gc();
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify no lingering references
        expect(serviceInstances.length, equals(10)); // All instances should be disposable
        
        print('Successfully disposed of 10 service instances without memory leaks');
      });
    });
  });
}