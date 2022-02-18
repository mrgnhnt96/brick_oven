import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:test/test.dart';

void main() {
  late BrickWatcher watcher;

  group('$BrickWatcher', () {
    setUp(() {
      watcher = BrickWatcher('dir');
    });

    test('can be initiated', () {
      expect(() => BrickWatcher('dir'), returnsNormally);
    });

    group('#isRunning', () {
      test('is false when listener is null', () {
        expect(watcher.isRunning, isFalse);

        watcher.addEvent(() {});

        expect(watcher.isRunning, false);
      });

      test(
        'is false when there are no events',
        () {
          expect(watcher.isRunning, isFalse);

          watcher.start();

          expect(watcher.isRunning, isFalse);
        },
        skip: true,
      );

      test(
        'is true when there are events and a listener',
        () {
          expect(watcher.isRunning, isFalse);

          watcher
            ..addEvent(() {})
            ..start();

          expect(watcher.isRunning, isTrue);
        },
        skip: true,
      );
    });

    group('#addEvent', () {
      test('adds an event', () {
        final watcher = BrickWatcher('dir');

        expect(() => watcher.addEvent(() {}), returnsNormally);

        expect(watcher.events.length, 1);
      });
    });

    group(
      '#start',
      () {
        test('creates a listener', () {
          expect(() => watcher.start(), returnsNormally);

          expect(watcher.listener, isNotNull);
        });

        test('calls reset when listener is not null', () {
          expect(() => watcher.start(), returnsNormally);

          expect(watcher.listener, isNotNull);

          expect(() => watcher.start(), returnsNormally);

          expect(watcher.listener, isNotNull);
        });

        test('sets has run to true', () {
          expect(watcher.hasRun, isFalse);

          watcher.start();

          // expectLater(watcher.hasRun, isTrue);
        });

        test('calls all the events', () {
          // ignore: unused_local_variable
          var hasRunEvent = false;

          watcher
            ..addEvent(() {
              hasRunEvent = true;
            })
            ..start();

          // expect(hasRunEvent, isTrue);
        });
      },
      skip: true,
    );

    group(
      '#reset',
      () {
        test('calls stop then start', () {
          expect(() => watcher.reset(), returnsNormally);

          expect(watcher.listener, isNotNull);
        });
      },
      skip: true,
    );

    group('#stop', () {
      test('sets listener to null', () {
        expect(() => watcher.stop(), returnsNormally);

        expect(watcher.listener, isNull);
      });
    });
  });
}
