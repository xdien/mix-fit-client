class Endpoints {
  Endpoints._();

  // base url
  static const String baseUrl = "http://localhost:3000";
  static const String wsUrl = "ws://localhost:3000/ws";

  // receiveTimeout
  static const int receiveTimeout = 15000;

  // connectTimeout
  static const int connectionTimeout = 30000;

  // booking endpoints
  static const String getPosts = baseUrl + "/posts";
}