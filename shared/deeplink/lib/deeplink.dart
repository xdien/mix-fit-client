/// Cross-platform deeplink system for application navigation
/// 
/// This library provides a unified approach to handle application navigation
/// through external parameters. It supports desktop (command-line arguments),
/// mobile (URL schemes), and web (URL routing) platforms.
library deeplink;

// Core interfaces
export 'core/interfaces/deeplink_parser.dart';
export 'core/interfaces/route_resolver.dart';
export 'core/interfaces/navigation_handler.dart';
export 'core/interfaces/permission_validator.dart';

// Data models
export 'core/models/deeplink_request.dart';
export 'core/models/route_info.dart';
export 'core/models/navigation_result.dart';
export 'core/models/navigation_context.dart';
export 'core/models/route_configuration.dart';
export 'core/models/permission_configuration.dart';

// Configuration services
export 'core/services/configuration_parser.dart';
export 'core/services/configuration_manager.dart';

// Platform-specific parsers
export 'core/services/desktop_deeplink_parser.dart';

// Error handling
export 'core/errors/deeplink_error.dart';