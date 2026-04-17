import 'dart:io';
import 'package:test/test.dart';
import 'package:deeplink/core/services/configuration_parser.dart';
import 'package:deeplink/core/models/route_configuration.dart';
import 'package:deeplink/core/models/permission_configuration.dart';

void main() {
  group('ConfigurationParser', () {
    group('parseRouteConfiguration', () {
      test('should parse valid route configuration', () {
        const jsonContent = '''
        {
          "routes": {
            "iot": {
              "device-list": {
                "screen": "DeviceListScreen",
                "permissions": ["iot.view"],
                "parameters": {
                  "type": {
                    "required": false,
                    "type": "string"
                  }
                }
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        final config = ConfigurationParser.parseRouteConfiguration(jsonContent);
        expect(config.routes.length, equals(1));
        expect(config.hasRoute('iot', 'device-list'), isTrue);
        expect(config.fallbacks.defaultRoute, equals('DashboardScreen'));
      });

      test('should throw ConfigurationError for invalid JSON', () {
        const invalidJson = '{ invalid json }';
        
        expect(
          () => ConfigurationParser.parseRouteConfiguration(invalidJson),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for empty routes', () {
        const jsonContent = '''
        {
          "routes": {},
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for invalid module name', () {
        const jsonContent = '''
        {
          "routes": {
            "Invalid-Module-Name!": {
              "feature": {
                "screen": "TestScreen"
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for invalid feature name', () {
        const jsonContent = '''
        {
          "routes": {
            "iot": {
              "Invalid Feature Name!": {
                "screen": "TestScreen"
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for empty screen name', () {
        const jsonContent = '''
        {
          "routes": {
            "iot": {
              "device-list": {
                "screen": "",
                "permissions": ["iot.view"]
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for invalid permission format', () {
        const jsonContent = '''
        {
          "routes": {
            "iot": {
              "device-list": {
                "screen": "DeviceListScreen",
                "permissions": ["invalid permission format!"]
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for invalid parameter type', () {
        const jsonContent = '''
        {
          "routes": {
            "iot": {
              "device-list": {
                "screen": "DeviceListScreen",
                "parameters": {
                  "param1": {
                    "required": true,
                    "type": "invalid_type"
                  }
                }
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for invalid regex pattern', () {
        const jsonContent = '''
        {
          "routes": {
            "iot": {
              "device-list": {
                "screen": "DeviceListScreen",
                "parameters": {
                  "param1": {
                    "required": true,
                    "type": "string",
                    "pattern": "[invalid regex"
                  }
                }
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should accept valid permission formats', () {
        const jsonContent = '''
        {
          "routes": {
            "iot": {
              "device-list": {
                "screen": "DeviceListScreen",
                "permissions": ["iot.view", "iot.*", "*", "module.sub-module.action"]
              }
            }
          },
          "fallbacks": {
            "default": "DashboardScreen",
            "permission_denied": "AccessDeniedScreen",
            "not_found": "NotFoundScreen",
            "error": "ErrorScreen"
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parseRouteConfiguration(jsonContent),
          returnsNormally,
        );
      });
    });

    group('parsePermissionConfiguration', () {
      test('should parse valid permission configuration', () {
        const jsonContent = '''
        {
          "permissions": {
            "iot.view": {
              "description": "View IoT devices",
              "roles": ["iot_manager", "admin"]
            }
          },
          "roles": {
            "admin": {
              "permissions": ["*"],
              "description": "Administrator"
            }
          }
        }
        ''';

        final config = ConfigurationParser.parsePermissionConfiguration(jsonContent);
        expect(config.permissions.length, equals(1));
        expect(config.roles.length, equals(1));
        expect(config.hasPermission('iot.view'), isTrue);
        expect(config.hasRole('admin'), isTrue);
      });

      test('should throw ConfigurationError for invalid JSON', () {
        const invalidJson = '{ invalid json }';
        
        expect(
          () => ConfigurationParser.parsePermissionConfiguration(invalidJson),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for empty configuration', () {
        const jsonContent = '''
        {
          "permissions": {},
          "roles": {}
        }
        ''';

        expect(
          () => ConfigurationParser.parsePermissionConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for invalid role name', () {
        const jsonContent = '''
        {
          "permissions": {
            "test.view": {
              "description": "Test permission"
            }
          },
          "roles": {
            "Invalid-Role-Name!": {
              "permissions": ["test.view"]
            }
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parsePermissionConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for unknown permission in role', () {
        const jsonContent = '''
        {
          "permissions": {
            "test.view": {
              "description": "Test permission"
            }
          },
          "roles": {
            "test_role": {
              "permissions": ["unknown.permission"],
              "description": "Test role"
            }
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parsePermissionConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for unknown inherited role', () {
        const jsonContent = '''
        {
          "permissions": {
            "test.view": {
              "description": "Test permission"
            }
          },
          "roles": {
            "test_role": {
              "permissions": ["test.view"],
              "description": "Test role",
              "inherits": ["unknown_role"]
            }
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parsePermissionConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should throw ConfigurationError for circular inheritance', () {
        const jsonContent = '''
        {
          "permissions": {
            "test.view": {
              "description": "Test permission"
            }
          },
          "roles": {
            "role_a": {
              "permissions": ["test.view"],
              "description": "Role A",
              "inherits": ["role_b"]
            },
            "role_b": {
              "permissions": ["test.view"],
              "description": "Role B",
              "inherits": ["role_a"]
            }
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parsePermissionConfiguration(jsonContent),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should accept wildcard permissions in roles', () {
        const jsonContent = '''
        {
          "permissions": {
            "test.view": {
              "description": "Test permission"
            }
          },
          "roles": {
            "admin": {
              "permissions": ["*"],
              "description": "Administrator"
            },
            "test_manager": {
              "permissions": ["test.*"],
              "description": "Test manager"
            }
          }
        }
        ''';

        expect(
          () => ConfigurationParser.parsePermissionConfiguration(jsonContent),
          returnsNormally,
        );
      });
    });

    group('environment-specific loading', () {
      test('should resolve environment-specific config path', () {
        const basePath = '/config/routes.json';
        const environment = 'dev';
        
        final resolvedPath = ConfigurationParser.resolveConfigPath(basePath, environment);
        expect(resolvedPath, equals('/config/routes.dev.json'));
      });

      test('should handle path without extension', () {
        const basePath = '/config/routes';
        const environment = 'dev';
        
        final resolvedPath = ConfigurationParser.resolveConfigPath(basePath, environment);
        expect(resolvedPath, equals('/config/routes.dev'));
      });

      test('should return original path when no environment', () {
        const basePath = '/config/routes.json';
        
        final resolvedPath = ConfigurationParser.resolveConfigPath(basePath, null);
        expect(resolvedPath, equals(basePath));
        
        final resolvedPath2 = ConfigurationParser.resolveConfigPath(basePath, '');
        expect(resolvedPath2, equals(basePath));
      });
    });
  });

  group('ConfigurationError', () {
    test('should create error with type and message', () {
      final error = ConfigurationError(
        'Test error message',
        ConfigurationErrorType.validationError,
        configPath: '/test/path',
      );

      expect(error.message, equals('Test error message'));
      expect(error.type, equals(ConfigurationErrorType.validationError));
      expect(error.code, equals('CONFIGURATION_ERROR'));
      expect(error.context['type'], equals('validationError'));
      expect(error.context['configPath'], equals('/test/path'));
    });

    test('should have proper string representation', () {
      final error = ConfigurationError(
        'Test error',
        ConfigurationErrorType.invalidFormat,
      );

      expect(error.toString(), contains('ConfigurationError(invalidFormat)'));
      expect(error.toString(), contains('Test error'));
    });
  });
}