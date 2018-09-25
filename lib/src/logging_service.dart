import 'dart:convert';
import 'dart:developer' as developer;

import 'package:logs/src/logs.dart';
import 'package:meta/meta.dart';

/// The shared service instance.
final LoggingService loggingService = LoggingService();

/// Exception thrown on logging service configuration errors.
class LoggingException extends Error implements Exception {
  /// Message describing the exception.
  final String message;

  LoggingException(this.message);

  @override
  String toString() => 'Logging exception: $message';
}

@visibleForTesting
typedef DeveloperLogCallback = void Function(String message, String name);

/// Manages logging services.
///
/// The [LoggingService] is intended for internal use only.
///
/// * To create logging channels, see [registerChannel].
/// * To enable or disable a logging channel, use [enableLogging].
/// * To query channel enablement, use [shouldLog].
class LoggingService {
  Map<String, String> _channels = <String, String>{};
  Set<String> _enabledChannels = Set<String>();

  final DeveloperLogCallback _logMessageCallback;

  @visibleForTesting
  LoggingService()
      : this.withCallback((String message, String name) {
          developer.log(message, name: name);
        });

  @visibleForTesting
  LoggingService.withCallback(this._logMessageCallback);

  /// A map of channels to channel descriptions.
  @visibleForTesting
  Map<String, String> get channels => _channels;

  void enableLogging(String channel, bool enable) {
    if (!_channels.containsKey(channel)) {
      throw LoggingException('channel "$channel" is not registered');
    }
    enable ? _enabledChannels.add(channel) : _enabledChannels.remove(channel);
  }

  void log(String channel, DebugLogMessageCallback messageCallback) {
    assert(channel != null);
    if (!shouldLog(channel)) {
      return;
    }

    assert(messageCallback != null);
    final Object message = messageCallback();
    assert(message != null);

    _logMessageCallback(json.encode(message), channel);
  }

  void registerChannel(String name, {String description}) {
    if (_channels.containsKey(name)) {
      throw LoggingException('a channel named "$name" is already registered');
    }
    _channels[name] = description;
  }

  bool shouldLog(String channel) => _enabledChannels.contains(channel);
}
