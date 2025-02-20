class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const postDetail = '/post/:id';
  static const login = '/login';
  static const register = '/register';
  static const liquorKiln = '/liquorKiln';
  static const liquorKilnControl = '/liquorKilnControl/:deviceId';
  static const settings = '/settings';
  // ...
  
  static String postDetailPath(String id) => '/post/$id';
  static String liquorKilnControlPath(String id) => '/liquorKilnControl/$id';

}