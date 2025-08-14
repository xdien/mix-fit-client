class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const postDetail = '/post/:id';
  static const login = '/login';
  static const register = '/register';
  static const settings = '/settings';
  static String liquorKilnControlPath(String id) => '/liquorKilnControl/$id';

  // Customer management routes
  static const customers = '/customers';
  static const customerAdd = '/customers/add';
  static const customerSelectionDemo = '/customers/selection-demo';
  static String customerEdit(String id) => '/customers/$id/edit';

  // Vehicle repair entry routes
  static const vehicleEntries = '/vehicle-entries';
  static const vehicleEntryAdd = '/vehicle-entries/add';
  static String vehicleEntryEdit(String id) => '/vehicle-entries/$id/edit';
  static String vehicleEntryHistory(String id) => '/vehicle-entries/$id/history';
  static String vehicleEntryByLicense(String licensePlate) => '/vehicle-entries/by-license/$licensePlate';
  static String vehicleEntryByVin(String vin) => '/vehicle-entries/by-vin/$vin';
}