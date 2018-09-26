import 'dart:async';
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

typedef _ServiceExtensionCallback = Future<Map<String, dynamic>> Function(
    Map<String, String> parameters);

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

  /// Called to register service extensions.
  ///
  /// Note: ideally this will be replaced w/ inline registrations within the
  /// flutter foundation binding (see e.g., https://github.com/flutter/flutter/pull/21505).
  void initServiceExtensions() {
    _registerServiceExtension(
        name: 'ext.flutter.logging',
        callback: (Map<String, Object> parameters) async {
          final String channel = parameters['channel'];
          if (channel != null) {
            if (_channels.containsKey(channel)) {
              enableLogging(channel, parameters['enable'] == 'true');
            }
          }
          return <String, dynamic>{};
        });
    _registerServiceExtension(
        name: 'ext.flutter.loggingChannels',
        callback: (Map<String, dynamic> parameters) async => _channels
            .map((channel, description) => MapEntry(channel, <String, String>{
                  'enabled': shouldLog(channel).toString(),
                  'description': description,
                })));
  }

  void log(String channel, LogMessageCallback messageCallback) {
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

  /// Registers a service extension method with the given name and a callback to
  /// be called when the extension method is called.
  void _registerServiceExtension(
      {@required String name, @required _ServiceExtensionCallback callback}) {
    assert(name != null);
    assert(callback != null);
    developer.registerExtension(name,
        (String method, Map<String, String> parameters) async {
      assert(method == name);

      dynamic caughtException;
      StackTrace caughtStack;
      Map<String, dynamic> result;
      try {
        result = await callback(parameters);
      } catch (exception, stack) {
        caughtException = exception;
        caughtStack = stack;
      }
      if (caughtException == null) {
        result['type'] = '_extensionType';
        result['method'] = method;
        return developer.ServiceExtensionResponse.result(json.encode(result));
      } else {
        return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            json.encode(<String, String>{
              'exception': caughtException.toString(),
              'stack': caughtStack.toString(),
              'method': method,
            }));
      }
    });
  }
}
