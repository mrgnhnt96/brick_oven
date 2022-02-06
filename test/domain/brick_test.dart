// ignore_for_file: unnecessary_cast

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';
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

  group('#writeBrick', () {
    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    Brick brick({
      bool createFile = false,
      bool createDir = false,
      List<String>? fileNames,
    }) {
      return Brick.memory(
        name: brickName,
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

    test('should not create the bricks folder when no files are provided', () {
      brick().writeBrick();
    });

    test('checks for directory bricks/{name}/__brick__', () {
      final testBrick = brick(createFile: true);

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.configuredFiles.single),
      );

      final targetFile = fs.file(join(brickPath, filePath));

      expect(targetFile.existsSync(), isFalse);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.writeBrick();

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

      testBrick.writeBrick();

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

      testBrick.writeBrick();

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
