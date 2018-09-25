import 'package:meta/meta.dart';

/// Exception thrown on logging service configuration errors.
class LoggingException extends Error implements Exception {
  /// Message describing the exception.
  final String message;

  LoggingException(this.message);

  @override
  String toString() => 'Logging exception: $message';
}

/// Manages logging services.
///
/// The [LoggingService] is intended for internal use only.
///
/// * To create logging channels, see [LoggingChannel].
/// * To enable or disable a logging channel, use [debugEnableLogging].
/// * To query channel enablement, use [debugShouldLogEvent].
class LoggingService {
  /// The shared service instance.
  static final LoggingService instance = LoggingService();

  Map<String, String> _channels = <String, String>{};
  Set<String> _enabledChannels = Set<String>();

  @visibleForTesting
  LoggingService();

  /// A map of channels to channel descriptions.
  @visibleForTesting
  Map<String, String> get channels => _channels;

  void enableLogging(String channel, bool enable) {
    if (!_channels.containsKey(channel)) {
      throw LoggingException('channel "$channel" is not registered');
    }
    if (enable) {
      _enabledChannels.add(channel);
    } else {
      _enabledChannels.remove(channel);
    }
  }

  void registerChannel(String name, {String description}) {
    if (_channels.containsKey(name)) {
      throw LoggingException('a channel named "$name" is already registered');
    }
    _channels[name] = description;
  }

  bool shouldLog(String channel) => _enabledChannels.contains(channel);
}
