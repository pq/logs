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
  Map<String, String> _channelDescriptions = <String, String>{};
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
  Map<String, String> get channelDescriptions => _channelDescriptions;

  void enableLogging(String channel, bool enable) {
    if (!_channelDescriptions.containsKey(channel)) {
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
        name: 'enable',
        callback: (Map<String, Object> parameters) async {
          final String channel = parameters['channel'];
          if (channel != null) {
            if (_channelDescriptions.containsKey(channel)) {
              enableLogging(channel, parameters['enable'] == 'true');
            }
          }
          return <String, dynamic>{};
        });
    _registerServiceExtension(
        name: 'loggingChannels',
        callback: (Map<String, dynamic> parameters) async => {
              'value': _channelDescriptions.map(
                  (channel, description) => MapEntry(channel, <String, String>{
                        'enabled': shouldLog(channel).toString(),
                        'description': description ?? '',
                      }))
            });
  }

  void log(String channel, LogMessageCallback messageCallback) {
    assert(channel != null);
    if (!shouldLog(channel)) {
      return;
    }

    assert(messageCallback != null);
    final String message = messageCallback();
    assert(message != null);

    _logMessageCallback(message, channel);
  }

  void logData(
    String channel,
    Object data, {
    LogMessageCallback messageCallback,
    Object toEncodable(Object nonEncodable),
  }) {
    assert(channel != null);
    if (!shouldLog(channel)) {
      return;
    }

    String message =
        messageCallback != null ? messageCallback() : data.toString();
    if (toEncodable != null) {
      data = toEncodable(data);
    }
    developer.log(message, name: channel, error: data);
  }

  void logError(
    String channel,
    Object error, {
    StackTrace stackTrace,
    LogMessageCallback messageCallback,
  }) {
    assert(channel != null);
    if (!shouldLog(channel)) {
      return;
    }

    String message =
        messageCallback != null ? messageCallback() : error.toString();
    developer.log(
      message,
      name: channel,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void registerChannel(String name, {String description}) {
    if (_channelDescriptions.containsKey(name)) {
      throw LoggingException('a channel named "$name" is already registered');
    }
    _channelDescriptions[name] = description;
  }

  bool shouldLog(String channel) => _enabledChannels.contains(channel);

  /// Registers a service extension method with the given name and a callback to
  /// be called when the extension method is called.
  void _registerServiceExtension(
      {@required String name, @required _ServiceExtensionCallback callback}) {
    assert(name != null);
    assert(callback != null);
    final String methodName = 'ext.flutter.logs.$name';
    developer.registerExtension(methodName,
        (String method, Map<String, String> parameters) async {
      assert(method == methodName);

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
