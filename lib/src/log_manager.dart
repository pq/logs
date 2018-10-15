import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:meta/meta.dart';

import 'channels/http_channel.dart';
import 'logs.dart';

/// The shared manager instance.
final LogManager logManager = LogManager()..addListener(_sendToDeveloperLog);

void _sendToDeveloperLog(String channel, String message, Object data) {
  developer.log(message, name: channel, error: data);
}

typedef LogListener = void Function(
  String channel,
  String message,
  Object data,
);

typedef _ServiceExtensionCallback = Future<Map<String, dynamic>> Function(
    Map<String, String> parameters);

typedef _ChannelInstallHandler = bool Function(String name);

/// Provides hooks for channel installation.
abstract class ChannelInstallHandler {
  void installChannel(String name);
}

/// Exception thrown on logging configuration errors.
class LoggingException extends Error implements Exception {
  /// Message describing the exception.
  final String message;

  LoggingException(this.message);

  @override
  String toString() => 'Logging exception: $message';
}

/// Manages loggers.
///
/// * To create logging channels, see [registerChannel].
/// * To enable or disable a logging channel, use [enableLogging].
/// * To query channel enablement, use [shouldLog].
class LogManager {
  Map<String, String> _channelDescriptions = <String, String>{};
  Set<String> _enabledChannels = Set<String>();
  final List<LogListener> _logListeners = <LogListener>[];

  final LinkedHashSet<_ChannelInstallHandler> _channelInstallHandlers =
      LinkedHashSet<_ChannelInstallHandler>();

  @visibleForTesting
  LogManager() {
    _addChannelInstallHandler((name) {
      if (name == 'http') {
        installHttpChannel();
        return true;
      }
      return false;
    });
  }

  /// A map of channels to channel descriptions.
  Map<String, String> get channelDescriptions => _channelDescriptions;

  void addListener(LogListener listener) {
    if (listener != null && !_logListeners.contains(listener)) {
      _logListeners.add(listener);
    }
  }

  void enableLogging(String channel, {bool enable = true}) {
    enable ? _enabledChannels.add(channel) : _enabledChannels.remove(channel);
    _installHandlers(channel);
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
              enableLogging(channel, enable: parameters['enable'] == 'true');
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

  void log(String channel, dynamic message,
      {dynamic data, ToJsonEncodable toJsonEncodable}) {
    assert(channel != null);
    if (!shouldLog(channel)) {
      return;
    }

    assert(message != null);
    if (message is LogMessageCallback) {
      message = message();
    }
    if (message is! String) {
      message = message.toString();
    }

    if (data is LogDataCallback) {
      data = data();
    }

    String encodedData =
        data != null ? json.encode(data, toEncodable: toJsonEncodable) : null;
    for (int i = 0; i < _logListeners.length; ++i) {
      _logListeners[i](channel, message, encodedData);
    }
  }

  void debugLog(String channel, LogMessageCallback message,
      {LogDataCallback data, ToJsonEncodable toJsonEncodable}) {
    assert(() {
      log(channel, message, data: data, toJsonEncodable: toJsonEncodable);
      return true;
    }());
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

  void _addChannelInstallHandler(_ChannelInstallHandler handler) {
    _channelInstallHandlers.add(handler);
  }

  void _installHandlers(String name) {
    // Install and remove associated handler.
    _channelInstallHandlers.removeWhere((handler) => handler(name));
  }

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
