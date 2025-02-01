class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const post = '/post';
  static const postDetail = '/post/:id';
  static const login = '/login';
  static const register = '/register';
  static const liquorKiln = '/liquorKiln';
  static const settings = '/settings';
  // ...
  
  // Helper method để tạo path với params
  static String postDetailPath(String id) => '/post/$id';
}