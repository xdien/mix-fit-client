import 'package:path_provider/path_provider.dart';

import '../entity/devices_entity.dart';
import 'database.steps.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'connection/connection.dart' as impl;

// Manually generated by `drift_dev make-migrations` - this file makes writing
// migrations easier. See this for details:
// https://drift.simonbinder.eu/docs/advanced-features/migrations/#step-by-step
import 'tables.dart';

// Generated by drift_dev when running `build_runner build`
part 'database.g.dart';

@DriftDatabase(
    tables: [TodoEntries, Categories, Post, DeviceTable],
    include: {'sql.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(
          e ??
              driftDatabase(
                name: 'mix-fit.db',
                native: const DriftNativeOptions(
                  databaseDirectory: getApplicationSupportDirectory,
                ),
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                  onResult: (result) {
                    if (result.missingFeatures.isNotEmpty) {
                      debugPrint(
                        'Using ${result.chosenImplementation} due to unsupported '
                        'browser features: ${result.missingFeatures}',
                      );
                    }
                  },
                ),
              ),
        );

  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          // The todoEntries.dueDate column was added in version 2.
          await m.addColumn(schema.todoEntries, schema.todoEntries.dueDate);
        },
        from2To3: (m, schema) async {
          // New triggers were added in version 3:
          await m.create(schema.todosDelete);
          await m.create(schema.todosUpdate);

          // Also, the `REFERENCES` constraint was added to
          // [TodoEntries.category]. Run a table migration to rebuild all
          // column constraints without loosing data.
          await m.alterTable(TableMigration(schema.todoEntries));
        },
      ),
      beforeOpen: (details) async {
        // Make sure that foreign keys are enabled
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated) {
          // Create a bunch of default values so the app doesn't look too empty
          // on the first start.
          await batch((b) {
            b.insert(
              categories,
              CategoriesCompanion.insert(name: 'Important', color: Colors.red),
            );

            b.insertAll(todoEntries, [
              TodoEntriesCompanion.insert(description: 'Check out drift'),
              TodoEntriesCompanion.insert(
                  description: 'Fix session invalidation bug',
                  category: const Value(1)),
              TodoEntriesCompanion.insert(
                  description: 'Add favorite movies to home page'),
            ]);
          });
        }

        // This follows the recommendation to validate that the database schema
        // matches what drift expects (https://drift.simonbinder.eu/docs/advanced-features/migrations/#verifying-a-database-schema-at-runtime).
        // It allows catching bugs in the migration logic early.
        await impl.validateDatabaseSchema(this);
      },
    );
  }
}