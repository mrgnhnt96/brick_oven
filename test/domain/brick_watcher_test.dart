import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../test_utils/test_directory_watcher.dart';

void main() {
  group('$BrickWatcher', () {
    late BrickWatcher watcher;
    late TestDirectoryWatcher testDirectoryWatcher;

    setUp(() {
      testDirectoryWatcher = TestDirectoryWatcher();

      watcher = BrickWatcher.config(
        dirPath: 'some/path',
        watcher: testDirectoryWatcher,
      );
    });

    tearDown(() {
      testDirectoryWatcher.close();
    });

    group('#config', () {
      test('should create an instance without explicit logger', () {
        expect(
          () => BrickWatcher.config(
            dirPath: 'my/test/path',
            watcher: MockDirectoryWatcher(),
          ),
          returnsNormally,
        );
      });
    });

    test('can be initiated', () {
      expect(() => BrickWatcher(''), returnsNormally);
    });

    group('#isRunning', () {
      test('is false when listener is null', () {
        expect(watcher.isRunning, isFalse);

        watcher.addEvent(() {});

        expect(watcher.isRunning, false);
      });

      test(
        'is false when there are no events',
        () async {
          expect(watcher.isRunning, isFalse);

          await watcher.start();

          expect(watcher.isRunning, isFalse);
        },
      );

      test(
        'is true when there are events and a listener',
        () async {
          expect(watcher.isRunning, isFalse);

          watcher.addEvent(() {});

          await watcher.start();

          expect(watcher.isRunning, isTrue);
        },
      );

      test('is true when there are before events and a listener', () async {
        expect(watcher.isRunning, isFalse);

        watcher.addEvent(() {}, runBefore: true);

        await watcher.start();

        expect(watcher.isRunning, isTrue);
      });

      test('is true when there are after events and a listener', () async {
        expect(watcher.isRunning, isFalse);

        watcher.addEvent(() {}, runAfter: true);

        await watcher.start();

        expect(watcher.isRunning, isTrue);
      });
    });

    group('#addEvent', () {
      test('adds an event', () {
        expect(() => watcher.addEvent(() {}), returnsNormally);

        expect(watcher.events.length, 1);
      });

      test('adds a pre event', () {
        expect(() => watcher.addEvent(() {}, runBefore: true), returnsNormally);

        expect(watcher.beforeEvents.length, 1);
      });

      test('adds a post event', () {
        expect(() => watcher.addEvent(() {}, runAfter: true), returnsNormally);

        expect(watcher.afterEvents.length, 1);
      });
    });

    group(
      '#start',
      () {
        test('creates a listener', () async {
          expect(watcher.listener, isNull);

          await watcher.start();

          expect(watcher.listener, isNotNull);
        });

        test('calls reset when listener is not null', () async {
          await watcher.start();

          final listener1 = watcher.listener;

          expect(watcher.listener, isNotNull);

          await watcher.start();

          final listener2 = watcher.listener;

          expect(watcher.listener, isNotNull);

          expect(listener1, isNot(equals(listener2)));
        });

        test('sets #hasRun to true', () async {
          expect(watcher.hasRun, isFalse);

          await watcher.start();

          await expectLater(watcher.hasRun, isTrue);
        });

        test('calls all the events', () async {
          var hasRunEvent = false;

          watcher.addEvent(() {
            hasRunEvent = true;
          });

          await watcher.start();

          expect(hasRunEvent, isTrue);
        });

        test('calls all the before events', () async {
          var hasRunEvent = false;

          watcher.addEvent(
            () {
              hasRunEvent = true;
            },
            runBefore: true,
          );

          await watcher.start();

          expect(hasRunEvent, isTrue);
        });

        test('calls all the after events', () async {
          var hasRunEvent = false;

          watcher.addEvent(
            () {
              hasRunEvent = true;
            },
            runAfter: true,
          );

          await watcher.start();

          expect(hasRunEvent, isTrue);
        });
      },
    );

    group('#reset', () {
      test('calls stop then start', () async {
        await watcher.reset();

        expect(watcher.listener, isNotNull);
      });

      test('maintains events', () async {
        watcher
          ..addEvent(() {})
          ..addEvent(() {}, runBefore: true)
          ..addEvent(() {}, runAfter: true);

        expect(watcher.events.length, 1);
        expect(watcher.beforeEvents.length, 1);
        expect(watcher.afterEvents.length, 1);

        await watcher.reset();

        expect(watcher.events.length, 1);
        expect(watcher.beforeEvents.length, 1);
        expect(watcher.afterEvents.length, 1);
      });
    });

    group('#stop', () {
      test('sets listener to null', () async {
        await watcher.start();

        expect(watcher.listener, isNotNull);

        await watcher.stop();

        expect(watcher.listener, isNull);
      });

      test('removes all events', () async {
        watcher
          ..addEvent(() {})
          ..addEvent(() {}, runAfter: true)
          ..addEvent(() {}, runBefore: true);

        expect(watcher.events.length, 1);
        expect(watcher.beforeEvents.length, 1);
        expect(watcher.afterEvents.length, 1);

        await watcher.stop();

        expect(watcher.events.length, 0);
        expect(watcher.beforeEvents.length, 0);
        expect(watcher.afterEvents.length, 0);
      });
    });
  });
}

class MockDirectoryWatcher extends Mock implements DirectoryWatcher {}
