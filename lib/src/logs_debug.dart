import '../src/logs.dart';

/// A callback that, when evaluated, returns a log message.
typedef LogMessageCallback = String Function();

/// A callback that, when evaluated, returns log data. Log data maps must
/// be encodable as JSON using `json.encode()`.
typedef LogDataCallback = Map Function();

/// In debug-mode logs a message conditionally if the given identifying event
/// [channel] is enabled (if `shouldLog(channel)` is true).
///
/// Messages are obtained lazily by evaluating [messageCallback]. An optional
/// map of JSON-encodable data can be provided with a [data] callback. In the
/// event that logging is not enabled for the given [channel], [messageCallback]
/// and [data] will not be evaluated.
///
/// Calls to `debugLog` are removed from release and profile modes.
void debugLog(String channel, LogMessageCallback messageCallback,
    {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
  assert(() {
    log(
      channel,
      messageCallback(),
      data: data(),
      toJsonEncodable: toJsonEncodable,
    );
    return true;
  }());
}
