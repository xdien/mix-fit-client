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

  // Repair/Quote entry routes
  static const repairQuotes = '/repair-quotes';
  static const repairTicketAdd = '/repair-tickets/add';
  static const quoteAdd = '/quotes/add';
  static String repairTicketEdit(String id) => '/repair-tickets/$id/edit';
  static String quoteEdit(String id) => '/quotes/$id/edit';
  static String repairTicketLaborWork(String id) => '/repair-tickets/$id/labor-work';
  static String quoteLaborWork(String id) => '/quotes/$id/labor-work';
  
  // Deep linking support for repair tickets and quotes
  static String repairTicketDetail(String id) => '/repair-tickets/$id';
  static String quoteDetail(String id) => '/quotes/$id';
}