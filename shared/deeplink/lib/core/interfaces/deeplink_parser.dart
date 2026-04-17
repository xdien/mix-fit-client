import '../models/deeplink_request.dart';

/// Interface for parsing deeplink URLs from various sources
/// Provides platform-agnostic deeplink parsing functionality
abstract class IDeeplinkParser {
  /// Parse deeplink from command line arguments or URL string
  /// Returns a DeeplinkRequest object containing parsed components
  Future<DeeplinkRequest> parse(List<String> args);
  
  /// Validate if the provided URL follows the expected deeplink format
  /// Returns true if the format is valid, false otherwise
  bool isValidFormat(String url);
}