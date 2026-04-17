import 'dart:developer' as developer;
import '../models/websocket_message_type.dart';
import '../models/websocket_message.dart';
import '../models/websocket_preferences.dart';
import 'websocket_preferences_service.dart';

/// Service for filtering and prioritizing WebSocket notifications
class WebSocketNotificationFilter {
  final WebSocketPreferencesService _preferencesService;
  
  WebSocketNotificationFilter(this._preferencesService);

  /// Filter a WebSocket message based on user preferences
  FilterResult filterMessage(WebSocketMessage message, {bool isAppInForeground = true}) {
    final preferences = _preferencesService.currentPreferences;
    final messageType = WebSocketMessageType.fromString(message.type);
    
    developer.log(
      'Filtering message: type=${message.type}, channel=${message.channel}',
      name: 'WebSocketNotificationFilter',
    );

    // Check if real-time updates are globally disabled
    if (!preferences.enableRealTimeUpdates) {
      developer.log('Real-time updates disabled, filtering message', name: 'WebSocketNotificationFilter');
      return FilterResult.filtered(FilterReason.globallyDisabled);
    }

    // Check if message type is enabled
    if (!preferences.isMessageTypeEnabled(messageType)) {
      developer.log('Message type $messageType disabled, filtering message', name: 'WebSocketNotificationFilter');
      return FilterResult.filtered(FilterReason.messageTypeDisabled);
    }

    // Check if channel is enabled
    if (!preferences.isChannelEnabled(message.channel)) {
      developer.log('Channel ${message.channel} disabled, filtering message', name: 'WebSocketNotificationFilter');
      return FilterResult.filtered(FilterReason.channelDisabled);
    }

    // Get message priority
    final messagePriority = preferences.getPriorityForMessageType(messageType);
    
    // Check notification settings
    final notificationSettings = _preferencesService.getNotificationSettings(messageType, isAppInForeground);
    
    developer.log(
      'Message passed filters: priority=$messagePriority, shouldShow=${notificationSettings.shouldShow}',
      name: 'WebSocketNotificationFilter',
    );

    return FilterResult.allowed(
      priority: messagePriority,
      notificationSettings: notificationSettings,
    );
  }

  /// Filter a batch of messages and return them sorted by priority
  List<FilteredMessage> filterAndSortMessages(
    List<WebSocketMessage> messages, {
    bool isAppInForeground = true,
  }) {
    final filteredMessages = <FilteredMessage>[];

    for (final message in messages) {
      final filterResult = filterMessage(message, isAppInForeground: isAppInForeground);
      
      if (filterResult.isAllowed) {
        filteredMessages.add(FilteredMessage(
          message: message,
          priority: filterResult.priority!,
          notificationSettings: filterResult.notificationSettings!,
        ));
      }
    }

    // Sort by priority (highest first)
    filteredMessages.sort((a, b) => b.priority.compareTo(a.priority));

    developer.log(
      'Filtered ${messages.length} messages, ${filteredMessages.length} allowed',
      name: 'WebSocketNotificationFilter',
    );

    return filteredMessages;
  }

  /// Check if a message should trigger an immediate notification
  bool shouldTriggerImmediateNotification(WebSocketMessage message, {bool isAppInForeground = true}) {
    final filterResult = filterMessage(message, isAppInForeground: isAppInForeground);
    
    if (!filterResult.isAllowed) {
      return false;
    }

    final notificationSettings = filterResult.notificationSettings!;
    final priority = filterResult.priority!;

    // High priority messages (4-5) should always trigger immediate notifications
    if (priority >= 4) {
      return notificationSettings.shouldShow;
    }

    // Medium priority messages (2-3) trigger notifications based on settings
    if (priority >= 2) {
      return notificationSettings.shouldShow;
    }

    // Low priority messages (1) only trigger notifications if explicitly enabled
    return notificationSettings.shouldShow && _preferencesService.currentPreferences.showForegroundNotifications;
  }

  /// Get the notification delay based on message priority
  Duration getNotificationDelay(int priority) {
    switch (priority) {
      case 5: // Critical - immediate
        return Duration.zero;
      case 4: // High - 1 second delay
        return const Duration(seconds: 1);
      case 3: // Medium - 3 seconds delay
        return const Duration(seconds: 3);
      case 2: // Low - 5 seconds delay
        return const Duration(seconds: 5);
      case 1: // Very low - 10 seconds delay
        return const Duration(seconds: 10);
      default:
        return const Duration(seconds: 5);
    }
  }

  /// Check if messages should be batched based on their types and timing
  bool shouldBatchMessages(List<WebSocketMessage> messages) {
    if (messages.length <= 1) {
      return false;
    }

    // Check if all messages are of the same type
    final firstMessageType = WebSocketMessageType.fromString(messages.first.type);
    final allSameType = messages.every(
      (msg) => WebSocketMessageType.fromString(msg.type) == firstMessageType,
    );

    // Check if messages arrived within a short time window (5 seconds)
    final now = DateTime.now();
    final allRecent = messages.every(
      (msg) => now.difference(msg.timestamp).inSeconds <= 5,
    );

    // Batch if same type and recent, or if there are many messages
    return (allSameType && allRecent) || messages.length >= 5;
  }

  /// Create a batched notification summary
  String createBatchedNotificationSummary(List<FilteredMessage> messages) {
    if (messages.isEmpty) {
      return 'No messages';
    }

    if (messages.length == 1) {
      return _createSingleMessageSummary(messages.first);
    }

    // Group messages by type
    final messagesByType = <WebSocketMessageType, List<FilteredMessage>>{};
    for (final message in messages) {
      final messageType = WebSocketMessageType.fromString(message.message.type);
      messagesByType.putIfAbsent(messageType, () => []).add(message);
    }

    // Create summary based on message types
    final summaryParts = <String>[];
    for (final entry in messagesByType.entries) {
      final messageType = entry.key;
      final count = entry.value.length;
      
      switch (messageType) {
        case WebSocketMessageType.customerUpdate:
          summaryParts.add('$count customer update${count > 1 ? 's' : ''}');
          break;
        case WebSocketMessageType.inventoryUpdate:
          summaryParts.add('$count inventory update${count > 1 ? 's' : ''}');
          break;
        case WebSocketMessageType.orderStatusUpdate:
          summaryParts.add('$count order update${count > 1 ? 's' : ''}');
          break;
        case WebSocketMessageType.systemNotification:
          summaryParts.add('$count system notification${count > 1 ? 's' : ''}');
          break;
        default:
          summaryParts.add('$count message${count > 1 ? 's' : ''}');
      }
    }

    return summaryParts.join(', ');
  }

  /// Create a summary for a single message
  String _createSingleMessageSummary(FilteredMessage filteredMessage) {
    final message = filteredMessage.message;
    final messageType = WebSocketMessageType.fromString(message.type);
    
    switch (messageType) {
      case WebSocketMessageType.customerUpdate:
        return 'Customer information updated';
      case WebSocketMessageType.inventoryUpdate:
        return 'Inventory levels changed';
      case WebSocketMessageType.orderStatusUpdate:
        return 'Order status updated';
      case WebSocketMessageType.systemNotification:
        return 'System notification';
      default:
        return 'New message received';
    }
  }
}

/// Result of message filtering
class FilterResult {
  final bool isAllowed;
  final FilterReason? filterReason;
  final int? priority;
  final NotificationSettings? notificationSettings;

  const FilterResult._({
    required this.isAllowed,
    this.filterReason,
    this.priority,
    this.notificationSettings,
  });

  factory FilterResult.allowed({
    required int priority,
    required NotificationSettings notificationSettings,
  }) {
    return FilterResult._(
      isAllowed: true,
      priority: priority,
      notificationSettings: notificationSettings,
    );
  }

  factory FilterResult.filtered(FilterReason reason) {
    return FilterResult._(
      isAllowed: false,
      filterReason: reason,
    );
  }
}

/// Reasons why a message might be filtered
enum FilterReason {
  globallyDisabled,
  messageTypeDisabled,
  channelDisabled,
  priorityTooLow,
  userPreference,
}

/// A message that has passed filtering with its associated metadata
class FilteredMessage {
  final WebSocketMessage message;
  final int priority;
  final NotificationSettings notificationSettings;

  const FilteredMessage({
    required this.message,
    required this.priority,
    required this.notificationSettings,
  });

  @override
  String toString() {
    return 'FilteredMessage(type: ${message.type}, priority: $priority, channel: ${message.channel})';
  }
}