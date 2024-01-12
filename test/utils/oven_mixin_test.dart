import 'dart:async';
import 'dart:io';

import 'package:brick_oven/utils/di.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

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
import '../test_utils/di.dart';
import '../test_utils/mocks.dart';
import '../test_utils/test_directory_watcher.dart';
import '../test_utils/test_file_watcher.dart';

void main() {
  setUp(setupTestDi);

  tearDown(() {
    KeyPressListener.stream = null;
  });

  group('#keyListener', () {
    test('returns super $KeyPressListener', () {
      final listener = KeyPressListener(
        stdin: MockStdin(),
        toExit: (_) {},
      );

      final instance = TestOvenMixin(
        keyPressListener: listener,
        fileWatchers: {},
      );

      expect(instance.keyListener, listener);
    });

    test('returns default $KeyPressListener', () {
      final instance = TestOvenMixin(
        fileWatchers: {},
      );

      expect(instance.keyListener, isA<KeyPressListener>());

      verifyNoMoreInteractions(di<Logger>());
    });

    group('default $KeyPressListener', () {
      test('calls toExit  when key is pressed', () async {
        final instance = TestOvenMixin(
          fileWatchers: {},
        );

        final listener = instance.keyListener;
        final toExit = listener.toExit;
        const exitCode = ExitCode.success;

        expect(() => toExit(exitCode.code), returnsNormally);

        verifyNoMoreInteractions(di<Logger>());
      });

      test('exits with code provided to toExit', () async {
        final instance = TestOvenMixin(
          fileWatchers: {},
        );

        final listener = instance.keyListener;
        final toExit = listener.toExit;
        const exitCode = ExitCode.ioError;

        expect(() async => toExit(exitCode.code), returnsNormally);

        verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
      );

      final result = await oven.putInOven({mockBrick});
      expect(result.code, ExitCode.success.code);

      verifyInOrder([
        di<Logger>().preheat,
        () => mockBrick.cook(output: 'my_path'),
        di<Logger>().dingDing,
      ]);

      verifyNever(mockKeyPressListener.listenToKeystrokes);
      verifyNever(() => mockFileWatcher.events);
      verifyNever(() => mockSourceWatcher.start(any()));

      verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
      );

      final result = await oven.putInOven({mockBrick});
      expect(result.code, ExitCode.success.code);

      verifyInOrder([
        di<Logger>().preheat,
        () => mockBrick.cook(output: 'my_path'),
        () => di<Logger>().warn('my error'),
        () => di<Logger>().err('Could not cook brick: BRICK'),
        di<Logger>().dingDing,
      ]);

      verifyNever(mockKeyPressListener.listenToKeystrokes);
      verifyNever(() => mockFileWatcher.events);
      verifyNever(() => mockSourceWatcher.start(any()));

      verify(() => mockBrick.name).called(1);

      verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
      );

      final result = await oven.putInOven({mockBrick});
      expect(result.code, ExitCode.success.code);

      verifyInOrder([
        di<Logger>().preheat,
        () => mockBrick.cook(output: 'my_path'),
        () => di<Logger>().warn('Unknown error: Exception: my error'),
        () => di<Logger>().err('Could not cook brick: BRICK'),
        di<Logger>().dingDing,
      ]);

      verifyNever(mockKeyPressListener.listenToKeystrokes);
      verifyNever(() => mockFileWatcher.events);
      verifyNever(() => mockSourceWatcher.start(any()));

      verify(() => mockBrick.name).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
      verifyNoMoreInteractions(mockKeyPressListener);
    });
  });

  group('watch', () {
    late Stdin mockStdin;
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
      mockBrickSource = MockBrickSource();
      mockSourceWatcher = MockSourceWatcher();
      mockProgress = MockProgress();
      exitCompleter = Completer<int>();
      testFileWatcher = TestFileWatcher();
      mockFileWatcher = MockFileWatcher();
      testDirectoryWatcher = TestDirectoryWatcher();

      keyPressListener = KeyPressListener(
        stdin: mockStdin,
        toExit: exitCompleter.complete,
      );

      when(() => di<Logger>().progress(any())).thenReturn(mockProgress);

      when(() => mockStdin.hasTerminal).thenReturn(true);

      when(() => mockBrick.source).thenReturn(mockBrickSource);
      when(() => mockBrickSource.watcher).thenReturn(mockSourceWatcher);

      when(() => mockSourceWatcher.hasRun).thenAnswer((_) => true);
      when(() => mockSourceWatcher.start(any()))
          .thenAnswer((_) => Future.value());
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
        outputDir: 'my_path',
        isWatch: true,
        fileWatchers: {BrickOvenYaml.file: mockFileWatcher},
      );

      unawaited(oven.putInOven({mockBrick}));
      // expect(result.code, ExitCode.success.code);

      await Future<void>.delayed(Duration.zero);

      verifyInOrder([
        di<Logger>().preheat,
        () => mockBrick.cook(output: 'my_path', watch: true),
        di<Logger>().dingDing,
        di<Logger>().watching,
        di<Logger>().quit,
        di<Logger>().reload,
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

      verify(di<Logger>().exiting).called(1);

      final exitCode = await exitCompleter.future;
      // expects success because `q` was pressed
      expect(exitCode, ExitCode.success.code);

      verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        isWatch: true,
        fileWatchers: {BrickOvenYaml.file: testFileWatcher},
      );

      final brick = Brick(
        name: 'BRICK',
        source: mockBrickSource,
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
        di<Logger>().preheat,
        () => di<Logger>().progress('Writing Brick: BRICK'),
        () => mockSourceWatcher.start(any()),
        di<Logger>().dingDing,
        di<Logger>().watching,
        di<Logger>().quit,
        di<Logger>().reload,
        di<Logger>().configChanged,
        mockSourceWatcher.stop,
      ]);

      final exitCode = await exitCompleter.future;
      expect(exitCode, ExitCode.tempFail.code);

      verify(() => mockSourceWatcher.hasRun).called(1);
      verify(() => mockBrickSource.watcher).called(3);

      verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        isWatch: true,
        fileWatchers: {'config_path': testFileWatcher},
      );

      final brick = Brick(
        name: 'BRICK',
        source: mockBrickSource,
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
        di<Logger>().preheat,
        () => di<Logger>().progress('Writing Brick: BRICK'),
        () => mockSourceWatcher.start(any()),
        di<Logger>().dingDing,
        di<Logger>().watching,
        di<Logger>().quit,
        di<Logger>().reload,
        di<Logger>().configChanged,
        mockSourceWatcher.stop,
      ]);

      final exitCode = await exitCompleter.future;
      expect(exitCode, ExitCode.tempFail.code);

      verify(() => mockSourceWatcher.hasRun).called(1);
      verify(() => mockBrickSource.watcher).called(3);

      verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        isWatch: true,
        fileWatchers: {BrickOvenYaml.file: testFileWatcher},
      );

      final brick = Brick(
        name: 'BRICK',
        source: BrickSource.memory(
          localPath: '',
          watcher: SourceWatcher.config(
            dirPath: '',
            watcher: testDirectoryWatcher,
          ),
        ),
      );

      unawaited(
        oven.putInOven({brick}).then(
          (exitCode) => exitCompleter.complete(exitCode.code),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      testDirectoryWatcher
          .triggerEvent(WatchEvent(ChangeType.MODIFY, 'path/to/file.txt'));

      await Future<void>.delayed(Duration.zero);

      keyController.add('q'.codeUnits);

      await Future<void>.delayed(Duration.zero);

      verifyInOrder([
        di<Logger>().preheat,
        () => di<Logger>().progress('Writing Brick: BRICK'),
        di<Logger>().dingDing,
        di<Logger>().watching,
        di<Logger>().quit,
        di<Logger>().reload,
        () => di<Logger>().fileChanged('path/to/file.txt'),
        di<Logger>().preheat,
        di<Logger>().dingDing,
        di<Logger>().watching,
        di<Logger>().quit,
        di<Logger>().reload,
        di<Logger>().exiting,
      ]);

      final exitCode = await exitCompleter.future;
      // expects success because `q` was pressed
      expect(exitCode, ExitCode.success.code);

      verify(() => mockProgress.complete('BRICK: cooked 0 files')).called(2);

      verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        isWatch: true,
        fileWatchers: {BrickOvenYaml.file: testFileWatcher},
      );

      final brick = Brick(
        name: 'BRICK',
        source: mockBrickSource,
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
        di<Logger>().preheat,
        () => di<Logger>().progress('Writing Brick: BRICK'),
        () => mockSourceWatcher.start(any()),
        di<Logger>().dingDing,
        di<Logger>().watching,
        di<Logger>().quit,
        di<Logger>().reload,
        () => di<Logger>().info('\nRestarting...'),
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

      verifyNoMoreInteractions(di<Logger>());
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
        outputDir: 'my_path',
        isWatch: true,
        fileWatchers: {BrickOvenYaml.file: testFileWatcher},
      );

      final brick = Brick(
        name: 'BRICK',
        source: mockBrickSource,
      );

      unawaited(
        oven.putInOven({brick}).then(
          (exitCode) => exitCompleter.complete(exitCode.code),
        ),
      );

      keyController.add('q'.codeUnits);

      await Future<void>.delayed(Duration.zero);

      verify(di<Logger>().exiting).called(1);

      final exitCode = await exitCompleter.future;
      // expects success because `q` was pressed
      expect(exitCode, ExitCode.success.code);

      verifyInOrder([
        di<Logger>().preheat,
        () => di<Logger>().progress('Writing Brick: BRICK'),
        () => mockSourceWatcher.start(any()),
        di<Logger>().dingDing,
        di<Logger>().watching,
        di<Logger>().quit,
        di<Logger>().reload,
      ]);

      verify(() => mockBrickSource.watcher).called(2);

      verify(() => mockSourceWatcher.addEvent(any())).called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runBefore: true))
          .called(2);
      verify(() => mockSourceWatcher.addEvent(any(), runAfter: true)).called(3);
      verify(() => mockSourceWatcher.hasRun).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockBrick);
      verifyNoMoreInteractions(mockBrickSource);
      verifyNoMoreInteractions(mockSourceWatcher);
      verifyNoMoreInteractions(mockFileWatcher);
    });
  });
}

class TestOvenMixin extends BrickOvenCommand
    with
        BrickCooker,
        BrickCookerArgs,
        ConfigWatcherMixin,
        LoggerMixin,
        OvenMixin {
  TestOvenMixin({
    required this.fileWatchers,
    this.keyPressListener,
    this.outputDir = '',
    this.isWatch = false,
    this.shouldSync = true,
  });

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
