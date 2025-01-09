
import 'package:drift/drift.dart';
import 'package:mix_fit/core/data/local/database/database.dart';
import 'package:mix_fit/domain/entity/post/post.dart';

class PostDataSource {
  // A Store with int keys and Map<String, dynamic> values.
  // This Store acts like a persistent map, values of which are Flogs objects converted to Map

  // Private getter to shorten the amount of code needed to get the
  // singleton instance of an opened database.
//  Future<Database> get _db async => await AppDatabase.instance.database;

  // database instance
  final AppDatabase _sembastClient;

  // Constructor
  PostDataSource(this._sembastClient);

  // DB functions:--------------------------------------------------------------
  Future<int> insert(Post post) async {
    return await _sembastClient.post.insertOne(post as Insertable<PostData>);
  }

  Future<int> count() async {
    return 0;
  }

  Future<List<Post>> getAllSortedByFilter() async {
    //creating finder
   return List.empty();
  }

  Future<List<PostData>> getPostsFromDb() async {

    print('Loading from database');

    // fetching data
    final recordSnapshots = await _sembastClient.post.select().get();

    return recordSnapshots;
  }

}
