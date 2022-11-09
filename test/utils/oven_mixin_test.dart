import 'dart:async';
import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:brick_oven/utils/oven_mixin.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../test_utils/mocks.dart';
import '../test_utils/test_directory_watcher.dart';
import '../test_utils/test_file_watcher.dart';

void main() {
  tearDown(() {
    KeyPressListener.stream = null;
  });

  group('#keyListener', () {
    test('returns super $KeyPressListener', () {
      final listener = KeyPressListener(
        stdin: MockStdin(),
        logger: MockLogger(),
        toExit: (_) {},
      );

      final instance = TestOvenMixin(
        keyPressListener: listener,
        logger: MockLogger(),
        fileWatchers: {},
      );

      expect(instance.keyListener, listener);
    });

    test('returns default $KeyPressListener', () {
      final instance = TestOvenMixin(
        logger: MockLogger(),
        fileWatchers: {},
      );

      expect(instance.keyListener, isA<KeyPressListener>());
    });

    group('default $KeyPressListener', () {
      late Logger mockLogger;

      setUp(() {
        mockLogger = MockLogger();
      });

      test('calls toExit with ExitCode.tempFail when key is pressed', () async {
        final instance = TestOvenMixin(
          logger: mockLogger,
          fileWatchers: {},
        );

        final listener = instance.keyListener;
        final toExit = listener.toExit;
        const exitCode = ExitCode.success;

        expect(() => toExit(exitCode.code), returnsNormally);
      });

      test('exits with code provided to toExit', () async {
        final instance = TestOvenMixin(
          logger: mockLogger,
          fileWatchers: {},
        );

        final listener = instance.keyListener;
        final toExit = listener.toExit;
        const exitCode = ExitCode.ioError;

        expect(() async => toExit(exitCode.code), returnsNormally);
      });
    });
  });

  group('cook', () {
    group('mock', () {
      late MockBrick mockBrick;
      late MockLogger mockLogger;
      late MockSource mockSource;
      late MockWatcher mockWatcher;
      late MockFileWatcher mockFileWatcher;
      late MockKeyPressListener mockKeyPressListener;

      setUp(() {
        mockBrick = MockBrick();
        mockLogger = MockLogger();
        mockSource = MockSource();
        mockWatcher = MockWatcher();
        mockFileWatcher = MockFileWatcher();
        mockKeyPressListener = MockKeyPressListener();

        when(() => mockBrick.source).thenReturn(mockSource);
        when(() => mockSource.watcher).thenReturn(mockWatcher);
      });

      test('runs gracefully', () async {
        final oven = TestOvenMixin(
          keyPressListener: mockKeyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
        );

        final result = await oven.putInOven({mockBrick});
        expect(result.code, ExitCode.success.code);

        verify(mockLogger.cooking).called(1);
        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);

        verifyNever(mockKeyPressListener.listenToKeystrokes);
        verifyNever(() => mockFileWatcher.events);
        verifyNever(mockWatcher.start);
        verify(() => mockBrick.cook(output: 'my_path')).called(1);
      });

      test('prints warning and error when $ConfigException is thrown',
          () async {
        when(() => mockBrick.name).thenReturn('BRICK');

        when(() => mockBrick.cook(output: any(named: 'output')))
            .thenThrow(TextConfigException('my error'));

        final oven = TestOvenMixin(
          keyPressListener: mockKeyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
        );

        final result = await oven.putInOven({mockBrick});
        expect(result.code, ExitCode.success.code);

        verify(mockLogger.cooking).called(1);
        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);

        verifyNever(mockKeyPressListener.listenToKeystrokes);
        verifyNever(() => mockFileWatcher.events);
        verifyNever(mockWatcher.start);
        verify(() => mockBrick.cook(output: 'my_path')).called(1);

        verify(() => mockLogger.warn('my error')).called(1);
        verify(() => mockLogger.err('Could not cook brick: BRICK')).called(1);
      });

      test('prints warning and error when $Exception is thrown', () async {
        when(() => mockBrick.name).thenReturn('BRICK');

        when(() => mockBrick.cook(output: any(named: 'output')))
            .thenThrow(Exception('my error'));

        final oven = TestOvenMixin(
          keyPressListener: mockKeyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
        );

        final result = await oven.putInOven({mockBrick});
        expect(result.code, ExitCode.success.code);

        verify(mockLogger.cooking).called(1);
        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);

        verifyNever(mockKeyPressListener.listenToKeystrokes);
        verifyNever(() => mockFileWatcher.events);
        verifyNever(mockWatcher.start);
        verify(() => mockBrick.cook(output: 'my_path')).called(1);

        verify(() => mockLogger.warn('Unknown error: Exception: my error'))
            .called(1);
        verify(() => mockLogger.err('Could not cook brick: BRICK')).called(1);
      });
    });

    group('write to file system', () {});
  });

  group('watch', () {
    group('mock', () {
      late Stdin mockStdin;
      late Logger mockLogger;
      late MockBrick mockBrick;
      late MockSource mockSource;
      late Progress mockProgress;
      late MockWatcher mockWatcher;
      late Completer<int> exitCompleter;
      late MockFileWatcher mockFileWatcher;
      late TestFileWatcher testFileWatcher;
      late KeyPressListener keyPressListener;
      late TestDirectoryWatcher testDirectoryWatcher;

      setUp(() {
        mockBrick = MockBrick();
        mockStdin = MockStdin();
        mockLogger = MockLogger();
        mockSource = MockSource();
        mockWatcher = MockWatcher();
        mockProgress = MockProgress();
        exitCompleter = Completer<int>();
        testFileWatcher = TestFileWatcher();
        mockFileWatcher = MockFileWatcher();
        testDirectoryWatcher = TestDirectoryWatcher();

        keyPressListener = KeyPressListener(
          stdin: mockStdin,
          logger: mockLogger,
          toExit: exitCompleter.complete,
        );

        when(() => mockLogger.progress(any())).thenReturn(mockProgress);

        when(() => mockStdin.hasTerminal).thenReturn(true);

        when(() => mockBrick.source).thenReturn(mockSource);
        when(() => mockSource.watcher).thenReturn(mockWatcher);

        when(() => mockWatcher.hasRun).thenAnswer((_) => true);
        when(mockWatcher.start).thenAnswer((_) => Future.value());
        when(mockWatcher.stop).thenAnswer((_) => Future.value());

        when(() => mockFileWatcher.events)
            .thenAnswer((_) => const Stream.empty());

        when(mockStdin.asBroadcastStream).thenAnswer(
          (_) => Stream.fromIterable([
            'q'.codeUnits,
            // [0x1b] // escape
          ]),
        );
      });

      tearDown(() {
        testFileWatcher.close();
        testDirectoryWatcher.close();
      });

      test('runs gracefully', () async {
        final oven = TestOvenMixin(
          keyPressListener: keyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          isWatch: true,
          fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
        );

        unawaited(oven.putInOven({mockBrick}));
        // expect(result.code, ExitCode.success.code);

        await Future<void>.delayed(Duration.zero);

        verify(mockLogger.cooking).called(1);
        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);
        verify(mockLogger.watching).called(1);

        // this verifies -> verify(mockLogger.keyStrokes)).called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press q to quit...')))
            .called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press r to reload...')))
            .called(1);

        verify(() => mockFileWatcher.events).called(1);

        verify(
          () => mockWatcher.addEvent(any(), runBefore: true),
        ).called(2);
        verify(
          () => mockWatcher.addEvent(any(), runAfter: true),
        ).called(2);

        verify(() => mockBrick.cook(output: 'my_path', watch: true)).called(1);

        verify(() => mockLogger.info('\nExiting...')).called(1);

        final exitCode = await exitCompleter.future;
        // expects success because `q` was pressed
        expect(exitCode, ExitCode.success.code);
      });

      test('calls config changed on config modify event', () async {
        final keyController = StreamController<List<int>>();

        when(mockStdin.asBroadcastStream).thenAnswer(
          (_) => keyController.stream,
        );

        final oven = TestOvenMixin(
          keyPressListener: keyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          isWatch: true,
          fileWatchers: {BrickOvenYaml.file: testFileWatcher},
        );

        final brick = Brick.memory(
          name: 'BRICK',
          source: mockSource,
          fileSystem: MemoryFileSystem(),
          logger: mockLogger,
        );

        unawaited(
          oven.putInOven({brick}).then(
            (exitCode) => exitCompleter.complete(exitCode.code),
          ),
        );

        await Future<void>.delayed(Duration.zero);

        verify(mockLogger.cooking).called(1);
        verify(() => mockLogger.progress('Writing Brick: BRICK')).called(1);

        verify(mockWatcher.start).called(1);
        verify(() => mockWatcher.addEvent(any(), runBefore: true)).called(2);
        verify(() => mockWatcher.addEvent(any(), runAfter: true)).called(3);

        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);
        verify(mockLogger.watching).called(1);

        // this verifies -> verify(mockLogger.keyStrokes)).called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press q to quit...')))
            .called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press r to reload...')))
            .called(1);

        testFileWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

        await Future<void>.delayed(Duration.zero);

        verify(mockLogger.configChanged).called(1);

        // keyController.add('q'.codeUnits);

        await Future<void>.delayed(Duration.zero);

        verify(mockWatcher.stop).called(1);

        final exitCode = await exitCompleter.future;
        expect(exitCode, ExitCode.tempFail.code);
      });

      test('calls config changed on config path modify event', () async {
        final keyController = StreamController<List<int>>();

        when(mockStdin.asBroadcastStream).thenAnswer(
          (_) => keyController.stream,
        );

        final oven = TestOvenMixin(
          keyPressListener: keyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          isWatch: true,
          fileWatchers: {'config_path': testFileWatcher},
        );

        final brick = Brick.memory(
          name: 'BRICK',
          source: mockSource,
          fileSystem: MemoryFileSystem(),
          logger: mockLogger,
          configPath: 'config_path',
        );

        unawaited(
          oven.putInOven({brick}).then(
            (exitCode) => exitCompleter.complete(exitCode.code),
          ),
        );

        await Future<void>.delayed(Duration.zero);

        verify(mockLogger.cooking).called(1);
        verify(() => mockLogger.progress('Writing Brick: BRICK')).called(1);
        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);
        verify(mockLogger.watching).called(1);

        // this verifies -> verify(mockLogger.keyStrokes)).called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press q to quit...')))
            .called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press r to reload...')))
            .called(1);

        verify(mockWatcher.start).called(1);
        verify(() => mockWatcher.addEvent(any(), runBefore: true)).called(2);
        verify(() => mockWatcher.addEvent(any(), runAfter: true)).called(3);

        testFileWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

        await Future<void>.delayed(Duration.zero);

        verify(mockLogger.configChanged).called(1);

        await Future<void>.delayed(Duration.zero);

        verify(mockWatcher.stop).called(1);

        final exitCode = await exitCompleter.future;
        expect(exitCode, ExitCode.tempFail.code);
      });

      test('calls file changed on source file modify event', () async {
        final keyController = StreamController<List<int>>();

        when(mockStdin.asBroadcastStream).thenAnswer(
          (_) => keyController.stream,
        );

        final oven = TestOvenMixin(
          keyPressListener: keyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          isWatch: true,
          fileWatchers: {BrickOvenYaml.file: testFileWatcher},
        );

        final brick = Brick.memory(
          name: 'BRICK',
          source: BrickSource.memory(
            localPath: '',
            fileSystem: MemoryFileSystem(),
            watcher: BrickWatcher.config(
              dirPath: '',
              watcher: testDirectoryWatcher,
            ),
          ),
          fileSystem: MemoryFileSystem(),
          logger: mockLogger,
        );

        unawaited(
          oven.putInOven({brick}).then(
            (exitCode) => exitCompleter.complete(exitCode.code),
          ),
        );

        await Future<void>.delayed(Duration.zero);

        verify(mockLogger.cooking).called(1);
        verify(() => mockLogger.progress('Writing Brick: BRICK')).called(1);
        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);
        verify(mockLogger.watching).called(1);

        // this verifies -> verify(mockLogger.keyStrokes)).called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press q to quit...')))
            .called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press r to reload...')))
            .called(1);

        testDirectoryWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

        await Future<void>.delayed(Duration.zero);

        verify(() => mockLogger.fileChanged('BRICK')).called(1);
        verify(mockLogger.cooking).called(1);
        verify(mockLogger.watching).called(1);

        // this verifies -> verify(mockLogger.keyStrokes)).called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press q to quit...')))
            .called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press r to reload...')))
            .called(1);

        keyController.add('q'.codeUnits);

        await Future<void>.delayed(Duration.zero);

        verify(() => mockLogger.info('\nExiting...')).called(1);

        final exitCode = await exitCompleter.future;
        // expects success because `q` was pressed
        expect(exitCode, ExitCode.success.code);
      });

      test('reloads when r is pressed', () async {
        final keyController = StreamController<List<int>>();

        when(mockStdin.asBroadcastStream).thenAnswer(
          (_) => keyController.stream,
        );

        final oven = TestOvenMixin(
          keyPressListener: keyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          isWatch: true,
          fileWatchers: {BrickOvenYaml.file: testFileWatcher},
        );

        final brick = Brick.memory(
          name: 'BRICK',
          source: mockSource,
          fileSystem: MemoryFileSystem(),
          logger: mockLogger,
        );

        unawaited(
          oven.putInOven({brick}).then(
            (exitCode) => exitCompleter.complete(exitCode.code),
          ),
        );

        keyController.add('r'.codeUnits);

        await Future<void>.delayed(Duration.zero);

        verify(() => mockLogger.info('\nRestarting...')).called(1);
        verify(mockLogger.cooking).called(1);
        verify(() => mockLogger.progress('Writing Brick: BRICK')).called(1);
        // this could possibly fail since this prints the time
        verify(mockLogger.cooked).called(1);
        verify(mockLogger.watching).called(1);

        // this verifies -> verify(mockLogger.keyStrokes)).called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press q to quit...')))
            .called(1);
        verify(() => mockLogger.info(darkGray.wrap('Press r to reload...')))
            .called(1);

        await Future<void>.delayed(Duration.zero);

        final exitCode = await exitCompleter.future;
        // expects success because `q` was pressed
        expect(exitCode, ExitCode.tempFail.code);
      });

      test('quits when q is pressed', () async {
        final keyController = StreamController<List<int>>();

        when(mockStdin.asBroadcastStream).thenAnswer(
          (_) => keyController.stream,
        );

        final oven = TestOvenMixin(
          keyPressListener: keyPressListener,
          logger: mockLogger,
          outputDir: 'my_path',
          isWatch: true,
          fileWatchers: {BrickOvenYaml.file: testFileWatcher},
        );

        final brick = Brick.memory(
          name: 'BRICK',
          source: mockSource,
          fileSystem: MemoryFileSystem(),
          logger: mockLogger,
        );

        unawaited(
          oven.putInOven({brick}).then(
            (exitCode) => exitCompleter.complete(exitCode.code),
          ),
        );

        keyController.add('q'.codeUnits);

        await Future<void>.delayed(Duration.zero);

        verify(() => mockLogger.info('\nExiting...')).called(1);

        final exitCode = await exitCompleter.future;
        // expects success because `q` was pressed
        expect(exitCode, ExitCode.success.code);
      });
    });

    group('write to file system', () {});
  });
}

class TestOvenMixin extends BrickCooker with OvenMixin {
  TestOvenMixin({
    this.keyPressListener,
    required this.logger,
    this.outputDir = '',
    required this.fileWatchers,
    this.isWatch = false,
  });

  @override
  final bool isWatch;

  @override
  final KeyPressListener? keyPressListener;

  @override
  final Logger logger;

  @override
  final String outputDir;

  final Map<String, FileWatcher?>? fileWatchers;

  @override
  FileWatcher watcher(String path) {
    final watcher = fileWatchers?[path];

    if (watcher != null) {
      return watcher;
    }

    return super.watcher(path);
  }
}

class TextConfigException extends ConfigException {
  TextConfigException(this.message);

  @override
  final String message;
}
