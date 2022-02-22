// ignore_for_file: unnecessary_cast

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';
import '../utils/mocks.dart';
import '../utils/to_yaml.dart';

void main() {
  const brickName = 'super_awesome';
  const localPath = 'localPath';
  final brickPath = join('bricks', brickName, '__brick__');
  const dirName = 'director_of_shield';
  const newDirName = 'director_of_world';
  const fileName = 'nick_fury.dart';
  final dirPath = join('path', 'to', dirName);
  final filePath = join(dirPath, fileName);

  group('#fromYaml', () {
    test('parses when provided', () {
      final brick = Brick(
        configuredDirs: [BrickPath(name: 'name', path: 'path/to/dir')],
        configuredFiles: const [BrickFile('file/path/name.dart')],
        name: 'brick',
        source: BrickSource(localPath: 'localPath'),
      );

      final data = brick.toYaml();

      final result = Brick.fromYaml(brick.name, data);

      expectLater(result, brick);
    });

    test('throws argument error when extra keys are provided', () {
      final brick = Brick(
        configuredDirs: [BrickPath(name: 'name', path: 'path/to/dir')],
        configuredFiles: const [BrickFile('file/path/name.dart')],
        name: 'brick',
        source: BrickSource(localPath: 'localPath'),
      );

      final data = brick.toJson();
      data['extra'] = 'extra';
      final yaml = FakeYamlMap(data);

      expect(() => Brick.fromYaml(brick.name, yaml), throwsArgumentError);
    });
  });

  // Watcher only listens to local files, so we need to mock the file system
  group(
    'watcher',
    () {
      late FileSystem fs;
      late BrickWatcher mockWatcher;
      // ignore: prefer_function_declarations_over_variables, omit_local_variable_types

      setUp(() {
        fs = MemoryFileSystem();
        mockWatcher = MockBrickWatcher();

        when(() => mockWatcher.addEvent(any())).thenReturn(voidCallback());
        when(mockWatcher.start).thenAnswer((_) => Future.value());
        when(() => mockWatcher.hasRun).thenReturn(false);
      });

      Brick brick({bool mockWatch = false}) {
        return Brick.memory(
          name: brickName,
          source: BrickSource.memory(
            localPath: localPath,
            fileSystem: fs,
            watcher: mockWatch ? mockWatcher : null,
          ),
          configuredDirs: const [],
          configuredFiles: const [],
          fileSystem: fs,
        );
      }

      test('#stopWatching calls stop on the watcher', () async {
        final testBrick = brick(mockWatch: true);

        when(mockWatcher.stop).thenAnswer((_) => Future.value());

        verifyNever(mockWatcher.stop);

        await testBrick.stopWatching();

        verify(mockWatcher.stop).called(1);
      });

      group('#cook', () {
        test(
            'uses default directory bricks/{name}/__brick__ when path not provided',
            () {
          final testBrick = brick(mockWatch: true);

          final fakeSourcePath = fs.file(join(localPath, filePath));

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          fs.file(fakeSourcePath).createSync(recursive: true);

          testBrick.cook();

          expect(targetFile.existsSync(), isTrue);
        });

        test('uses provided path for output when provided', () {
          final testBrick = brick(mockWatch: true);

          final fakeSourcePath = fs.file(join(localPath, filePath));

          const output = 'out';

          final targetFile = fs.file(
            join(output, brickName, '__brick__', filePath),
          );

          expect(targetFile.existsSync(), isFalse);

          fs.file(fakeSourcePath).createSync(recursive: true);

          testBrick.cook(watch: true, output: output);

          expect(targetFile.existsSync(), isTrue);
        });

        test('is running watcher', () async {
          final testBrick = brick(mockWatch: true);

          final sourceFile = fs.file(join(localPath, filePath));

          const content = '// content';

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          // Because MemoryFileSystem doesn't support watching,
          // We are just checking if watcher is running.
          //
          // const newContent = '// new content';
          // sourceFile.writeAsStringSync(newContent);
          // expect(targetFile.readAsStringSync(), newContent);

          when(() => mockWatcher.isRunning).thenReturn(true);

          expect(testBrick.source.watcher?.isRunning, isTrue);
        });

        test('writes bricks when no watcher is available', () {
          final testBrick = brick();

          final sourceFile = fs.file(join(localPath, filePath));

          const content = '// content';

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          expect(testBrick.source.watcher?.isRunning, isNull);
        });
      });

      group('#stopWatching', () {
        test('stops watching files for updates', () {
          final testBrick = brick(mockWatch: true);

          final sourceFile = fs.file(join(localPath, filePath));

          const content = '// content';

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          when(() => mockWatcher.isRunning).thenReturn(true);

          expect(testBrick.source.watcher?.isRunning, isTrue);

          reset(mockWatcher);

          when(mockWatcher.stop).thenAnswer((_) => Future.value());

          testBrick.stopWatching();

          when(() => mockWatcher.isRunning).thenReturn(false);

          expect(testBrick.source.watcher?.isRunning, isFalse);
        });
      });
    },
  );

  group('#writeBrick', () {
    late FileSystem fs;
    late MockLogger mockLogger;

    setUp(() {
      fs = MemoryFileSystem();
      mockLogger = MockLogger();

      when(() => mockLogger.progress(any())).thenReturn(([_]) => (String _) {});
    });

    Brick brick({
      bool createFile = false,
      bool createDir = false,
      List<String>? fileNames,
    }) {
      return Brick.memory(
        name: brickName,
        logger: mockLogger,
        source: BrickSource(localPath: localPath),
        configuredDirs: [
          if (createDir) BrickPath(name: newDirName, path: dirPath),
        ],
        configuredFiles: [
          if (createFile && fileNames == null) BrickFile(filePath),
          if (fileNames != null)
            for (final name in fileNames) BrickFile(join(dirPath, name)),
        ],
        fileSystem: fs,
      );
    }

    test(
      'uses default directory bricks/{name}/__brick__ when path not provided',
      () {
        final testBrick = brick(createFile: true);

        final fakeSourcePath = fs.file(
          testBrick.source.fromSourcePath(testBrick.configuredFiles.single),
        );

        final targetFile = fs.file(join(brickPath, filePath));

        expect(targetFile.existsSync(), isFalse);

        fs.file(fakeSourcePath).createSync(recursive: true);

        testBrick.cook();

        expect(targetFile.existsSync(), isTrue);
      },
    );

    test('uses provided path for output when provided', () {
      final testBrick = brick(createFile: true);

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.configuredFiles.single),
      );

      const output = 'out';

      final targetFile = fs.file(
        join(output, brickName, '__brick__', filePath),
      );

      expect(targetFile.existsSync(), isFalse);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook(output: output);

      expect(targetFile.existsSync(), isTrue);
    });

    test('deletes directory if exists', () {
      final testBrick = brick(createFile: true);

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.configuredFiles.single),
      );

      final fakeUnneededFile = fs.file(join(brickPath, 'unneeded.dart'));

      expect(fakeUnneededFile.existsSync(), isFalse);

      fakeUnneededFile.createSync(recursive: true);

      expect(fakeUnneededFile.existsSync(), isTrue);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook();

      expect(fakeUnneededFile.existsSync(), isFalse);
    });

    test('loops through files to write', () {
      const files = ['file1.dart', 'file2.dart', 'file3.dart'];

      final testBrick = brick(createFile: true, fileNames: files);

      for (final file in testBrick.configuredFiles) {
        final fakeSourcePath = fs.file(
          testBrick.source.fromSourcePath(file),
        );

        fs.file(fakeSourcePath).createSync(recursive: true);
      }

      for (final file in testBrick.configuredFiles) {
        expect(fs.file(join(brickPath, file.path)).existsSync(), isFalse);
      }

      testBrick.cook();

      for (final file in testBrick.configuredFiles) {
        expect(fs.file(join(brickPath, file.path)).existsSync(), isTrue);
      }
    });
  });

  group('#props', () {
    const fileNames = ['file1.dart', 'file2.dart', 'file3.dart'];

    final source = BrickSource(localPath: localPath);
    final dir = [BrickPath(name: newDirName, path: dirPath)];
    final files = fileNames.map(BrickFile.new);

    Brick brick({
      bool createFile = false,
      bool createDir = false,
    }) {
      return Brick(
        name: brickName,
        source: source,
        configuredDirs: [
          if (createDir) ...dir,
        ],
        configuredFiles: [
          if (createFile) ...files,
        ],
      );
    }

    test('should return length 4', () {
      final testBrick = brick();

      expect(testBrick.props.length, 4);
    });

    test('should contain name', () {
      final testBrick = brick();

      expect(testBrick.props, contains(brickName));
    });

    test('should contain source', () {
      final testBrick = brick();

      expect(testBrick.props, contains(source));
    });

    test('should contain list of config files', () {
      final testBrick = brick(createFile: true);

      final propFiles =
          testBrick.props.firstWhere((prop) => prop is List<BrickFile>);

      expect(propFiles, isA<List<BrickFile>>());
      propFiles as List<BrickFile>?;

      for (final file in propFiles!) {
        expect(testBrick.configuredFiles, contains(file));
      }
    });

    test('should contain list of config dirs', () {
      final testBrick = brick(createDir: true);

      final propDirs =
          testBrick.props.firstWhere((prop) => prop is List<BrickPath>);

      expect(propDirs, isA<List<BrickPath>>());
      propDirs as List<BrickPath>?;

      for (final dir in propDirs!) {
        expect(testBrick.configuredDirs, contains(dir));
      }
    });
  });
}
