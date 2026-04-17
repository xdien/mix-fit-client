import 'package:test/test.dart';
import 'package:deeplink/core/models/route_configuration.dart';

void main() {
  group('RouteConfiguration', () {
    late RouteConfiguration config;

    setUp(() {
      config = RouteConfiguration(
        routes: {
          'iot': ModuleConfiguration(
            features: {
              'device-list': const RouteDefinition(
                screen: 'DeviceListScreen',
                permissions: ['iot.view'],
                parameters: {
                  'type': ParameterDefinition(required: false, type: 'string'),
                },
              ),
              'device-detail': const RouteDefinition(
                screen: 'DeviceDetailScreen',
                permissions: ['iot.view'],
                parameters: {
                  'id': ParameterDefinition(required: true, type: 'string'),
                },
              ),
            },
          ),
          'settings': ModuleConfiguration(
            features: {
              'preferences': const RouteDefinition(
                screen: 'PreferencesScreen',
                permissions: ['settings.view'],
              ),
            },
          ),
        },
        fallbacks: const FallbackConfiguration(
          defaultRoute: 'DashboardScreen',
          permissionDeniedRoute: 'AccessDeniedScreen',
          notFoundRoute: 'NotFoundScreen',
          errorRoute: 'ErrorScreen',
        ),
      );
    });

    test('should get module configuration', () {
      final iotModule = config.getModule('iot');
      expect(iotModule, isNotNull);
      expect(iotModule!.features.length, equals(2));
    });

    test('should return null for non-existent module', () {
      final nonExistentModule = config.getModule('non-existent');
      expect(nonExistentModule, isNull);
    });

    test('should get specific route configuration', () {
      final route = config.getRoute('iot', 'device-list');
      expect(route, isNotNull);
      expect(route!.screen, equals('DeviceListScreen'));
      expect(route.permissions, contains('iot.view'));
    });

    test('should return null for non-existent route', () {
      final route = config.getRoute('iot', 'non-existent');
      expect(route, isNull);
    });

    test('should check if route exists', () {
      expect(config.hasRoute('iot', 'device-list'), isTrue);
      expect(config.hasRoute('iot', 'non-existent'), isFalse);
      expect(config.hasRoute('non-existent', 'device-list'), isFalse);
    });

    test('should get available modules', () {
      final modules = config.getAvailableModules();
      expect(modules, containsAll(['iot', 'settings']));
      expect(modules.length, equals(2));
    });

    test('should get available features for module', () {
      final features = config.getAvailableFeatures('iot');
      expect(features, containsAll(['device-list', 'device-detail']));
      expect(features.length, equals(2));
    });

    test('should return empty list for non-existent module features', () {
      final features = config.getAvailableFeatures('non-existent');
      expect(features, isEmpty);
    });

    test('should serialize to JSON', () {
      final json = config.toJson();
      expect(json['routes'], isA<Map<String, dynamic>>());
      expect(json['fallbacks'], isA<Map<String, dynamic>>());
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('should deserialize from JSON', () {
      final json = {
        'routes': {
          'test': {
            'feature1': {
              'screen': 'TestScreen',
              'permissions': ['test.view'],
              'parameters': {
                'param1': {
                  'required': true,
                  'type': 'string',
                }
              },
              'requiresAuth': true,
            }
          }
        },
        'fallbacks': {
          'default': 'DefaultScreen',
          'permission_denied': 'AccessDeniedScreen',
          'not_found': 'NotFoundScreen',
          'error': 'ErrorScreen',
        },
        'metadata': {
          'version': '1.0.0',
        }
      };

      final deserializedConfig = RouteConfiguration.fromJson(json);
      expect(deserializedConfig.routes.length, equals(1));
      expect(deserializedConfig.hasRoute('test', 'feature1'), isTrue);
      expect(deserializedConfig.fallbacks.defaultRoute, equals('DefaultScreen'));
      expect(deserializedConfig.metadata['version'], equals('1.0.0'));
    });
  });

  group('RouteDefinition', () {
    test('should check if parameter is required', () {
      const routeDef = RouteDefinition(
        screen: 'TestScreen',
        parameters: {
          'required_param': ParameterDefinition(required: true),
          'optional_param': ParameterDefinition(required: false),
        },
      );

      expect(routeDef.isParameterRequired('required_param'), isTrue);
      expect(routeDef.isParameterRequired('optional_param'), isFalse);
      expect(routeDef.isParameterRequired('non_existent'), isFalse);
    });

    test('should get required parameters', () {
      const routeDef = RouteDefinition(
        screen: 'TestScreen',
        parameters: {
          'required1': ParameterDefinition(required: true),
          'optional1': ParameterDefinition(required: false),
          'required2': ParameterDefinition(required: true),
        },
      );

      final requiredParams = routeDef.getRequiredParameters();
      expect(requiredParams, containsAll(['required1', 'required2']));
      expect(requiredParams.length, equals(2));
    });

    test('should serialize and deserialize correctly', () {
      const original = RouteDefinition(
        screen: 'TestScreen',
        permissions: ['test.view', 'test.edit'],
        parameters: {
          'param1': ParameterDefinition(
            required: true,
            type: 'string',
            defaultValue: 'default',
            pattern: r'^\w+$',
            description: 'Test parameter',
          ),
        },
        fallbackRoute: 'FallbackScreen',
        requiresAuth: false,
        metadata: {'custom': 'value'},
      );

      final json = original.toJson();
      final deserialized = RouteDefinition.fromJson(json);

      expect(deserialized.screen, equals(original.screen));
      expect(deserialized.permissions, equals(original.permissions));
      expect(deserialized.fallbackRoute, equals(original.fallbackRoute));
      expect(deserialized.requiresAuth, equals(original.requiresAuth));
      expect(deserialized.metadata, equals(original.metadata));
      expect(deserialized.parameters.length, equals(1));
      
      final param = deserialized.parameters['param1']!;
      expect(param.required, isTrue);
      expect(param.type, equals('string'));
      expect(param.defaultValue, equals('default'));
      expect(param.pattern, equals(r'^\w+$'));
      expect(param.description, equals('Test parameter'));
    });

    test('should handle legacy parameter format', () {
      final json = {
        'screen': 'TestScreen',
        'permissions': ['test.view'],
        'parameters': {
          'param1': 'required',
          'param2': 'optional',
        },
      };

      final routeDef = RouteDefinition.fromJson(json);
      expect(routeDef.parameters['param1']!.required, isTrue);
      expect(routeDef.parameters['param2']!.required, isFalse);
    });
  });

  group('ParameterDefinition', () {
    test('should have default values', () {
      const paramDef = ParameterDefinition();
      expect(paramDef.required, isFalse);
      expect(paramDef.type, equals('string'));
      expect(paramDef.defaultValue, isNull);
      expect(paramDef.pattern, isNull);
      expect(paramDef.description, isNull);
    });

    test('should serialize and deserialize correctly', () {
      const original = ParameterDefinition(
        required: true,
        type: 'int',
        defaultValue: '42',
        pattern: r'^\d+$',
        description: 'A number parameter',
      );

      final json = original.toJson();
      final deserialized = ParameterDefinition.fromJson(json);

      expect(deserialized.required, equals(original.required));
      expect(deserialized.type, equals(original.type));
      expect(deserialized.defaultValue, equals(original.defaultValue));
      expect(deserialized.pattern, equals(original.pattern));
      expect(deserialized.description, equals(original.description));
    });
  });

  group('FallbackConfiguration', () {
    test('should serialize and deserialize correctly', () {
      const original = FallbackConfiguration(
        defaultRoute: 'DefaultScreen',
        permissionDeniedRoute: 'AccessDeniedScreen',
        notFoundRoute: 'NotFoundScreen',
        errorRoute: 'ErrorScreen',
      );

      final json = original.toJson();
      final deserialized = FallbackConfiguration.fromJson(json);

      expect(deserialized.defaultRoute, equals(original.defaultRoute));
      expect(deserialized.permissionDeniedRoute, equals(original.permissionDeniedRoute));
      expect(deserialized.notFoundRoute, equals(original.notFoundRoute));
      expect(deserialized.errorRoute, equals(original.errorRoute));
    });
  });
}