/// Contains localized error messages for different languages
abstract class ErrorMessages {
  // Generic error messages
  String get unknownError;
  String get networkError;
  String get serverError;
  String get clientError;
  String get validationError;
  String get apiError;
  String get authenticationError;
  String get authorizationError;
  String get offlineError;

  // API error messages
  String get badRequest;
  String get unauthorized;
  String get forbidden;
  String get notFound;
  String get methodNotAllowed;
  String get requestTimeout;
  String get conflict;
  String get unprocessableEntity;
  String get tooManyRequests;
  String get internalServerError;
  String get badGateway;
  String get serviceUnavailable;
  String get gatewayTimeout;

  // Network error messages
  String get noConnection;
  String get connectionTimeout;
  String get dnsFailure;
  String get connectionRefused;
  String get certificateError;
  String get requestCancelled;
  String get poorNetworkQuality;

  // Action labels
  String get retry;
  String get dismiss;
  String get details;
  String get login;
  String get contactSupport;
  String get refresh;
  String get openSettings;
  String get manageStorage;
  String get tryAgain;
  String get cancel;
  String get ok;

  // Network status messages
  String get online;
  String get offline;
  String get connecting;
  String get connected;
  String get disconnected;
  String get reconnecting;
  String get connectionLost;
  String get connectionRestored;

  // Network quality messages
  String get excellentConnection;
  String get goodConnection;
  String get fairConnection;
  String get poorConnection;

  // Validation messages
  String get fieldRequired;
  String get invalidEmail;
  String get invalidPhoneNumber;
  String get passwordTooShort;
  String get passwordTooWeak;
  String get passwordsDoNotMatch;
  String get invalidUrl;
  String get invalidDate;
  String get valueTooSmall;
  String get valueTooLarge;

  // Pluralization messages
  String get oneValidationError;
  String get multipleValidationErrors; // Contains {count} placeholder
  String get oneError;
  String get multipleErrors; // Contains {count} placeholder
  String get oneSimilarError;
  String get multipleSimilarErrors; // Contains {count} placeholder

  // Time-based messages
  String get retryAfterSeconds; // Contains {seconds} placeholder
  String get retryAfterMinutes; // Contains {minutes} placeholder

  // Permission messages
  String get permissionDenied; // Contains {permission} placeholder

  // Storage messages
  String get storageFullMessage;

  // Data corruption messages
  String get dataCorruptionMessage;

  // Maintenance messages
  String get maintenanceMessage;

  // Factory methods for different languages
  factory ErrorMessages.en() => _EnglishErrorMessages();
  factory ErrorMessages.vi() => _VietnameseErrorMessages();
  factory ErrorMessages.es() => _SpanishErrorMessages();
  factory ErrorMessages.fr() => _FrenchErrorMessages();
  factory ErrorMessages.de() => _GermanErrorMessages();
  factory ErrorMessages.ja() => _JapaneseErrorMessages();
  factory ErrorMessages.ko() => _KoreanErrorMessages();
  factory ErrorMessages.zh() => _ChineseErrorMessages();
  factory ErrorMessages.ar() => _ArabicErrorMessages();
}

/// English error messages
class _EnglishErrorMessages implements ErrorMessages {
  @override
  String get unknownError => 'An unknown error occurred';
  @override
  String get networkError => 'Network error occurred';
  @override
  String get serverError => 'Server error occurred';
  @override
  String get clientError => 'Client error occurred';
  @override
  String get validationError => 'Validation error';
  @override
  String get apiError => 'API error occurred';
  @override
  String get authenticationError => 'Authentication failed';
  @override
  String get authorizationError => 'Access denied';
  @override
  String get offlineError => 'You are currently offline';

  @override
  String get badRequest => 'Bad request. Please check your input.';
  @override
  String get unauthorized => 'Authentication required. Please log in.';
  @override
  String get forbidden => 'Access denied. You don\'t have permission.';
  @override
  String get notFound => 'The requested resource was not found.';
  @override
  String get methodNotAllowed => 'Method not allowed.';
  @override
  String get requestTimeout => 'Request timed out. Please try again.';
  @override
  String get conflict => 'Conflict occurred. Please refresh and try again.';
  @override
  String get unprocessableEntity => 'Unable to process the request.';
  @override
  String get tooManyRequests => 'Too many requests. Please try again later.';
  @override
  String get internalServerError => 'Internal server error. Please try again later.';
  @override
  String get badGateway => 'Bad gateway. Please try again later.';
  @override
  String get serviceUnavailable => 'Service temporarily unavailable.';
  @override
  String get gatewayTimeout => 'Gateway timeout. Please try again.';

  @override
  String get noConnection => 'No internet connection available';
  @override
  String get connectionTimeout => 'Connection timed out';
  @override
  String get dnsFailure => 'Unable to resolve server address';
  @override
  String get connectionRefused => 'Connection refused by server';
  @override
  String get certificateError => 'SSL certificate error';
  @override
  String get requestCancelled => 'Request was cancelled';
  @override
  String get poorNetworkQuality => 'Poor network quality detected';

  @override
  String get retry => 'Retry';
  @override
  String get dismiss => 'Dismiss';
  @override
  String get details => 'Details';
  @override
  String get login => 'Login';
  @override
  String get contactSupport => 'Contact Support';
  @override
  String get refresh => 'Refresh';
  @override
  String get openSettings => 'Open Settings';
  @override
  String get manageStorage => 'Manage Storage';
  @override
  String get tryAgain => 'Try Again';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'OK';

  @override
  String get online => 'Online';
  @override
  String get offline => 'Offline';
  @override
  String get connecting => 'Connecting...';
  @override
  String get connected => 'Connected';
  @override
  String get disconnected => 'Disconnected';
  @override
  String get reconnecting => 'Reconnecting...';
  @override
  String get connectionLost => 'Connection lost';
  @override
  String get connectionRestored => 'Connection restored';

  @override
  String get excellentConnection => 'Excellent connection';
  @override
  String get goodConnection => 'Good connection';
  @override
  String get fairConnection => 'Fair connection';
  @override
  String get poorConnection => 'Poor connection';

  @override
  String get fieldRequired => 'This field is required';
  @override
  String get invalidEmail => 'Please enter a valid email address';
  @override
  String get invalidPhoneNumber => 'Please enter a valid phone number';
  @override
  String get passwordTooShort => 'Password is too short';
  @override
  String get passwordTooWeak => 'Password is too weak';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get invalidUrl => 'Please enter a valid URL';
  @override
  String get invalidDate => 'Please enter a valid date';
  @override
  String get valueTooSmall => 'Value is too small';
  @override
  String get valueTooLarge => 'Value is too large';

  @override
  String get oneValidationError => 'Please fix the validation error';
  @override
  String get multipleValidationErrors => 'Please fix {count} validation errors';
  @override
  String get oneError => '1 error';
  @override
  String get multipleErrors => '{count} errors';
  @override
  String get oneSimilarError => 'and 1 similar error';
  @override
  String get multipleSimilarErrors => 'and {count} similar errors';

  @override
  String get retryAfterSeconds => 'Please try again in {seconds} seconds';
  @override
  String get retryAfterMinutes => 'Please try again in {minutes} minutes';

  @override
  String get permissionDenied => 'Permission denied: {permission}';

  @override
  String get storageFullMessage => 'Device storage is full. Please free up space.';

  @override
  String get dataCorruptionMessage => 'Data corruption detected. Please refresh the app.';

  @override
  String get maintenanceMessage => 'Server is under maintenance. Please try again later.';
}

/// Vietnamese error messages
class _VietnameseErrorMessages implements ErrorMessages {
  @override
  String get unknownError => 'Đã xảy ra lỗi không xác định';
  @override
  String get networkError => 'Lỗi mạng đã xảy ra';
  @override
  String get serverError => 'Lỗi máy chủ đã xảy ra';
  @override
  String get clientError => 'Lỗi ứng dụng đã xảy ra';
  @override
  String get validationError => 'Lỗi xác thực';
  @override
  String get apiError => 'Lỗi API đã xảy ra';
  @override
  String get authenticationError => 'Xác thực thất bại';
  @override
  String get authorizationError => 'Truy cập bị từ chối';
  @override
  String get offlineError => 'Bạn hiện đang ngoại tuyến';

  @override
  String get badRequest => 'Yêu cầu không hợp lệ. Vui lòng kiểm tra dữ liệu nhập.';
  @override
  String get unauthorized => 'Cần xác thực. Vui lòng đăng nhập.';
  @override
  String get forbidden => 'Truy cập bị từ chối. Bạn không có quyền.';
  @override
  String get notFound => 'Không tìm thấy tài nguyên được yêu cầu.';
  @override
  String get methodNotAllowed => 'Phương thức không được phép.';
  @override
  String get requestTimeout => 'Yêu cầu hết thời gian. Vui lòng thử lại.';
  @override
  String get conflict => 'Xung đột đã xảy ra. Vui lòng làm mới và thử lại.';
  @override
  String get unprocessableEntity => 'Không thể xử lý yêu cầu.';
  @override
  String get tooManyRequests => 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
  @override
  String get internalServerError => 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.';
  @override
  String get badGateway => 'Gateway lỗi. Vui lòng thử lại sau.';
  @override
  String get serviceUnavailable => 'Dịch vụ tạm thời không khả dụng.';
  @override
  String get gatewayTimeout => 'Gateway hết thời gian. Vui lòng thử lại.';

  @override
  String get noConnection => 'Không có kết nối internet';
  @override
  String get connectionTimeout => 'Kết nối hết thời gian';
  @override
  String get dnsFailure => 'Không thể phân giải địa chỉ máy chủ';
  @override
  String get connectionRefused => 'Kết nối bị từ chối bởi máy chủ';
  @override
  String get certificateError => 'Lỗi chứng chỉ SSL';
  @override
  String get requestCancelled => 'Yêu cầu đã bị hủy';
  @override
  String get poorNetworkQuality => 'Chất lượng mạng kém được phát hiện';

  @override
  String get retry => 'Thử lại';
  @override
  String get dismiss => 'Bỏ qua';
  @override
  String get details => 'Chi tiết';
  @override
  String get login => 'Đăng nhập';
  @override
  String get contactSupport => 'Liên hệ hỗ trợ';
  @override
  String get refresh => 'Làm mới';
  @override
  String get openSettings => 'Mở cài đặt';
  @override
  String get manageStorage => 'Quản lý bộ nhớ';
  @override
  String get tryAgain => 'Thử lại';
  @override
  String get cancel => 'Hủy';
  @override
  String get ok => 'OK';

  @override
  String get online => 'Trực tuyến';
  @override
  String get offline => 'Ngoại tuyến';
  @override
  String get connecting => 'Đang kết nối...';
  @override
  String get connected => 'Đã kết nối';
  @override
  String get disconnected => 'Đã ngắt kết nối';
  @override
  String get reconnecting => 'Đang kết nối lại...';
  @override
  String get connectionLost => 'Mất kết nối';
  @override
  String get connectionRestored => 'Kết nối đã được khôi phục';

  @override
  String get excellentConnection => 'Kết nối tuyệt vời';
  @override
  String get goodConnection => 'Kết nối tốt';
  @override
  String get fairConnection => 'Kết nối khá';
  @override
  String get poorConnection => 'Kết nối kém';

  @override
  String get fieldRequired => 'Trường này là bắt buộc';
  @override
  String get invalidEmail => 'Vui lòng nhập địa chỉ email hợp lệ';
  @override
  String get invalidPhoneNumber => 'Vui lòng nhập số điện thoại hợp lệ';
  @override
  String get passwordTooShort => 'Mật khẩu quá ngắn';
  @override
  String get passwordTooWeak => 'Mật khẩu quá yếu';
  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';
  @override
  String get invalidUrl => 'Vui lòng nhập URL hợp lệ';
  @override
  String get invalidDate => 'Vui lòng nhập ngày hợp lệ';
  @override
  String get valueTooSmall => 'Giá trị quá nhỏ';
  @override
  String get valueTooLarge => 'Giá trị quá lớn';

  @override
  String get oneValidationError => 'Vui lòng sửa lỗi xác thực';
  @override
  String get multipleValidationErrors => 'Vui lòng sửa {count} lỗi xác thực';
  @override
  String get oneError => '1 lỗi';
  @override
  String get multipleErrors => '{count} lỗi';
  @override
  String get oneSimilarError => 'và 1 lỗi tương tự';
  @override
  String get multipleSimilarErrors => 'và {count} lỗi tương tự';

  @override
  String get retryAfterSeconds => 'Vui lòng thử lại sau {seconds} giây';
  @override
  String get retryAfterMinutes => 'Vui lòng thử lại sau {minutes} phút';

  @override
  String get permissionDenied => 'Quyền bị từ chối: {permission}';

  @override
  String get storageFullMessage => 'Bộ nhớ thiết bị đã đầy. Vui lòng giải phóng dung lượng.';

  @override
  String get dataCorruptionMessage => 'Phát hiện dữ liệu bị hỏng. Vui lòng làm mới ứng dụng.';

  @override
  String get maintenanceMessage => 'Máy chủ đang bảo trì. Vui lòng thử lại sau.';
}

/// Spanish error messages (basic implementation)
class _SpanishErrorMessages implements ErrorMessages {
  @override
  String get unknownError => 'Se produjo un error desconocido';
  @override
  String get networkError => 'Error de red';
  @override
  String get serverError => 'Error del servidor';
  @override
  String get clientError => 'Error del cliente';
  @override
  String get validationError => 'Error de validación';
  @override
  String get apiError => 'Error de API';
  @override
  String get authenticationError => 'Falló la autenticación';
  @override
  String get authorizationError => 'Acceso denegado';
  @override
  String get offlineError => 'Actualmente estás desconectado';

  @override
  String get badRequest => 'Solicitud incorrecta';
  @override
  String get unauthorized => 'No autorizado';
  @override
  String get forbidden => 'Prohibido';
  @override
  String get notFound => 'No encontrado';
  @override
  String get methodNotAllowed => 'Método no permitido';
  @override
  String get requestTimeout => 'Tiempo de espera agotado';
  @override
  String get conflict => 'Conflicto';
  @override
  String get unprocessableEntity => 'Entidad no procesable';
  @override
  String get tooManyRequests => 'Demasiadas solicitudes';
  @override
  String get internalServerError => 'Error interno del servidor';
  @override
  String get badGateway => 'Puerta de enlace incorrecta';
  @override
  String get serviceUnavailable => 'Servicio no disponible';
  @override
  String get gatewayTimeout => 'Tiempo de espera de puerta de enlace';

  @override
  String get noConnection => 'Sin conexión a internet';
  @override
  String get connectionTimeout => 'Tiempo de conexión agotado';
  @override
  String get dnsFailure => 'Fallo de DNS';
  @override
  String get connectionRefused => 'Conexión rechazada';
  @override
  String get certificateError => 'Error de certificado SSL';
  @override
  String get requestCancelled => 'Solicitud cancelada';
  @override
  String get poorNetworkQuality => 'Calidad de red deficiente';

  @override
  String get retry => 'Reintentar';
  @override
  String get dismiss => 'Descartar';
  @override
  String get details => 'Detalles';
  @override
  String get login => 'Iniciar sesión';
  @override
  String get contactSupport => 'Contactar soporte';
  @override
  String get refresh => 'Actualizar';
  @override
  String get openSettings => 'Abrir configuración';
  @override
  String get manageStorage => 'Gestionar almacenamiento';
  @override
  String get tryAgain => 'Intentar de nuevo';
  @override
  String get cancel => 'Cancelar';
  @override
  String get ok => 'OK';

  @override
  String get online => 'En línea';
  @override
  String get offline => 'Desconectado';
  @override
  String get connecting => 'Conectando...';
  @override
  String get connected => 'Conectado';
  @override
  String get disconnected => 'Desconectado';
  @override
  String get reconnecting => 'Reconectando...';
  @override
  String get connectionLost => 'Conexión perdida';
  @override
  String get connectionRestored => 'Conexión restaurada';

  @override
  String get excellentConnection => 'Conexión excelente';
  @override
  String get goodConnection => 'Buena conexión';
  @override
  String get fairConnection => 'Conexión regular';
  @override
  String get poorConnection => 'Conexión deficiente';

  @override
  String get fieldRequired => 'Este campo es obligatorio';
  @override
  String get invalidEmail => 'Email inválido';
  @override
  String get invalidPhoneNumber => 'Número de teléfono inválido';
  @override
  String get passwordTooShort => 'Contraseña muy corta';
  @override
  String get passwordTooWeak => 'Contraseña muy débil';
  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';
  @override
  String get invalidUrl => 'URL inválida';
  @override
  String get invalidDate => 'Fecha inválida';
  @override
  String get valueTooSmall => 'Valor muy pequeño';
  @override
  String get valueTooLarge => 'Valor muy grande';

  @override
  String get oneValidationError => 'Corrige el error de validación';
  @override
  String get multipleValidationErrors => 'Corrige {count} errores de validación';
  @override
  String get oneError => '1 error';
  @override
  String get multipleErrors => '{count} errores';
  @override
  String get oneSimilarError => 'y 1 error similar';
  @override
  String get multipleSimilarErrors => 'y {count} errores similares';

  @override
  String get retryAfterSeconds => 'Inténtalo de nuevo en {seconds} segundos';
  @override
  String get retryAfterMinutes => 'Inténtalo de nuevo en {minutes} minutos';

  @override
  String get permissionDenied => 'Permiso denegado: {permission}';

  @override
  String get storageFullMessage => 'Almacenamiento lleno. Libera espacio.';

  @override
  String get dataCorruptionMessage => 'Datos corruptos detectados. Actualiza la aplicación.';

  @override
  String get maintenanceMessage => 'Servidor en mantenimiento. Inténtalo más tarde.';
}

// Placeholder implementations for other languages
// In a real application, these would be fully translated

class _FrenchErrorMessages extends _EnglishErrorMessages {}
class _GermanErrorMessages extends _EnglishErrorMessages {}
class _JapaneseErrorMessages extends _EnglishErrorMessages {}
class _KoreanErrorMessages extends _EnglishErrorMessages {}
class _ChineseErrorMessages extends _EnglishErrorMessages {}
class _ArabicErrorMessages extends _EnglishErrorMessages {}