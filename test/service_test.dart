import 'package:logs/src/logging_service.dart';
import 'package:test/test.dart';

void main() {
  group('service tests', () {
    LoggingService service;

    setUp(() {
      service = LoggingService();
    });

    test('register', () {
      expect(service.channels.containsKey('foo'), isFalse);
      service.registerChannel('foo');
      expect(service.channels.containsKey('foo'), isTrue);
    });

    test('register twice', () {
      expect(service.channels.containsKey('foo'), isFalse);
      service.registerChannel('foo');
      expect(service.channels.containsKey('foo'), isTrue);
      expect(() => service.registerChannel('foo'), throwsException);
    });

    test('enable', () {
      service.registerChannel('foo');
      expect(service.shouldLog('foo'), isFalse);
      service.enableLogging('foo', true);
      expect(service.shouldLog('foo'), isTrue);
    });

    test('enable (unregistered)', () {
      expect(service.shouldLog('foo'), isFalse);
      expect(() => service.enableLogging('foo', true), throwsException);
    });

    test('disable', () {
      service.registerChannel('foo');
      expect(service.shouldLog('foo'), isFalse);
      service.enableLogging('foo', true);
      expect(service.shouldLog('foo'), isTrue);
      service.enableLogging('foo', false);
      expect(service.shouldLog('foo'), isFalse);
    });

    test('description', () {
      service.registerChannel('foo', description: 'a channel for foos');
      expect(service.channels['foo'], 'a channel for foos');
    });

    test('channels', () {
      service.registerChannel('foo');
      service.registerChannel('bar');
      service.registerChannel('baz');
      expect(service.channels.keys, containsAll(['foo', 'bar', 'baz']));
    });
  });
}
