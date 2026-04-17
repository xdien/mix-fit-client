import 'app_error.dart';
import 'error_action.dart';
import 'error_severity.dart';
import 'error_type.dart';

/// Represents a data validation error
class ValidationError extends AppError {
  /// Map of field names to their validation error messages
  final Map<String, List<String>> fieldErrors;
  
  /// Optional form identifier for context
  final String? formId;

  ValidationError({
    super.id,
    required super.message,
    required this.fieldErrors,
    this.formId,
    super.timestamp,
    super.actions,
  }) : super(
          severity: ErrorSeverity.warning,
          type: ErrorType.validation,
          metadata: {
            'fieldErrors': fieldErrors,
            'formId': formId,
            'errorCount': fieldErrors.values.fold<int>(
              0, 
              (sum, errors) => sum + errors.length,
            ),
          },
        );

  /// Constructor with custom metadata (used for consolidation)
  ValidationError.withMetadata({
    super.id,
    required super.message,
    required this.fieldErrors,
    this.formId,
    super.timestamp,
    super.actions,
    required Map<String, dynamic> metadata,
  }) : super.withMetadata(
          severity: ErrorSeverity.warning,
          type: ErrorType.validation,
          metadata: metadata,
        );

  /// Returns the total number of validation errors
  int get errorCount => fieldErrors.values.fold<int>(
    0, 
    (sum, errors) => sum + errors.length,
  );

  /// Returns all field names that have errors
  List<String> get errorFields => fieldErrors.keys.toList();

  /// Returns whether a specific field has errors
  bool hasFieldError(String fieldName) => fieldErrors.containsKey(fieldName);

  /// Returns the error messages for a specific field
  List<String> getFieldErrors(String fieldName) => 
      fieldErrors[fieldName] ?? [];

  /// Returns the first error message for a specific field
  String? getFirstFieldError(String fieldName) {
    final errors = getFieldErrors(fieldName);
    return errors.isNotEmpty ? errors.first : null;
  }

  /// Adds an error for a specific field
  ValidationError addFieldError(String fieldName, String error) {
    final updatedFieldErrors = Map<String, List<String>>.from(fieldErrors);
    updatedFieldErrors[fieldName] = [...getFieldErrors(fieldName), error];
    
    return copyWith(fieldErrors: updatedFieldErrors);
  }

  /// Removes all errors for a specific field
  ValidationError removeFieldErrors(String fieldName) {
    final updatedFieldErrors = Map<String, List<String>>.from(fieldErrors);
    updatedFieldErrors.remove(fieldName);
    
    return copyWith(fieldErrors: updatedFieldErrors);
  }

  @override
  ValidationError copyWith({
    String? id,
    String? message,
    ErrorSeverity? severity,
    ErrorType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<ErrorAction>? actions,
    Map<String, List<String>>? fieldErrors,
    String? formId,
  }) {
    return ValidationError(
      id: id ?? this.id,
      message: message ?? this.message,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formId: formId ?? this.formId,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
    );
  }

  /// Creates a ValidationError from a map
  static ValidationError fromMap(Map<String, dynamic> map) {
    final fieldErrorsMap = map['fieldErrors'] as Map<String, dynamic>? ?? {};
    final fieldErrors = fieldErrorsMap.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );

    return ValidationError(
      id: map['id'],
      message: map['message'],
      fieldErrors: fieldErrors,
      formId: map['formId'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'fieldErrors': fieldErrors,
      'formId': formId,
      'errorCount': errorCount,
      'errorFields': errorFields,
    });
    return map;
  }

  @override
  String toString() {
    return 'ValidationError{id: $id, message: $message, fieldErrors: $fieldErrors, formId: $formId}';
  }
}