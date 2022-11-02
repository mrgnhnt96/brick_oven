import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:file/file.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../utils/testing_env.dart';

void main() {
  group('$BrickWatcher', () {
    late FileSystem fs;
    late BrickWatcher watcher;
    late BrickWatcher brickWatcher;
    late File file;

    setUp(() {
      fs = setUpTestingEnvironment();

      watcher = BrickWatcher(fs.currentDirectory.path);

      file = fs.file(p.join(fs.currentDirectory.path, 'file.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('sah dude');

      final mockDirWatcher = MockDirectoryWatcher();

      brickWatcher = BrickWatcher.config(
        dirPath: fs.currentDirectory.path,
        watcher: mockDirWatcher,
      );

      when(() => mockDirWatcher.ready)
          .thenAnswer((_) => Future<bool>.value(true));

      when(() => mockDirWatcher.events).thenAnswer(
        (_) => Stream.value(WatchEvent(ChangeType.MODIFY, file.path)),
      );
    });

    tearDown(() {
      tearDownTestingEnvironment(fs);
    });

    group('#config', () {
      test('should create an instance without explicit logger', () {
        expect(
          () => BrickWatcher.config(
            dirPath: fs.currentDirectory.path,
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

        test('sets has run to true', () async {
          expect(brickWatcher.hasRun, isFalse);

          await brickWatcher.start();

          await expectLater(brickWatcher.hasRun, isTrue);
        });

        test('calls all the events', () async {
          var hasRunEvent = false;

          brickWatcher.addEvent(() {
            hasRunEvent = true;
          });

          await brickWatcher.start();

          expect(hasRunEvent, isTrue);
        });

        test('calls all the before events', () async {
          var hasRunEvent = false;

          brickWatcher.addEvent(
            () {
              hasRunEvent = true;
            },
            runBefore: true,
          );

          await brickWatcher.start();

          expect(hasRunEvent, isTrue);
        });

        test('calls all the after events', () async {
          var hasRunEvent = false;

          brickWatcher.addEvent(
            () {
              hasRunEvent = true;
            },
            runAfter: true,
          );

          await brickWatcher.start();

          expect(hasRunEvent, isTrue);
        });
      },
    );

    group(
      '#reset',
      () {
        test('calls stop then start', () async {
          await watcher.reset();

          expect(watcher.listener, isNotNull);
        });
      },
    );

    group('#stop', () {
      test('sets listener to null', () async {
        await watcher.start();

        expect(watcher.listener, isNotNull);

        await watcher.stop();

        expect(watcher.listener, isNull);
      });
    });
  });
}

class MockDirectoryWatcher extends Mock implements DirectoryWatcher {}
