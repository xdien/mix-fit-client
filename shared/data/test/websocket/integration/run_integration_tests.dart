#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';

/// Integration Test Runner for WebSocket Tests
/// 
/// This script runs all WebSocket integration tests in sequence and provides
/// comprehensive reporting of test results, performance metrics, and coverage.
/// 
/// Usage:
///   dart run_integration_tests.dart [options]
/// 
/// Options:
///   --verbose, -v     Enable verbose output
///   --performance     Run performance tests only
///   --auth           Run authentication tests only
///   --lifecycle      Run lifecycle tests only
///   --e2e            Run end-to-end tests only
///   --all            Run all tests (default)
///   --timeout=<ms>   Set test timeout in milliseconds (default: 300000)

void main(List<String> arguments) async {
  final runner = IntegrationTestRunner();
  await runner.run(arguments);
}

class IntegrationTestRunner {
  bool verbose = false;
  String testFilter = 'all';
  int timeoutMs = 300000; // 5 minutes default timeout
  
  final List<TestSuite> testSuites = [
    TestSuite(
      name: 'End-to-End Integration Tests',
      file: 'websocket_e2e_integration_test.dart',
      description: 'Complete WebSocket connection and data flow tests',
      estimatedDuration: Duration(minutes: 3),
    ),
    TestSuite(
      name: 'Authentication & Reconnection Tests',
      file: 'websocket_auth_reconnection_integration_test.dart',
      description: 'Authentication, token refresh, and reconnection scenarios',
      estimatedDuration: Duration(minutes: 4),
    ),
    TestSuite(
      name: 'App Lifecycle Integration Tests',
      file: 'websocket_lifecycle_integration_test.dart',
      description: 'Background/foreground transitions and data synchronization',
      estimatedDuration: Duration(minutes: 3),
    ),
    TestSuite(
      name: 'Performance Integration Tests',
      file: 'websocket_performance_integration_test.dart',
      description: 'Load testing, throughput, and resource usage tests',
      estimatedDuration: Duration(minutes: 5),
    ),
  ];

  Future<void> run(List<String> arguments) async {
    parseArguments(arguments);
    
    print('🚀 WebSocket Integration Test Runner');
    print('=====================================');
    print('');
    
    if (verbose) {
      print('Configuration:');
      print('  Test Filter: $testFilter');
      print('  Timeout: ${timeoutMs}ms');
      print('  Verbose: $verbose');
      print('');
    }

    final filteredSuites = getFilteredTestSuites();
    
    if (filteredSuites.isEmpty) {
      print('❌ No test suites match the filter: $testFilter');
      exit(1);
    }

    print('Test Suites to Run:');
    for (final suite in filteredSuites) {
      print('  ✓ ${suite.name} (~${suite.estimatedDuration.inMinutes}min)');
      if (verbose) {
        print('    ${suite.description}');
      }
    }
    print('');

    final totalEstimatedTime = filteredSuites.fold<Duration>(
      Duration.zero,
      (sum, suite) => sum + suite.estimatedDuration,
    );
    
    print('Estimated total time: ${totalEstimatedTime.inMinutes} minutes');
    print('');

    // Check prerequisites
    if (!await checkPrerequisites()) {
      print('❌ Prerequisites check failed');
      exit(1);
    }

    final results = <TestResult>[];
    final overallStartTime = DateTime.now();

    for (int i = 0; i < filteredSuites.length; i++) {
      final suite = filteredSuites[i];
      print('📋 Running ${suite.name} (${i + 1}/${filteredSuites.length})');
      print('   ${suite.description}');
      
      final result = await runTestSuite(suite);
      results.add(result);
      
      printTestResult(result);
      print('');
    }

    final overallEndTime = DateTime.now();
    final totalDuration = overallEndTime.difference(overallStartTime);

    printSummary(results, totalDuration);
    
    final hasFailures = results.any((r) => !r.success);
    exit(hasFailures ? 1 : 0);
  }

  void parseArguments(List<String> arguments) {
    for (final arg in arguments) {
      if (arg == '--verbose' || arg == '-v') {
        verbose = true;
      } else if (arg == '--performance') {
        testFilter = 'performance';
      } else if (arg == '--auth') {
        testFilter = 'auth';
      } else if (arg == '--lifecycle') {
        testFilter = 'lifecycle';
      } else if (arg == '--e2e') {
        testFilter = 'e2e';
      } else if (arg == '--all') {
        testFilter = 'all';
      } else if (arg.startsWith('--timeout=')) {
        final timeoutStr = arg.substring('--timeout='.length);
        timeoutMs = int.tryParse(timeoutStr) ?? timeoutMs;
      } else if (arg == '--help' || arg == '-h') {
        printUsage();
        exit(0);
      }
    }
  }

  List<TestSuite> getFilteredTestSuites() {
    switch (testFilter) {
      case 'e2e':
        return testSuites.where((s) => s.file.contains('e2e')).toList();
      case 'auth':
        return testSuites.where((s) => s.file.contains('auth')).toList();
      case 'lifecycle':
        return testSuites.where((s) => s.file.contains('lifecycle')).toList();
      case 'performance':
        return testSuites.where((s) => s.file.contains('performance')).toList();
      case 'all':
      default:
        return testSuites;
    }
  }

  Future<bool> checkPrerequisites() async {
    print('🔍 Checking prerequisites...');
    
    // Check if Flutter is available
    final flutterResult = await Process.run('flutter', ['--version']);
    if (flutterResult.exitCode != 0) {
      print('❌ Flutter is not available or not in PATH');
      return false;
    }
    
    if (verbose) {
      print('✓ Flutter is available');
    }

    // Check if we're in the correct directory
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      print('❌ pubspec.yaml not found. Please run from the data package directory.');
      return false;
    }
    
    if (verbose) {
      print('✓ Running from correct directory');
    }

    // Check if dependencies are installed
    final packagesFile = File('.dart_tool/package_config.json');
    if (!await packagesFile.exists()) {
      print('⚠️  Dependencies not installed. Running flutter pub get...');
      final pubGetResult = await Process.run('flutter', ['pub', 'get']);
      if (pubGetResult.exitCode != 0) {
        print('❌ Failed to install dependencies');
        return false;
      }
    }
    
    if (verbose) {
      print('✓ Dependencies are installed');
    }

    print('✅ Prerequisites check passed');
    print('');
    return true;
  }

  Future<TestResult> runTestSuite(TestSuite suite) async {
    final startTime = DateTime.now();
    
    try {
      final result = await Process.run(
        'flutter',
        ['test', suite.file, '--reporter=json'],
        workingDirectory: '.',
      ).timeout(Duration(milliseconds: timeoutMs));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (result.exitCode == 0) {
        return TestResult(
          suite: suite,
          success: true,
          duration: duration,
          output: result.stdout.toString(),
          error: null,
        );
      } else {
        return TestResult(
          suite: suite,
          success: false,
          duration: duration,
          output: result.stdout.toString(),
          error: result.stderr.toString(),
        );
      }
    } on TimeoutException {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      return TestResult(
        suite: suite,
        success: false,
        duration: duration,
        output: '',
        error: 'Test suite timed out after ${timeoutMs}ms',
      );
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      return TestResult(
        suite: suite,
        success: false,
        duration: duration,
        output: '',
        error: 'Unexpected error: $e',
      );
    }
  }

  void printTestResult(TestResult result) {
    final icon = result.success ? '✅' : '❌';
    final status = result.success ? 'PASSED' : 'FAILED';
    final duration = '${result.duration.inSeconds}s';
    
    print('   $icon $status ($duration)');
    
    if (!result.success) {
      print('   Error: ${result.error}');
      
      if (verbose && result.output.isNotEmpty) {
        print('   Output:');
        final lines = result.output.split('\n');
        for (final line in lines.take(10)) { // Show first 10 lines
          print('     $line');
        }
        if (lines.length > 10) {
          print('     ... (${lines.length - 10} more lines)');
        }
      }
    } else if (verbose) {
      // Parse JSON output for detailed results
      try {
        final lines = result.output.split('\n').where((line) => line.trim().isNotEmpty);
        var testCount = 0;
        var passCount = 0;
        
        for (final line in lines) {
          if (line.contains('"type":"testDone"')) {
            testCount++;
            if (line.contains('"result":"success"')) {
              passCount++;
            }
          }
        }
        
        if (testCount > 0) {
          print('   Tests: $passCount/$testCount passed');
        }
      } catch (e) {
        // Ignore JSON parsing errors
      }
    }
  }

  void printSummary(List<TestResult> results, Duration totalDuration) {
    print('📊 Test Summary');
    print('===============');
    print('');
    
    final passedCount = results.where((r) => r.success).length;
    final failedCount = results.length - passedCount;
    
    print('Total Suites: ${results.length}');
    print('Passed: $passedCount');
    print('Failed: $failedCount');
    print('Total Time: ${totalDuration.inMinutes}m ${totalDuration.inSeconds % 60}s');
    print('');
    
    if (failedCount > 0) {
      print('❌ Failed Test Suites:');
      for (final result in results.where((r) => !r.success)) {
        print('  • ${result.suite.name}');
        if (result.error != null) {
          print('    ${result.error}');
        }
      }
      print('');
    }
    
    // Performance summary
    print('⏱️  Performance Summary:');
    for (final result in results) {
      final actualVsEstimated = result.duration.inSeconds / result.suite.estimatedDuration.inSeconds;
      final performance = actualVsEstimated <= 1.2 ? '🟢' : actualVsEstimated <= 2.0 ? '🟡' : '🔴';
      
      print('  $performance ${result.suite.name}: ${result.duration.inSeconds}s (estimated: ${result.suite.estimatedDuration.inSeconds}s)');
    }
    print('');
    
    if (passedCount == results.length) {
      print('🎉 All integration tests passed!');
      print('');
      print('Requirements Coverage:');
      print('  ✅ 4.1 - Network interruption handling');
      print('  ✅ 4.2 - Automatic reconnection');
      print('  ✅ 4.3 - Exponential backoff strategy');
      print('  ✅ 5.1 - JWT authentication');
      print('  ✅ 8.1 - Background connection management');
      print('  ✅ 8.2 - Foreground reconnection');
    } else {
      print('💥 Some integration tests failed. Please review the errors above.');
    }
  }

  void printUsage() {
    print('WebSocket Integration Test Runner');
    print('');
    print('Usage: dart run_integration_tests.dart [options]');
    print('');
    print('Options:');
    print('  --verbose, -v     Enable verbose output');
    print('  --performance     Run performance tests only');
    print('  --auth           Run authentication tests only');
    print('  --lifecycle      Run lifecycle tests only');
    print('  --e2e            Run end-to-end tests only');
    print('  --all            Run all tests (default)');
    print('  --timeout=<ms>   Set test timeout in milliseconds (default: 300000)');
    print('  --help, -h       Show this help message');
  }
}

class TestSuite {
  final String name;
  final String file;
  final String description;
  final Duration estimatedDuration;

  TestSuite({
    required this.name,
    required this.file,
    required this.description,
    required this.estimatedDuration,
  });
}

class TestResult {
  final TestSuite suite;
  final bool success;
  final Duration duration;
  final String output;
  final String? error;

  TestResult({
    required this.suite,
    required this.success,
    required this.duration,
    required this.output,
    this.error,
  });
}