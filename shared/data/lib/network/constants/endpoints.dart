class Endpoints {
  Endpoints._();

  // base url
  static const String baseUrl = String.fromEnvironment("BASE_URL", defaultValue: "http://localhost:3000");

  // receiveTimeout
  static const int receiveTimeout = 15000;

  // connectTimeout
  static const int connectionTimeout = 30000;

}