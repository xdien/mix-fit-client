class IotRoutes {
  static const liquorKiln = '/liquor-kiln';
  static const liquorKilnControl = '/liquor-kiln-control/:deviceId';
  static String liquorKilnControlPath(String id) => '/liquor-kiln-control/$id';

}