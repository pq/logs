import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:logs/src/logs.dart';
import 'package:meta/meta.dart';

/// The shared service instance.
final LoggingService loggingService = LoggingService()
  ..addListener(_sendToDeveloperLog);

void _sendToDeveloperLog(String message, String channel, Object data) {
  developer.log(message, name: channel, error: data);
}

typedef void LogListener(String channel, String message, Object data);

typedef _ServiceExtensionCallback = Future<Map<String, dynamic>> Function(
    Map<String, String> parameters);

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
/// * To create logging channels, see [registerChannel].
/// * To enable or disable a logging channel, use [enableLogging].
/// * To query channel enablement, use [shouldLog].
class LoggingService {
  Map<String, String> _channelDescriptions = <String, String>{};
  Set<String> _enabledChannels = Set<String>();
  final List<LogListener> _logListeners = <LogListener>[];

  @visibleForTesting
  LoggingService();

  /// A map of channels to channel descriptions.
  Map<String, String> get channelDescriptions => _channelDescriptions;

  void addListener(LogListener listener) {
    if (listener != null && !_logListeners.contains(listener)) {
      _logListeners.add(listener);
    }
  }

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

  void log(String channel, LogMessageCallback messageCallback,
      {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
    assert(channel != null);
    if (!shouldLog(channel)) {
      return;
    }

    assert(messageCallback != null);
    final String message = messageCallback();
    assert(message != null);

    String encodedData =
        data != null ? json.encode(data(), toEncodable: toJsonEncodable) : null;
    for (int i = 0; i < _logListeners.length; ++i) {
      _logListeners[i](channel, message, encodedData);
    }
  }

  void registerChannel(String name, {String description}) {
    if (_channelDescriptions.containsKey(name)) {
      throw LoggingException('a channel named "$name" is already registered');
    }
    _channelDescriptions[name] = description;
  }

  void removeListener(LogListener listener) {
    if (listener != null) {
      _logListeners.remove(listener);
    }
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
