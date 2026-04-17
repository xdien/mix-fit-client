import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/services/conflict_resolver.dart';
import 'package:data/websocket/interfaces/i_conflict_resolver.dart';
import 'package:data/websocket/models/sync_operation.dart';

void main() {
  group('ConflictResolver', () {
    late ConflictResolver conflictResolver;

    setUp(() {
      conflictResolver = ConflictResolver();
    });

    test('should resolve conflict using remote strategy', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name', 'email': 'local@test.com'},
        remoteData: {'name': 'Remote Name', 'email': 'remote@test.com'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        ConflictResolutionStrategy.useRemote,
      );

      // Assert
      expect(result, equals(conflict.remoteData));
    });

    test('should resolve conflict using local strategy', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name', 'email': 'local@test.com'},
        remoteData: {'name': 'Remote Name', 'email': 'remote@test.com'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        ConflictResolutionStrategy.useLocal,
      );

      // Assert
      expect(result, equals(conflict.localData));
    });

    test('should resolve conflict using latest timestamp strategy', () async {
      // Arrange
      final now = DateTime.now();
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name', 'email': 'local@test.com'},
        remoteData: {'name': 'Remote Name', 'email': 'remote@test.com'},
        localTimestamp: now.subtract(const Duration(minutes: 5)),
        remoteTimestamp: now,
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        ConflictResolutionStrategy.useLatest,
      );

      // Assert
      expect(result, equals(conflict.remoteData)); // Remote is newer
    });

    test('should resolve conflict using merge strategy', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name', 'balance': 100.0},
        remoteData: {'name': 'Remote Name', 'balance': 200.0},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        ConflictResolutionStrategy.merge,
      );

      // Assert
      expect(result['name'], equals('Remote Name')); // Latest timestamp
      expect(result['balance'], equals(200.0)); // Remote value for balance
    });

    test('should throw exception for manual resolution strategy', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name'},
        remoteData: {'name': 'Remote Name'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => conflictResolver.resolveConflict(
          conflict,
          ConflictResolutionStrategy.manual,
        ),
        throwsA(isA<ConflictResolutionException>()),
      );
    });

    test('should get and set default strategies', () {
      // Act & Assert
      expect(
        conflictResolver.getDefaultStrategy('customer'),
        equals(ConflictResolutionStrategy.useLatest),
      );

      // Act
      conflictResolver.setDefaultStrategy('customer', ConflictResolutionStrategy.useRemote);

      // Assert
      expect(
        conflictResolver.getDefaultStrategy('customer'),
        equals(ConflictResolutionStrategy.useRemote),
      );
    });

    test('should determine if conflict can be auto-resolved', () {
      // Arrange
      final conflict = DataConflict(
        entityType: 'customer',
        entityId: '123',
        localData: {'name': 'Local Name'},
        remoteData: {'name': 'Remote Name'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      // Act & Assert
      expect(conflictResolver.canAutoResolve(conflict), isTrue);

      // Change to manual strategy
      conflictResolver.setDefaultStrategy('customer', ConflictResolutionStrategy.manual);
      expect(conflictResolver.canAutoResolve(conflict), isFalse);
    });

    test('should get and set field merge rules', () {
      // Act
      final rules = conflictResolver.getFieldMergeRules('customer');

      // Assert
      expect(rules['name'], equals(ConflictResolutionStrategy.useLatest));
      expect(rules['balance'], equals(ConflictResolutionStrategy.useRemote));

      // Act - set new rules
      final newRules = {
        'name': ConflictResolutionStrategy.useLocal,
        'email': ConflictResolutionStrategy.useRemote,
      };
      conflictResolver.setFieldMergeRules('test_entity', newRules);

      // Assert
      final retrievedRules = conflictResolver.getFieldMergeRules('test_entity');
      expect(retrievedRules['name'], equals(ConflictResolutionStrategy.useLocal));
      expect(retrievedRules['email'], equals(ConflictResolutionStrategy.useRemote));
    });

    test('should merge field values for notes fields', () async {
      // Arrange
      final conflict = DataConflict(
        entityType: 'order',
        entityId: '123',
        localData: {'notes': 'Local notes'},
        remoteData: {'notes': 'Remote notes'},
        localTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        remoteTimestamp: DateTime.now(),
      );

      // Act
      final result = await conflictResolver.resolveConflict(
        conflict,
        ConflictResolutionStrategy.merge,
      );

      // Assert
      expect(result['notes'], contains('Local notes'));
      expect(result['notes'], contains('Remote notes'));
      expect(result['notes'], contains('---'));
    });
  });
}