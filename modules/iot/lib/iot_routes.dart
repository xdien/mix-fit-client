class IotRoutes {
  static const liquorKiln = '/liquorKiln';
  static const liquorKilnControl = '/liquorKilnControl/:deviceId';
  static String liquorKilnControlPath(String id) => '/liquorKilnControl/$id';

}