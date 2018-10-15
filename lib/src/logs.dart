import 'package:logs/src/log_manager.dart';

/// A callback that, when evaluated, returns a log message.
typedef LogMessageCallback = String Function();

/// A callback that, when evaluated, returns log data. Log data maps must
/// be encodable as JSON using `json.encode()`.
typedef LogDataCallback = Map Function();

/// A function that encodes a given object as a JSON-encodable map.
typedef ToJsonEncodable = Map<dynamic, dynamic> Function(Object);

/// Enable (or disable) logging for all events on the given [channel].
void enableLogging(String channel, {bool enable = true}) {
  logManager.enableLogging(channel, enable: enable);
}

/// Logs a message conditionally if the given identifying event [channel] is
/// enabled (if `shouldLog(channel)` is true).
///
/// If [message] is a [Function], it will be lazy evaluated. Additionally, if
/// [message] or its evaluated value is not a [String], then 'toString()' will
/// be called on the object and the result will be logged.
///
///
/// An optional map of JSON-encodable data can be provided as [data]. If [data]
/// is a [Function], it will be lazily evaluated.
///
/// The cost of logging calls can be further mitigated at call sites by invoking
/// them in functions that is only evaluated in debug (or profile) mode(s). For
/// example, to ignore logging in release mode you could wrap calls in a profile
/// callback:
///
/// ```dart
/// profile(() {
///   log(logGestures, () => 'gesture call', () => <String, int> {
///    'x' : x,
///    'y' : y,
///    'z' : z,
///   });
/// });
///```
/// For convenience, calls that should only be invoked in debug mode should
/// be made with [debugLog], which wraps calls in an `assert`.
///
/// Logging for a given event channel can be enabled programmatically via
/// [enableLogging] or using a VM service call.
///
/// @see enableLogging
/// @see debugLog
///
void log(String channel, dynamic message,
    {dynamic data, ToJsonEncodable toJsonEncodable}) {
  logManager.log(channel, message,
      data: data, toJsonEncodable: toJsonEncodable);
}

/// In debug-mode logs a message conditionally if the given identifying event
/// [channel] is enabled (if `shouldLog(channel)` is true).
///
/// Calls to `debugLog` are removed from release and profile modes.
///
/// @see log
void debugLog(String channel, LogMessageCallback messageCallback,
    {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
  logManager.debugLog(channel, messageCallback,
      data: data, toJsonEncodable: toJsonEncodable);
}

/// Register a logging channel with the given [name] and optional [description].
void registerLoggingChannel(String name, {String description}) {
  logManager.registerChannel(name, description: description);
}

/// Returns true if events on the given event [channel] should be logged.
bool shouldLog(String channel) => logManager.shouldLog(channel);

class Log {
  final String channel;

  Log(this.channel, {String description}) {
    assert(channel != null);
    if (!logManager.channelDescriptions.containsKey(channel)) {
      logManager.registerChannel(channel, description: description);
    }
  }

  bool get enabled => logManager.shouldLog(channel);

  set enabled(enabled) {
    logManager.enableLogging(channel, enable: enabled);
  }

  /// @see [LogManager.log]
  void log(LogMessageCallback messageCallback,
      {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
    logManager.log(channel, messageCallback,
        data: data, toJsonEncodable: toJsonEncodable);
  }

  /// @see [LogManager.debugLog]
  void debugLog(LogMessageCallback messageCallback,
      {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
    logManager.debugLog(channel, messageCallback,
        data: data, toJsonEncodable: toJsonEncodable);
  }
}
