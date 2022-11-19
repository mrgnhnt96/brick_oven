import 'dart:async';
import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
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
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  tearDown(() {
    KeyPressListener.stream = null;
  });

  group('#keyListener', () {
    test('returns super $KeyPressListener', () {
      final listener = KeyPressListener(
        stdin: MockStdin(),
        logger: mockLogger,
        toExit: (_) {},
      );

      final instance = TestOvenMixin(
        keyPressListener: listener,
        logger: mockLogger,
        fileWatchers: {},
      );

      expect(instance.keyListener, listener);

      verifyNoMoreInteractions(mockLogger);
    });

    test('returns default $KeyPressListener', () {
      final instance = TestOvenMixin(
        logger: mockLogger,
        fileWatchers: {},
      );

      expect(instance.keyListener, isA<KeyPressListener>());

      verifyNoMoreInteractions(mockLogger);
    });

    group('default $KeyPressListener', () {
      test('calls toExit  when key is pressed', () async {
        final instance = TestOvenMixin(
          logger: mockLogger,
          fileWatchers: {},
        );

        final listener = instance.keyListener;
        final toExit = listener.toExit;
        const exitCode = ExitCode.success;

        expect(() => toExit(exitCode.code), returnsNormally);

        verifyNoMoreInteractions(mockLogger);
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

        verifyNoMoreInteractions(mockLogger);
      });
    });
  });

  group('cook', () {
    late Brick mockBrick;
    late BrickSource mockBrickSource;
    late SourceWatcher mockSourceWatcher;
    late FileWatcher mockFileWatcher;
    late KeyPressListener mockKeyPressListener;

    setUp(() {
      mockBrick = MockBrick();
      mockBrickSource = MockBrickSource();
      mockSourceWatcher = MockSourceWatcher();
      mockFileWatcher = MockFileWatcher();
      mockKeyPressListener = MockKeyPressListener();

      when(() => mockBrick.source).thenReturn(mockBrickSource);
      when(() => mockBrickSource.watcher).thenReturn(mockSourceWatcher);
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

      verifyInOrder([
        mockLogger.preheat,
        () => mockBrick.cook(output: 'my_path'),
        mockLogger.dingDing,
      ]);

      verifyNever(mockKeyPressListener.listenToKeystrokes);
      verifyNever(() => mockFileWatcher.events);
      verifyNever(mockSourceWatcher.start);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
      verifyNoMoreInteractions(mockKeyPressListener);
    });

    test('prints warning and error when $ConfigException is thrown', () async {
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

      verifyInOrder([
        mockLogger.preheat,
        () => mockBrick.cook(output: 'my_path'),
        () => mockLogger.warn('my error'),
        () => mockLogger.err('Could not cook brick: BRICK'),
        mockLogger.dingDing,
      ]);

      verifyNever(mockKeyPressListener.listenToKeystrokes);
      verifyNever(() => mockFileWatcher.events);
      verifyNever(mockSourceWatcher.start);

      verify(() => mockBrick.name).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
      verifyNoMoreInteractions(mockKeyPressListener);
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

      verifyInOrder([
        mockLogger.preheat,
        () => mockBrick.cook(output: 'my_path'),
        () => mockLogger.warn('Unknown error: Exception: my error'),
        () => mockLogger.err('Could not cook brick: BRICK'),
        mockLogger.dingDing,
      ]);

      verifyNever(mockKeyPressListener.listenToKeystrokes);
      verifyNever(() => mockFileWatcher.events);
      verifyNever(mockSourceWatcher.start);

      verify(() => mockBrick.name).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
      verifyNoMoreInteractions(mockKeyPressListener);
    });
  });

  group('watch', () {
    late Stdin mockStdin;
    late Logger mockLogger;
    late Brick mockBrick;
    late BrickSource mockBrickSource;
    late Progress mockProgress;
    late SourceWatcher mockSourceWatcher;
    late Completer<int> exitCompleter;
    late FileWatcher mockFileWatcher;
    late TestFileWatcher testFileWatcher;
    late KeyPressListener keyPressListener;
    late TestDirectoryWatcher testDirectoryWatcher;

    setUp(() {
      mockBrick = MockBrick();
      mockStdin = MockStdin();
      mockLogger = MockLogger();
      mockBrickSource = MockBrickSource();
      mockSourceWatcher = MockSourceWatcher();
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

      when(() => mockBrick.source).thenReturn(mockBrickSource);
      when(() => mockBrickSource.watcher).thenReturn(mockSourceWatcher);

      when(() => mockSourceWatcher.hasRun).thenAnswer((_) => true);
      when(mockSourceWatcher.start).thenAnswer((_) => Future.value());
      when(mockSourceWatcher.stop).thenAnswer((_) => Future.value());

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

      verifyInOrder([
        mockLogger.preheat,
        () => mockBrick.cook(output: 'my_path', watch: true),
        mockLogger.dingDing,
        mockLogger.watching,
        mockLogger.quit,
        mockLogger.reload,
      ]);

      verify(() => mockFileWatcher.events).called(1);

      verify(
        () => mockSourceWatcher.addEvent(any(), runBefore: true),
      ).called(2);
      verify(
        () => mockSourceWatcher.addEvent(any(), runAfter: true),
      ).called(3);

      verify(() => mockBrick.source).called(1);
      verify(() => mockBrick.configPath).called(1);
      verify(() => mockBrickSource.watcher).called(1);

      verify(mockLogger.exiting).called(1);

      final exitCode = await exitCompleter.future;
      // expects success because `q` was pressed
      expect(exitCode, ExitCode.success.code);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
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
        source: mockBrickSource,
        fileSystem: MemoryFileSystem(),
        logger: mockLogger,
      );

      unawaited(
        oven.putInOven({brick}).then(
          (exitCode) => exitCompleter.complete(exitCode.code),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      verify(() => mockSourceWatcher.addEvent(any(), runBefore: true))
          .called(2);
      verify(() => mockSourceWatcher.addEvent(any())).called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runAfter: true)).called(3);

      testFileWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

      await Future<void>.delayed(Duration.zero);

      verifyInOrder([
        mockLogger.preheat,
        () => mockLogger.progress('Writing Brick: BRICK'),
        mockSourceWatcher.start,
        mockLogger.dingDing,
        mockLogger.watching,
        mockLogger.quit,
        mockLogger.reload,
        mockLogger.configChanged,
        mockSourceWatcher.stop,
      ]);

      final exitCode = await exitCompleter.future;
      expect(exitCode, ExitCode.tempFail.code);

      verify(() => mockSourceWatcher.hasRun).called(1);
      verify(() => mockBrickSource.watcher).called(3);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
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
        source: mockBrickSource,
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

      verify(() => mockSourceWatcher.addEvent(any(), runBefore: true))
          .called(2);
      verify(() => mockSourceWatcher.addEvent(any())).called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runAfter: true)).called(3);

      testFileWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

      await Future<void>.delayed(Duration.zero);

      verifyInOrder([
        mockLogger.preheat,
        () => mockLogger.progress('Writing Brick: BRICK'),
        mockSourceWatcher.start,
        mockLogger.dingDing,
        mockLogger.watching,
        mockLogger.quit,
        mockLogger.reload,
        mockLogger.configChanged,
        mockSourceWatcher.stop,
      ]);

      final exitCode = await exitCompleter.future;
      expect(exitCode, ExitCode.tempFail.code);

      verify(() => mockSourceWatcher.hasRun).called(1);
      verify(() => mockBrickSource.watcher).called(3);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
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
          watcher: SourceWatcher.config(
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

      testDirectoryWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

      await Future<void>.delayed(Duration.zero);

      keyController.add('q'.codeUnits);

      await Future<void>.delayed(Duration.zero);

      verifyInOrder([
        mockLogger.preheat,
        () => mockLogger.progress('Writing Brick: BRICK'),
        mockLogger.dingDing,
        mockLogger.watching,
        mockLogger.quit,
        mockLogger.reload,
        () => mockLogger.fileChanged('BRICK'),
        mockLogger.preheat,
        mockLogger.dingDing,
        mockLogger.watching,
        mockLogger.quit,
        mockLogger.reload,
        mockLogger.exiting,
      ]);

      final exitCode = await exitCompleter.future;
      // expects success because `q` was pressed
      expect(exitCode, ExitCode.success.code);

      verify(() => mockProgress.complete('BRICK: cooked 0 files')).called(2);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockFileWatcher);
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
        source: mockBrickSource,
        fileSystem: MemoryFileSystem(),
        logger: mockLogger,
      );

      unawaited(
        oven.putInOven({brick}).then(
          (exitCode) => exitCompleter.complete(exitCode.code),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      keyController.add('r'.codeUnits);

      await Future<void>.delayed(Duration.zero);

      verifyInOrder([
        mockLogger.preheat,
        () => mockLogger.progress('Writing Brick: BRICK'),
        mockSourceWatcher.start,
        mockLogger.dingDing,
        mockLogger.watching,
        mockLogger.quit,
        mockLogger.reload,
        () => mockLogger.info('\nRestarting...'),
      ]);

      final exitCode = await exitCompleter.future;
      // expects success because `q` was pressed
      expect(exitCode, ExitCode.tempFail.code);

      verify(() => mockSourceWatcher.hasRun).called(1);
      verify(() => mockBrickSource.watcher).called(2);

      verify(() => mockSourceWatcher.addEvent(any())).called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runBefore: true))
          .called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runAfter: true)).called(3);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
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
        source: mockBrickSource,
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

      verify(mockLogger.exiting).called(1);

      final exitCode = await exitCompleter.future;
      // expects success because `q` was pressed
      expect(exitCode, ExitCode.success.code);

      verifyInOrder([
        mockLogger.preheat,
        () => mockLogger.progress('Writing Brick: BRICK'),
        mockSourceWatcher.start,
        mockLogger.dingDing,
        mockLogger.watching,
        mockLogger.quit,
        mockLogger.reload,
      ]);

      verify(() => mockBrickSource.watcher).called(2);

      verify(() => mockSourceWatcher.addEvent(any())).called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runBefore: true))
          .called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runAfter: true)).called(3);
      verify(() => mockSourceWatcher.hasRun).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
    });
  });
}

class TestOvenMixin extends BrickOvenCommand
    with BrickCooker, BrickCookerArgs, ConfigWatcherMixin, OvenMixin {
  TestOvenMixin({
    this.keyPressListener,
    required Logger logger,
    this.outputDir = '',
    required this.fileWatchers,
    this.isWatch = false,
    this.shouldSync = true,
  }) : super(
          logger: logger,
          fileSystem: MemoryFileSystem(),
        );

  @override
  final bool isWatch;

  @override
  final bool shouldSync;

  @override
  final KeyPressListener? keyPressListener;

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

  @override
  String get description => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();
}

class TextConfigException extends ConfigException {
  TextConfigException(this.message);

  @override
  final String message;
}
