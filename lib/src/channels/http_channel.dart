/// Simple WIP http channel based on POC in https://github.com/pq/logs/issues/6

import 'dart:async';
import 'dart:io';

import 'package:logs/logs.dart';

final _HttpOverrides _httpOverrides = _HttpOverrides();

final Log _log = Log('http');

/// Hook to install the http channel.
void installHttpChannel() {
  if (!_log.enabled) {
    _log.enabled = true;
  }

  HttpOverrides.global = _httpOverrides;
}

class LoggingHttpClient implements HttpClient {
  HttpClient proxy;

  @override
  Duration connectionTimeout;

  @override
  Duration idleTimeout;

  @override
  int maxConnectionsPerHost;

  @override
  String userAgent;

  int count = 1;

  LoggingHttpClient({SecurityContext context}) {
    HttpOverrides.global = null;
    proxy = HttpClient(context: context);
    HttpOverrides.global = _httpOverrides;
  }

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String realm) f) {
    todo('authenticate');
    proxy.authenticate = f;
  }

  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String realm)
          f) {
    todo('authenticateProxy');
    proxy.authenticateProxy = f;
  }

  @override
  bool get autoUncompress => proxy.autoUncompress;

  set autoUncompress(bool value) {
    proxy.autoUncompress = value;
  }

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port) callback) {
    todo('badCertificateCallback');
    proxy.badCertificateCallback = callback;
  }

  @override
  set findProxy(String Function(Uri url) f) {
    todo('findProxy');
    proxy.findProxy = f;
  }

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    todo('addCredentials');
    proxy.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {
    todo('addProxyCredentials');
    proxy.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  void close({bool force = false}) {
    todo('close');
    proxy.close(force: force);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    todo('delete');
    return proxy.delete(host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    todo('deleteUrl');
    return proxy.deleteUrl(url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    _log.log(() => 'getUrl: $host $port $path');
    return proxy.get(host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    _log.log(() => 'getUrl: $url');
    return proxy.getUrl(url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    todo('head');
    return proxy.head(host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    todo('headUrl');
    return proxy.headUrl(url);
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    todo('open');
    return proxy.open(method, host, port, path);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    final int id = count++;

    // #1 • GET • https://flutter.io open
    _log.log(() => '#$id \u2022 $method \u2022 $url open');

    Future<HttpClientRequest> request = proxy.openUrl(method, url);
    return request.then((HttpClientRequest req) {
      // todo (pq): consider putting id in sequence number?
      _log.log(() => '#$id \u2022 $method \u2022 $url request ready');

      req.done.then((HttpClientResponse response) {
        _log.log(() =>
            '#$id \u2022 $method \u2022 $url ${response.statusCode} ${response.reasonPhrase} ${response.contentLength} bytes');
      });

      return req;
    });
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    todo('patch');
    return proxy.patch(host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    todo('patchUrl');
    return proxy.patchUrl(url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    todo('post');
    return proxy.post(host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    todo('postUrl');
    return proxy.postUrl(url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    todo('put');
    return proxy.put(host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    todo('putUrl');
    return proxy.putUrl(url);
  }
}

void todo(String msg) {
  print('TODO: $msg');
}

class _HttpOverrides extends HttpOverrides {
  HttpClient createHttpClient(SecurityContext context) =>
      LoggingHttpClient(context: context);
}
