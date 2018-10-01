import 'package:logs/src/logging_service.dart';

/// A callback that, when evaluated, returns a log message.
typedef LogMessageCallback = String Function();

/// A callback that, when evaluated, returns log data. Log data maps must
/// be encodable as JSON using `json.encode()`.
typedef LogDataCallback = Map Function();

/// A function that encodes a given object as a JSON-encodable map.
typedef ToJsonEncodable = Map<dynamic, dynamic> Function(Object);

/// Enable (or disable) logging for all events on the given [channel].
void enableLogging(String channel, [bool enable = true]) {
  loggingService.enableLogging(channel, enable);
}

/// Logs a message conditionally if the given identifying event [channel] is
/// enabled (if `shouldLog(channel)` is true).
///
/// Messages are obtained by evaluating [messageCallback]. An optional map of
/// JSON-encodable data can be provided with a [data] callback. In the event
/// that logging is not enabled for the given [channel], [messageCallback] and
/// [data] will not be evaluated. The cost of logging calls can be further
/// mitigated at call sites by invoking them in a function that is only
/// evaluated in debug (or profile) mode(s). For example, to ignore logging in
/// release mode you could wrap calls in a profile callback:
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
///
/// Logging for a given event channel can be enabled programmatically via
/// [debugEnableLogging] or using a VM service call.
void log(String channel, LogMessageCallback messageCallback,
    {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
  loggingService.log(channel, messageCallback,
      data: data, toJsonEncodable: toJsonEncodable);
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
  void log(LogMessageCallback messageCallback,
      {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
    loggingService.log(channel, messageCallback,
        data: data, toJsonEncodable: toJsonEncodable);
  }
}
