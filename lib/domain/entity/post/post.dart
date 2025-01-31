import 'package:drift/drift.dart';

@DriftDatabase(tables: [Post])
class Post extends Table {
  IntColumn get userId => integer().nullable()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
}
