import 'package:test/test.dart';
import '../../../lib/core/services/desktop_deeplink_parser.dart';
import '../../../lib/core/models/deeplink_request.dart';
import '../../../lib/core/errors/deeplink_error.dart';

void main() {
  group('DesktopDeeplinkParser', () {
    late DesktopDeeplinkParser parser;

    setUp(() {
      parser = DesktopDeeplinkParser();
    });

    group('isValidFormat', () {
      group('valid URLs', () {
        test('should accept basic valid URL', () {
          expect(parser.isValidFormat('iot://iot/device-list'), isTrue);
        });

        test('should accept URL with parameters', () {
          expect(parser.isValidFormat('iot://iot/device-detail?id=123'), isTrue);
        });

        test('should accept URL with multiple parameters', () {
          expect(parser.isValidFormat('iot://iot/monitoring?dashboard=main&timerange=24h'), isTrue);
        });

        test('should accept URL with encoded parameters', () {
          expect(parser.isValidFormat('iot://iot/search?query=device%20name'), isTrue);
        });

        test('should accept module and feature with underscores', () {
          expect(parser.isValidFormat('iot://device_manager/device_list'), isTrue);
        });

        test('should accept module and feature with hyphens', () {
          expect(parser.isValidFormat('iot://device-manager/device-list'), isTrue);
        });

        test('should accept settings module', () {
          expect(parser.isValidFormat('iot://settings/preferences'), isTrue);
        });

        test('should accept empty parameter values in middle', () {
          expect(parser.isValidFormat('iot://iot/search?query=&filter=active'), isTrue);
        });
      });

      group('invalid URLs', () {
        test('should reject empty URL', () {
          expect(parser.isValidFormat(''), isFalse);
        });

        test('should reject unsupported scheme', () {
          expect(parser.isValidFormat('http://iot/device-list'), isFalse);
          expect(parser.isValidFormat('custom://iot/device-list'), isFalse);
        });

        test('should reject malformed URLs', () {
          expect(parser.isValidFormat('iot:/iot/device-list'), isFalse);
          expect(parser.isValidFormat('iot:///device-list'), isFalse);
          expect(parser.isValidFormat('iot://iot/'), isFalse);
          expect(parser.isValidFormat('iot://iot'), isFalse);
        });

        test('should reject URLs with invalid characters in module', () {
          expect(parser.isValidFormat('iot://io@t/device-list'), isFalse);
          expect(parser.isValidFormat('iot://io.t/device-list'), isFalse);
          expect(parser.isValidFormat('iot://io t/device-list'), isFalse);
        });

        test('should reject URLs with invalid characters in feature', () {
          expect(parser.isValidFormat('iot://iot/device@list'), isFalse);
          expect(parser.isValidFormat('iot://iot/device.list'), isFalse);
          expect(parser.isValidFormat('iot://iot/device list'), isFalse);
        });

        test('should reject module starting with number', () {
          expect(parser.isValidFormat('iot://1iot/device-list'), isFalse);
        });

        test('should reject feature starting with number', () {
          expect(parser.isValidFormat('iot://iot/1device-list'), isFalse);
        });

        test('should reject malformed query parameters', () {
          expect(parser.isValidFormat('iot://iot/device-list?'), isFalse);
          expect(parser.isValidFormat('iot://iot/device-list?&'), isFalse);
          expect(parser.isValidFormat('iot://iot/device-list?id='), isFalse);
          expect(parser.isValidFormat('iot://iot/device-list?=123'), isFalse);
          expect(parser.isValidFormat('iot://iot/device-list?id==123'), isFalse);
          expect(parser.isValidFormat('iot://iot/device-list?id=123&'), isFalse);
          expect(parser.isValidFormat('iot://iot/device-list?id=123&&type=sensor'), isFalse);
        });

        test('should reject URLs exceeding maximum length', () {
          final longUrl = 'iot://iot/device-list?' + 'a' * 2048;
          expect(parser.isValidFormat(longUrl), isFalse);
        });

        test('should reject components exceeding maximum length', () {
          final longModule = 'a' * 101;
          expect(parser.isValidFormat('iot://$longModule/device-list'), isFalse);
          
          final longFeature = 'a' * 101;
          expect(parser.isValidFormat('iot://iot/$longFeature'), isFalse);
        });
      });
    });

    group('parse', () {
      group('successful parsing', () {
        test('should parse basic URL from single argument', () async {
          final args = ['iot://iot/device-list'];
          final result = await parser.parse(args);

          expect(result.scheme, equals('iot'));
          expect(result.module, equals('iot'));
          expect(result.feature, equals('device-list'));
          expect(result.parameters, isEmpty);
          expect(result.originalUrl, equals('iot://iot/device-list'));
          expect(result.isValid(), isTrue);
        });

        test('should parse URL with parameters', () async {
          final args = ['iot://iot/device-detail?id=123&type=sensor'];
          final result = await parser.parse(args);

          expect(result.scheme, equals('iot'));
          expect(result.module, equals('iot'));
          expect(result.feature, equals('device-detail'));
          expect(result.parameters, hasLength(2));
          expect(result.parameters['id'], equals('123'));
          expect(result.parameters['type'], equals('sensor'));
          expect(result.originalUrl, equals('iot://iot/device-detail?id=123&type=sensor'));
        });

        test('should parse URL with encoded parameters', () async {
          final args = ['iot://iot/search?query=device%20name&filter=active%2Binactive'];
          final result = await parser.parse(args);

          expect(result.parameters['query'], equals('device name'));
          expect(result.parameters['filter'], equals('active+inactive'));
        });

        test('should find deeplink URL among multiple arguments', () async {
          final args = ['--verbose', 'iot://iot/device-list', '--debug'];
          final result = await parser.parse(args);

          expect(result.scheme, equals('iot'));
          expect(result.module, equals('iot'));
          expect(result.feature, equals('device-list'));
        });

        test('should parse settings module URL', () async {
          final args = ['iot://settings/preferences'];
          final result = await parser.parse(args);

          expect(result.scheme, equals('iot'));
          expect(result.module, equals('settings'));
          expect(result.feature, equals('preferences'));
        });

        test('should handle empty parameter values', () async {
          final args = ['iot://iot/search?query=&filter=active'];
          final result = await parser.parse(args);

          expect(result.parameters['query'], equals(''));
          expect(result.parameters['filter'], equals('active'));
        });

        test('should normalize scheme to lowercase', () async {
          final args = ['IOT://iot/device-list'];
          final result = await parser.parse(args);

          expect(result.scheme, equals('iot'));
        });
      });

      group('parsing errors', () {
        test('should throw error for empty arguments', () async {
          expect(
            () => parser.parse([]),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error when no valid deeplink found', () async {
          final args = ['--verbose', '--debug', 'not-a-deeplink'];
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error for invalid URL format', () async {
          final args = ['iot:/iot/device-list'];
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error for unsupported scheme', () async {
          final args = ['http://iot/device-list'];
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error for malformed query parameters', () async {
          final args = ['iot://iot/device-list?id==123'];
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error for duplicate parameters', () async {
          final args = ['iot://iot/device-list?id=123&id=456'];
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error for too many parameters', () async {
          final paramPairs = List.generate(51, (i) => 'param$i=value$i');
          final queryString = paramPairs.join('&');
          final args = ['iot://iot/device-list?$queryString'];
          
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error for parameter key too long', () async {
          final longKey = 'a' * 101;
          final args = ['iot://iot/device-list?$longKey=value'];
          
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw error for parameter value too long', () async {
          final longValue = 'a' * 101;
          final args = ['iot://iot/device-list?key=$longValue'];
          
          expect(
            () => parser.parse(args),
            throwsA(isA<DeeplinkParsingError>()),
          );
        });

        test('should throw detailed error for query parameter parsing failure', () async {
          // Create a URL that passes basic validation but fails parameter parsing
          // We'll use a valid format but with duplicate keys to trigger parsing error
          final args = ['iot://iot/device-list?id=123&id=456'];
          
          try {
            await parser.parse(args);
            fail('Expected DeeplinkParsingError');
          } catch (e) {
            expect(e, isA<DeeplinkParsingError>());
            final error = e as DeeplinkParsingError;
            expect(error.message, contains('Duplicate parameter key'));
          }
        });
      });
    });

    group('edge cases', () {
      test('should handle URLs with special characters in parameters', () async {
        final args = ['iot://iot/search?query=test%21%40%23%24%25'];
        final result = await parser.parse(args);
        
        expect(result.parameters['query'], equals('test!@#\$%'));
      });

      test('should handle URLs with unicode characters in parameters', () async {
        final args = ['iot://iot/search?query=%E2%9C%93%E2%9C%94'];
        final result = await parser.parse(args);
        
        expect(result.parameters['query'], equals('✓✔'));
      });

      test('should handle maximum valid parameter count', () async {
        final paramPairs = List.generate(50, (i) => 'param$i=value$i');
        final queryString = paramPairs.join('&');
        final args = ['iot://iot/device-list?$queryString'];
        
        final result = await parser.parse(args);
        expect(result.parameters, hasLength(50));
        expect(result.parameters['param0'], equals('value0'));
        expect(result.parameters['param49'], equals('value49'));
      });

      test('should handle maximum valid component lengths', () async {
        final maxModule = 'a' * 100;
        final maxFeature = 'b' * 100;
        final args = ['iot://$maxModule/$maxFeature'];
        
        final result = await parser.parse(args);
        expect(result.module, equals(maxModule));
        expect(result.feature, equals(maxFeature));
      });

      test('should handle complex valid identifiers', () async {
        final args = ['iot://device_manager_v2/device-list-advanced'];
        final result = await parser.parse(args);
        
        expect(result.module, equals('device_manager_v2'));
        expect(result.feature, equals('device-list-advanced'));
      });
    });

    group('static properties', () {
      test('should provide supported schemes', () {
        final schemes = DesktopDeeplinkParser.supportedSchemes;
        expect(schemes, contains('iot'));
        expect(schemes, hasLength(1));
      });

      test('should provide configuration constants', () {
        expect(DesktopDeeplinkParser.maxUrlLength, equals(2048));
        expect(DesktopDeeplinkParser.maxComponentLength, equals(100));
        expect(DesktopDeeplinkParser.maxParameterCount, equals(50));
      });
    });

    group('error details', () {
      test('should provide detailed error information for parsing failures', () async {
        try {
          await parser.parse(['iot://iot/device-list?id==123']);
          fail('Expected DeeplinkParsingError');
        } catch (e) {
          expect(e, isA<DeeplinkParsingError>());
          final error = e as DeeplinkParsingError;
          expect(error.message, contains('No valid deeplink URL found'));
        }
      });

      test('should provide context for missing components error', () async {
        try {
          await parser.parse(['not-a-deeplink']);
          fail('Expected DeeplinkParsingError');
        } catch (e) {
          expect(e, isA<DeeplinkParsingError>());
          final error = e as DeeplinkParsingError;
          expect(error.message, contains('No valid deeplink URL found'));
        }
      });
    });

    group('performance', () {
      test('should handle parsing multiple URLs efficiently', () async {
        final urls = List.generate(100, (i) => 'iot://iot/device-$i?id=$i');
        
        final stopwatch = Stopwatch()..start();
        for (final url in urls) {
          await parser.parse([url]);
        }
        stopwatch.stop();
        
        // Should complete within reasonable time (less than 1 second for 100 URLs)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should validate format efficiently for many URLs', () {
        final urls = List.generate(1000, (i) => 'iot://iot/device-$i?id=$i');
        
        final stopwatch = Stopwatch()..start();
        for (final url in urls) {
          parser.isValidFormat(url);
        }
        stopwatch.stop();
        
        // Should complete within reasonable time (less than 100ms for 1000 validations)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}