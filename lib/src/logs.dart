import 'package:logs/src/logging_service.dart';

/// A callback that, when evaluated, returns a log message.  Log messages must
/// be encodable as JSON using `json.encode()`.
typedef LogMessageCallback = String Function();

/// Enable (or disable) logging for all events on the given [channel].
void enableLogging(String channel, [bool enable = true]) {
  loggingService.enableLogging(channel, enable);
}

/// Logs a message conditionally if the given identifying event [channel] is
/// enabled (if `shouldLog(channel)` is true).
///
/// Messages are obtained by evaluating [messageCallback] and must be encodable
/// as JSON strings using `json.encode()`. In the event that logging is not
/// enabled for the given [channel], [messageCallback] will not be evaluated.
/// The cost of logging calls can be further mitigated at call sites by invoking
/// them in a function that is only evaluated in debug (or profile) mode(s). For
/// example, to ignore logging in release mode you could wrap calls in a profile
/// callback:
///
/// ```dart
/// profile(() {
///   log(logGestures, () => <String, int> {
///    'x' : x,
///    'y' : y,
///    'z' : z,
///   });
/// });
///```
///
/// Logging for a given event channel can be enabled programmatically via
/// [debugEnableLogging] or using a VM service call.
void log(String channel, LogMessageCallback messageCallback) {
  loggingService.log(channel, messageCallback);
}

/// Register a logging channel with the given [name] and optional [description].
void registerLoggingChannel(String name, {String description}) {
  loggingService.registerChannel(name, description: description);
}

/// Returns true if events on the given event [channel] should be logged.
bool shouldLog(String channel) => loggingService.shouldLog(channel);

class Log {
  final String channel;

  Log(this.channel, {String description}) {
    assert(channel != null);
    if (!loggingService.channelDescriptions.containsKey(channel)) {
      loggingService.registerChannel(channel, description: description);
    }
  }

  bool get enabled => loggingService.shouldLog(channel);

  void set enabled(enabled) {
    loggingService.enableLogging(channel, enabled);
  }

  /// @see [log]
  void log(LogMessageCallback messageCallback) {
    loggingService.log(channel, messageCallback);
  }

  void logData(
    Object data, {
    LogMessageCallback messageCallback,
    Object toEncodable(Object nonEncodable),
  }) {
    loggingService.logData(
      channel,
      data,
      messageCallback: messageCallback,
      toEncodable: toEncodable,
    );
  }

  void logError(
    Object error, {
    StackTrace stackTrace,
    LogMessageCallback messageCallback,
  }) {
    loggingService.logError(
      channel,
      error,
      messageCallback: messageCallback,
      stackTrace: stackTrace,
    );
  }
}
