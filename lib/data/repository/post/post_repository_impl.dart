import 'dart:async';

import 'package:mix_fit/data/local/constants/db_constants.dart';
import 'package:mix_fit/data/local/datasources/post/post_datasource.dart';
import 'package:mix_fit/data/network/apis/posts/post_api.dart';
import 'package:mix_fit/domain/entity/post/post.dart';
import 'package:mix_fit/domain/entity/post/post_list.dart';
import 'package:mix_fit/domain/repository/post/post_repository.dart';

class PostRepositoryImpl extends PostRepository {
  // data source object
  final PostDataSource _postDataSource;

  // api objects
  final PostApi _postApi;

  // constructor
  PostRepositoryImpl(this._postApi, this._postDataSource);

  // Post: ---------------------------------------------------------------------
  @override
  Future<PostList> getPosts() async {
    return await _postApi.getPosts().then((postsList) {
      postsList.posts?.forEach((post) {
        _postDataSource.insert(post);
      });

      return postsList;
    }).catchError((error) => throw error);
  }

  @override
  Future<List<Post>> findPostById(int id) {
    return Future.value(<Post>[]);
  }

  @override
  Future<int> insert(Post post) {
    return _postDataSource.insert(post);
  }

  @override
  Future<int> update(Post post) {
    return Future.value(0);
  }

  @override
  Future<int> delete(Post post) {
    return Future.value(0);
  }
}
