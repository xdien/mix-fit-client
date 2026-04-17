import 'package:test/test.dart';
import 'package:deeplink/core/models/permission_configuration.dart';

void main() {
  group('PermissionConfiguration', () {
    late PermissionConfiguration config;

    setUp(() {
      config = PermissionConfiguration(
        permissions: {
          'iot.view': const PermissionDefinition(
            description: 'View IoT devices',
            roles: ['iot_manager', 'admin'],
            category: 'iot',
          ),
          'iot.control': const PermissionDefinition(
            description: 'Control IoT devices',
            roles: ['admin'],
            category: 'iot',
          ),
          'settings.view': const PermissionDefinition(
            description: 'View settings',
            roles: ['user', 'admin'],
            category: 'settings',
          ),
        },
        roles: {
          'admin': const RoleDefinition(
            permissions: ['*'],
            description: 'Administrator',
            isSystem: true,
          ),
          'iot_manager': const RoleDefinition(
            permissions: ['iot.*'],
            description: 'IoT Manager',
          ),
          'user': const RoleDefinition(
            permissions: ['settings.view'],
            description: 'Regular user',
          ),
          'inherited_role': const RoleDefinition(
            permissions: ['iot.view'],
            description: 'Role with inheritance',
            inherits: ['user'],
          ),
        },
      );
    });

    test('should get permission definition', () {
      final permission = config.getPermission('iot.view');
      expect(permission, isNotNull);
      expect(permission!.description, equals('View IoT devices'));
      expect(permission.category, equals('iot'));
    });

    test('should return null for non-existent permission', () {
      final permission = config.getPermission('non.existent');
      expect(permission, isNull);
    });

    test('should get role definition', () {
      final role = config.getRole('admin');
      expect(role, isNotNull);
      expect(role!.description, equals('Administrator'));
      expect(role.isSystem, isTrue);
    });

    test('should return null for non-existent role', () {
      final role = config.getRole('non_existent');
      expect(role, isNull);
    });

    test('should check if permission exists', () {
      expect(config.hasPermission('iot.view'), isTrue);
      expect(config.hasPermission('non.existent'), isFalse);
    });

    test('should check if role exists', () {
      expect(config.hasRole('admin'), isTrue);
      expect(config.hasRole('non_existent'), isFalse);
    });

    test('should get permissions for role with wildcard', () {
      final permissions = config.getPermissionsForRole('admin');
      expect(permissions, containsAll(['iot.view', 'iot.control', 'settings.view']));
    });

    test('should get permissions for role with module wildcard', () {
      final permissions = config.getPermissionsForRole('iot_manager');
      expect(permissions, containsAll(['iot.view', 'iot.control']));
      expect(permissions, isNot(contains('settings.view')));
    });

    test('should get direct permissions for role', () {
      final permissions = config.getPermissionsForRole('user');
      expect(permissions, equals(['settings.view']));
    });

    test('should check if role has permission', () {
      expect(config.roleHasPermission('admin', 'iot.view'), isTrue);
      expect(config.roleHasPermission('admin', 'iot.control'), isTrue);
      expect(config.roleHasPermission('admin', 'settings.view'), isTrue);
      expect(config.roleHasPermission('iot_manager', 'iot.view'), isTrue);
      expect(config.roleHasPermission('iot_manager', 'iot.control'), isTrue);
      expect(config.roleHasPermission('iot_manager', 'settings.view'), isFalse);
      expect(config.roleHasPermission('user', 'settings.view'), isTrue);
      expect(config.roleHasPermission('user', 'iot.view'), isFalse);
    });

    test('should get available permissions', () {
      final permissions = config.getAvailablePermissions();
      expect(permissions, containsAll(['iot.view', 'iot.control', 'settings.view']));
      expect(permissions.length, equals(3));
    });

    test('should get available roles', () {
      final roles = config.getAvailableRoles();
      expect(roles, containsAll(['admin', 'iot_manager', 'user', 'inherited_role']));
      expect(roles.length, equals(4));
    });

    test('should serialize to JSON', () {
      final json = config.toJson();
      expect(json['permissions'], isA<Map<String, dynamic>>());
      expect(json['roles'], isA<Map<String, dynamic>>());
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('should deserialize from JSON', () {
      final json = {
        'permissions': {
          'test.view': {
            'description': 'Test permission',
            'category': 'test',
            'roles': ['test_role'],
          }
        },
        'roles': {
          'test_role': {
            'permissions': ['test.view'],
            'description': 'Test role',
            'isSystem': false,
          }
        },
        'metadata': {
          'version': '1.0.0',
        }
      };

      final deserializedConfig = PermissionConfiguration.fromJson(json);
      expect(deserializedConfig.permissions.length, equals(1));
      expect(deserializedConfig.roles.length, equals(1));
      expect(deserializedConfig.hasPermission('test.view'), isTrue);
      expect(deserializedConfig.hasRole('test_role'), isTrue);
      expect(deserializedConfig.metadata['version'], equals('1.0.0'));
    });
  });

  group('RoleDefinition', () {
    test('should get all permissions including inherited', () {
      final config = PermissionConfiguration(
        permissions: {
          'base.view': const PermissionDefinition(description: 'Base view'),
          'extended.edit': const PermissionDefinition(description: 'Extended edit'),
        },
        roles: {
          'base_role': const RoleDefinition(
            permissions: ['base.view'],
            description: 'Base role',
          ),
          'extended_role': const RoleDefinition(
            permissions: ['extended.edit'],
            description: 'Extended role',
            inherits: ['base_role'],
          ),
        },
      );

      final baseRole = config.getRole('base_role')!;
      final extendedRole = config.getRole('extended_role')!;

      final basePermissions = baseRole.getAllPermissions(config);
      expect(basePermissions, equals(['base.view']));

      final extendedPermissions = extendedRole.getAllPermissions(config);
      expect(extendedPermissions, containsAll(['extended.edit', 'base.view']));
    });

    test('should serialize and deserialize correctly', () {
      const original = RoleDefinition(
        permissions: ['test.view', 'test.edit'],
        description: 'Test role',
        inherits: ['parent_role'],
        isSystem: true,
        metadata: {'custom': 'value'},
      );

      final json = original.toJson();
      final deserialized = RoleDefinition.fromJson(json);

      expect(deserialized.permissions, equals(original.permissions));
      expect(deserialized.description, equals(original.description));
      expect(deserialized.inherits, equals(original.inherits));
      expect(deserialized.isSystem, equals(original.isSystem));
      expect(deserialized.metadata, equals(original.metadata));
    });

    test('should handle missing optional fields', () {
      final json = {
        'permissions': ['test.view'],
      };

      final roleDef = RoleDefinition.fromJson(json);
      expect(roleDef.permissions, equals(['test.view']));
      expect(roleDef.description, isNull);
      expect(roleDef.inherits, isEmpty);
      expect(roleDef.isSystem, isFalse);
      expect(roleDef.metadata, isEmpty);
    });
  });

  group('PermissionDefinition', () {
    test('should serialize and deserialize correctly', () {
      const original = PermissionDefinition(
        description: 'Test permission',
        roles: ['role1', 'role2'],
        category: 'test',
        isSystem: true,
        metadata: {'custom': 'value'},
      );

      final json = original.toJson();
      final deserialized = PermissionDefinition.fromJson(json);

      expect(deserialized.description, equals(original.description));
      expect(deserialized.roles, equals(original.roles));
      expect(deserialized.category, equals(original.category));
      expect(deserialized.isSystem, equals(original.isSystem));
      expect(deserialized.metadata, equals(original.metadata));
    });

    test('should handle missing optional fields', () {
      final json = {
        'description': 'Test permission',
      };

      final permDef = PermissionDefinition.fromJson(json);
      expect(permDef.description, equals('Test permission'));
      expect(permDef.roles, isEmpty);
      expect(permDef.category, isNull);
      expect(permDef.isSystem, isFalse);
      expect(permDef.metadata, isEmpty);
    });
  });
}