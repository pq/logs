import 'package:logs/src/log_manager.dart';
import 'package:test/test.dart';

void main() {
  group('manager tests', () {
    LogManager manager;
    String loggedMessage;
    String loggedChannel;
    Object loggedData;

    setUp(() {
      manager = LogManager()
        ..addListener((channel, message, data) {
          loggedMessage = message;
          loggedChannel = channel;
          loggedData = data;
        });
    });

    test('register', () {
      expect(manager.channelDescriptions.containsKey('foo'), isFalse);
      manager.registerChannel('foo');
      expect(manager.channelDescriptions.containsKey('foo'), isTrue);
    });

    test('register twice', () {
      expect(manager.channelDescriptions.containsKey('foo'), isFalse);
      manager.registerChannel('foo');
      expect(manager.channelDescriptions.containsKey('foo'), isTrue);
      expect(() => manager.registerChannel('foo'), throwsException);
    });

    test('enable', () {
      manager.registerChannel('foo');
      expect(manager.shouldLog('foo'), isFalse);
      manager.enableLogging('foo', true);
      expect(manager.shouldLog('foo'), isTrue);
    });

    test('enable (unregistered)', () {
      expect(manager.shouldLog('foo'), isFalse);
      expect(() => manager.enableLogging('foo', true), throwsException);
    });

    test('disable', () {
      manager.registerChannel('foo');
      expect(manager.shouldLog('foo'), isFalse);
      manager.enableLogging('foo', true);
      expect(manager.shouldLog('foo'), isTrue);
      manager.enableLogging('foo', false);
      expect(manager.shouldLog('foo'), isFalse);
    });

    test('description', () {
      manager.registerChannel('foo', description: 'a channel for foos');
      expect(manager.channelDescriptions['foo'], 'a channel for foos');
    });

    test('channels', () {
      manager.registerChannel('foo');
      manager.registerChannel('bar');
      manager.registerChannel('baz');
      expect(
          manager.channelDescriptions.keys, containsAll(['foo', 'bar', 'baz']));
    });

    test('log', () {
      manager.registerChannel('foo');
      manager.enableLogging('foo', true);
      manager.log('foo', () => 'bar',
          data: () => {
                'x': 1,
                'y': 2,
                'z': 3,
              });
      expect(loggedMessage, 'bar');
      expect(loggedChannel, 'foo');
      expect(loggedData, '{"x":1,"y":2,"z":3}');
    });
  });
}
