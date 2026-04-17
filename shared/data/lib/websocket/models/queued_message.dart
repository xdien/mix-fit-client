import 'package:freezed_annotation/freezed_annotation.dart';
import 'websocket_message.dart';

part 'queued_message.freezed.dart';
part 'queued_message.g.dart';

/// Enum defining the status of a queued message
enum QueuedMessageStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('expired')
  expired,
}

/// Enum defining the priority of queued messages
enum QueuedMessagePriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// Represents a WebSocket message that has been queued for later processing
@freezed
class QueuedMessage with _$QueuedMessage {
  const factory QueuedMessage({
    required String id,
    @JsonKey(toJson: _messageToJson, fromJson: _messageFromJson)
    required WebSocketMessage message,
    required DateTime queuedAt,
    required QueuedMessageStatus status,
    @Default(QueuedMessagePriority.normal) QueuedMessagePriority priority,
    DateTime? processedAt,
    DateTime? expiresAt,
    String? error,
    int? retryCount,
    Map<String, dynamic>? metadata,
  }) = _QueuedMessage;

  factory QueuedMessage.fromJson(Map<String, dynamic> json) =>
      _$QueuedMessageFromJson(json);
}

Map<String, dynamic> _messageToJson(WebSocketMessage message) => message.toJson();
WebSocketMessage _messageFromJson(Map<String, dynamic> json) => WebSocketMessage.fromJson(json);

/// Configuration for message queue behavior
@freezed
class MessageQueueConfig with _$MessageQueueConfig {
  const factory MessageQueueConfig({
    @Default(1000) int maxQueueSize,
    @Default(Duration(hours: 24)) Duration messageExpiration,
    @Default(3) int maxRetryAttempts,
    @Default(Duration(seconds: 30)) Duration retryDelay,
    @Default(Duration(minutes: 5)) Duration processingTimeout,
    @Default(true) bool enablePriorityProcessing,
    @Default(100) int batchSize,
  }) = _MessageQueueConfig;

  factory MessageQueueConfig.fromJson(Map<String, dynamic> json) =>
      _$MessageQueueConfigFromJson(json);
}

/// Statistics about the message queue
@freezed
class MessageQueueStats with _$MessageQueueStats {
  const factory MessageQueueStats({
    required int totalQueued,
    required int pending,
    required int processing,
    required int completed,
    required int failed,
    required int expired,
    required DateTime lastUpdated,
    Duration? averageProcessingTime,
    int? messagesPerSecond,
  }) = _MessageQueueStats;

  factory MessageQueueStats.fromJson(Map<String, dynamic> json) =>
      _$MessageQueueStatsFromJson(json);
}

/// Result of processing a queued message
@freezed
class QueueProcessingResult with _$QueueProcessingResult {
  const factory QueueProcessingResult({
    required String messageId,
    required bool success,
    required Duration processingTime,
    String? error,
    Map<String, dynamic>? metadata,
  }) = _QueueProcessingResult;

  factory QueueProcessingResult.fromJson(Map<String, dynamic> json) =>
      _$QueueProcessingResultFromJson(json);
}

extension QueuedMessagePriorityExtension on QueuedMessagePriority {
  int get value {
    switch (this) {
      case QueuedMessagePriority.low:
        return 1;
      case QueuedMessagePriority.normal:
        return 2;
      case QueuedMessagePriority.high:
        return 3;
      case QueuedMessagePriority.critical:
        return 4;
    }
  }

  String get displayName {
    switch (this) {
      case QueuedMessagePriority.low:
        return 'Low';
      case QueuedMessagePriority.normal:
        return 'Normal';
      case QueuedMessagePriority.high:
        return 'High';
      case QueuedMessagePriority.critical:
        return 'Critical';
    }
  }
}

extension QueuedMessageStatusExtension on QueuedMessageStatus {
  String get displayName {
    switch (this) {
      case QueuedMessageStatus.pending:
        return 'Pending';
      case QueuedMessageStatus.processing:
        return 'Processing';
      case QueuedMessageStatus.completed:
        return 'Completed';
      case QueuedMessageStatus.failed:
        return 'Failed';
      case QueuedMessageStatus.expired:
        return 'Expired';
    }
  }

  bool get isActive => this == QueuedMessageStatus.pending || this == QueuedMessageStatus.processing;
  bool get isCompleted => this == QueuedMessageStatus.completed;
  bool get isFailed => this == QueuedMessageStatus.failed || this == QueuedMessageStatus.expired;
}