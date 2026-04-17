import '../lib/deeplink.dart';

/// Example demonstrating how to use the DesktopDeeplinkParser
/// for parsing command-line arguments in desktop applications
void main(List<String> args) async {
  final parser = DesktopDeeplinkParser();

  print('Desktop Deeplink Parser Example');
  print('===================================');

  // Example command line arguments
  final examples = [
    ['iot://iot/device-list'],
    ['--verbose', 'iot://iot/device-detail?id=123', '--debug'],
    ['iot://iot/monitoring?dashboard=main&timerange=24h'],
    ['iot://settings/preferences'],
    ['iot://iot/search?query=temperature%20sensor&filter=active'],
  ];

  for (int i = 0; i < examples.length; i++) {
    final testArgs = examples[i];
    print('\nExample ${i + 1}: ${testArgs.join(' ')}');
    
    try {
      // Parse the deeplink from command line arguments
      final request = await parser.parse(testArgs);
      
      print('✓ Successfully parsed:');
      print('  Scheme: ${request.scheme}');
      print('  Module: ${request.module}');
      print('  Feature: ${request.feature}');
      print('  Parameters: ${request.parameters}');
      print('  Original URL: ${request.originalUrl}');
      print('  Valid: ${request.isValid()}');
      
    } catch (e) {
      print('✗ Parsing failed: $e');
    }
  }

  // Demonstrate validation
  print('\n\nValidation Examples');
  print('==================');
  
  final validationExamples = [
    'iot://iot/device-list',
    'iot://invalid-module/feature',
    'http://iot/device-list',
    'iot://iot/device-list?',
    'iot://iot/device-list?id==123',
  ];

  for (final url in validationExamples) {
    final isValid = parser.isValidFormat(url);
    print('${isValid ? '✓' : '✗'} $url');
  }

  // Show parser configuration
  print('\n\nParser Configuration');
  print('===================');
  print('Supported schemes: ${DesktopDeeplinkParser.supportedSchemes}');
  print('Max URL length: ${DesktopDeeplinkParser.maxUrlLength}');
  print('Max component length: ${DesktopDeeplinkParser.maxComponentLength}');
  print('Max parameter count: ${DesktopDeeplinkParser.maxParameterCount}');

  // If actual command line arguments were provided, parse them
  if (args.isNotEmpty) {
    print('\n\nActual Command Line Arguments');
    print('============================');
    print('Args: ${args.join(' ')}');
    
    try {
      final request = await parser.parse(args);
      print('✓ Successfully parsed actual arguments:');
      print('  URL: ${request.toString()}');
      print('  Module: ${request.module}');
      print('  Feature: ${request.feature}');
      if (request.parameters.isNotEmpty) {
        print('  Parameters:');
        request.parameters.forEach((key, value) {
          print('    $key = $value');
        });
      }
    } catch (e) {
      print('✗ Failed to parse actual arguments: $e');
    }
  }
}