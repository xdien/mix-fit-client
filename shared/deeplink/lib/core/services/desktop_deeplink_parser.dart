import '../interfaces/deeplink_parser.dart';
import '../models/deeplink_request.dart';
import '../errors/deeplink_error.dart';

/// Desktop implementation of deeplink parser for command-line arguments
/// Parses deeplink URLs from argv/argc parameters using regex validation
class DesktopDeeplinkParser implements IDeeplinkParser {
  /// Regex pattern for validating deeplink URL format
  /// Matches: scheme://module/feature?param1=value1&param2=value2
  static final RegExp _urlPattern = RegExp(
    r'^([a-zA-Z][a-zA-Z0-9+.-]*):\/\/([a-zA-Z][a-zA-Z0-9_-]*)\/'
    r'([a-zA-Z][a-zA-Z0-9_-]+)(?:\?(.*))?$',
  );

  /// Regex pattern for validating query parameters
  /// Matches: key=value pairs separated by &
  static final RegExp _paramPattern = RegExp(r'([^&=]+)=([^&=]*)');

  /// Supported URL schemes for deeplinks
  static const List<String> _supportedSchemes = ['iot'];

  /// Maximum length for URL components to prevent abuse
  static const int _maxComponentLength = 100;
  static const int _maxUrlLength = 2048;
  static const int _maxParameterCount = 50;

  @override
  Future<DeeplinkRequest> parse(List<String> args) async {
    if (args.isEmpty) {
      throw DeeplinkParsingError(
        message: 'No arguments provided for deeplink parsing',
        originalUrl: '',
      );
    }

    // Find the deeplink URL in command line arguments
    String? deeplinkUrl;
    for (final arg in args) {
      if (isValidFormat(arg)) {
        deeplinkUrl = arg;
        break;
      }
    }

    if (deeplinkUrl == null) {
      throw DeeplinkParsingError(
        message: 'No valid deeplink URL found in arguments: ${args.join(' ')}',
        originalUrl: args.join(' '),
      );
    }

    return _parseUrl(deeplinkUrl);
  }

  @override
  bool isValidFormat(String url) {
    if (url.isEmpty || url.length > _maxUrlLength) {
      return false;
    }

    final match = _urlPattern.firstMatch(url);
    if (match == null) {
      return false;
    }

    final scheme = match.group(1)?.toLowerCase();
    final module = match.group(2);
    final feature = match.group(3);

    // Validate scheme is supported
    if (scheme == null || !_supportedSchemes.contains(scheme)) {
      return false;
    }

    // Validate component lengths
    if (module == null || 
        feature == null ||
        module.length > _maxComponentLength ||
        feature.length > _maxComponentLength) {
      return false;
    }

    // Validate component format (alphanumeric, underscore, hyphen)
    if (!_isValidIdentifier(module) || !_isValidIdentifier(feature)) {
      return false;
    }

    // Validate query parameters if present
    final queryString = match.group(4);
    if (queryString != null) {
      if (queryString.isEmpty) {
        // URL ends with ? but no parameters - invalid
        return false;
      }
      return _isValidQueryString(queryString);
    }

    return true;
  }

  /// Parse a validated deeplink URL into components
  DeeplinkRequest _parseUrl(String url) {
    final match = _urlPattern.firstMatch(url);
    if (match == null) {
      throw DeeplinkParsingError.invalidFormat(
        url: url,
        details: 'URL does not match expected pattern',
      );
    }

    final scheme = match.group(1)!.toLowerCase();
    final module = match.group(2)!;
    final feature = match.group(3)!;
    final queryString = match.group(4);

    // Parse query parameters
    final parameters = <String, String>{};
    if (queryString != null && queryString.isNotEmpty) {
      try {
        parameters.addAll(_parseQueryParameters(queryString));
      } catch (e) {
        throw DeeplinkParsingError(
          message: 'Failed to parse query parameters: $e',
          originalUrl: url,
          context: {'queryString': queryString},
        );
      }
    }

    // Validate parsed components
    _validateParsedComponents(url, scheme, module, feature, parameters);

    return DeeplinkRequest(
      scheme: scheme,
      module: module,
      feature: feature,
      parameters: parameters,
      originalUrl: url,
      timestamp: DateTime.now(),
    );
  }

  /// Parse query string into key-value parameters
  Map<String, String> _parseQueryParameters(String queryString) {
    final parameters = <String, String>{};
    final matches = _paramPattern.allMatches(queryString);

    for (final match in matches) {
      final key = Uri.decodeComponent(match.group(1)!);
      final value = Uri.decodeComponent(match.group(2)!);

      // Validate parameter key and value
      if (key.isEmpty || key.length > _maxComponentLength) {
        throw DeeplinkParsingError.invalidFormat(
          url: queryString,
          details: 'Invalid parameter key: $key',
        );
      }

      if (value.length > _maxComponentLength) {
        throw DeeplinkParsingError.invalidFormat(
          url: queryString,
          details: 'Parameter value too long for key: $key',
        );
      }

      // Check for duplicate parameters
      if (parameters.containsKey(key)) {
        throw DeeplinkParsingError.invalidFormat(
          url: queryString,
          details: 'Duplicate parameter key: $key',
        );
      }

      parameters[key] = value;
    }

    // Check parameter count limit
    if (parameters.length > _maxParameterCount) {
      throw DeeplinkParsingError.invalidFormat(
        url: queryString,
        details: 'Too many parameters (max: $_maxParameterCount)',
      );
    }

    return parameters;
  }

  /// Validate that parsed components meet requirements
  void _validateParsedComponents(
    String originalUrl,
    String scheme,
    String module,
    String feature,
    Map<String, String> parameters,
  ) {
    final missingComponents = <String>[];

    if (scheme.isEmpty) missingComponents.add('scheme');
    if (module.isEmpty) missingComponents.add('module');
    if (feature.isEmpty) missingComponents.add('feature');

    if (missingComponents.isNotEmpty) {
      throw DeeplinkParsingError.missingComponents(
        url: originalUrl,
        missingComponents: missingComponents,
      );
    }

    // Validate scheme is supported
    if (!_supportedSchemes.contains(scheme)) {
      throw DeeplinkParsingError.invalidFormat(
        url: originalUrl,
        details: 'Unsupported scheme: $scheme. Supported: ${_supportedSchemes.join(', ')}',
      );
    }
  }

  /// Check if a string is a valid identifier (alphanumeric, underscore, hyphen)
  bool _isValidIdentifier(String identifier) {
    if (identifier.isEmpty) return false;
    
    // Must start with letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(identifier)) {
      return false;
    }
    
    // Can contain letters, numbers, underscore, hyphen
    return RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(identifier);
  }

  /// Validate query string format
  bool _isValidQueryString(String queryString) {
    if (queryString.isEmpty) return false; // Empty query string after ? is invalid

    // Check for basic malformed patterns
    if (queryString.startsWith('&') || 
        queryString.endsWith('&') ||
        queryString.endsWith('=') ||
        queryString.contains('&&') ||
        queryString.contains('==')) {
      return false;
    }

    // Check for missing key or value patterns
    if (queryString.startsWith('=') || queryString.contains('&=')) {
      return false;
    }

    // Validate each parameter
    final matches = _paramPattern.allMatches(queryString);
    if (matches.isEmpty) return false;

    // Check that the entire query string is consumed by valid parameters
    final matchedLength = matches.fold<int>(0, (sum, match) {
      return sum + match.group(0)!.length;
    });

    // Account for & separators
    final expectedLength = matchedLength + (matches.length - 1);
    return expectedLength == queryString.length;
  }

  /// Get list of supported URL schemes
  static List<String> get supportedSchemes => List.unmodifiable(_supportedSchemes);

  /// Get maximum allowed URL length
  static int get maxUrlLength => _maxUrlLength;

  /// Get maximum allowed component length
  static int get maxComponentLength => _maxComponentLength;

  /// Get maximum allowed parameter count
  static int get maxParameterCount => _maxParameterCount;
}