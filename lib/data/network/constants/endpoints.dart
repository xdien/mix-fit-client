class Endpoints {
  Endpoints._();

  // base url
  static const String baseUrl = "https://iot.canthotouring.com";
  // static const String baseUrl = "http://localhost:3000";

  // receiveTimeout
  static const int receiveTimeout = 15000;

  // connectTimeout
  static const int connectionTimeout = 30000;

  // booking endpoints
  static const String getPosts = baseUrl + "/posts";
}