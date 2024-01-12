// ignore_for_file: unnecessary_cast

import 'dart:async';

import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_url.dart';
import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/constants.dart';
import '../test_utils/di.dart';
import '../test_utils/fakes.dart';
import '../test_utils/mocks.dart';
import '../test_utils/print_override.dart';
import '../test_utils/test_directory_watcher.dart';

void main() {
  setUp(setupTestDi);

  const brickName = 'super_awesome';
  const localPath = 'localPath';
  final brickPath = join('bricks', brickName, '__brick__');
  const dirName = 'director_of_shield';
  final dirPath = join('path', 'to', dirName);
  const excludeDir = 'exclude_me';
  const fileName = 'nick_fury.dart';
  final filePath = join(dirPath, fileName);
  const partialName = 'partial.dart';
  final partialPath = join(dirPath, partialName);

  group('#fromYaml', () {
    test('parses when provided', () {
      final yaml = loadYaml('''
source: oven
brick_config: brick.yaml
dirs:
  path:
    name:
  path/to:
    name:
      value: to
      section: device
    include_if: ios
  path/to/dir:
    include_if_not: ios
    name:
      value: dir
      invert_section: device
files:
  file.md:
    name:
  my/file.md:
    include_if: ios
    name:
      value: file
      section: device
  my/other/file.md:
    include_if_not: ios
    name:
      value: other
      invert_section: device
    vars:
      _VAR1_: var1
partials:
  some/partial.dart:
  some/other/partial.dart:
    vars:
      _ONE_: one
exclude:
  - exclude/all/of/me
urls:
  add/this/url:
  add/this/url/too: other_url
  and/also/this/url:
    name:
      value: my_url
      section: device
  and/also/this/url/too:
    name:
      value: me_too
      invert_section: device
''');

      final result = Brick.fromYaml(
        YamlValue.from(yaml),
        'YOLO',
      );

      final brick = Brick(
        name: 'YOLO',
        brickYamlConfig: const BrickYamlConfig(
          ignoreVars: [],
          path: './brick.yaml',
        ),
        source: BrickSource(
          localPath: 'oven',
        ),
        dirs: [
          BrickDir(
            path: 'path',
            name: Name('path'),
          ),
          BrickDir(
            path: 'path/to',
            name: Name('to', section: 'device'),
            includeIf: 'ios',
          ),
          BrickDir(
            path: 'path/to/dir',
            name: Name('dir', invertedSection: 'device'),
            includeIfNot: 'ios',
          ),
        ],
        files: [
          BrickFile(
            'file.md',
            name: Name('file'),
          ),
          BrickFile.config(
            'my/file.md',
            name: Name('file', section: 'device'),
            includeIf: 'ios',
          ),
          BrickFile.config(
            'my/other/file.md',
            name: Name('other', invertedSection: 'device'),
            includeIfNot: 'ios',
            variables: const [
              Variable(
                name: 'var1',
                placeholder: '_VAR1_',
              ),
            ],
          ),
        ],
        partials: const [
          Partial(path: 'some/partial.dart'),
          Partial(
            path: 'some/other/partial.dart',
            variables: [
              Variable(
                name: 'one',
                placeholder: '_ONE_',
              ),
            ],
          ),
        ],
        exclude: const ['exclude/all/of/me'],
        urls: [
          BrickUrl(
            'add/this/url',
          ),
          BrickUrl(
            'add/this/url/too',
            name: Name('other_url'),
          ),
          BrickUrl(
            'and/also/this/url',
            name: Name('my_url', section: 'device'),
          ),
          BrickUrl(
            'and/also/this/url/too',
            name: Name('me_too', invertedSection: 'device'),
          ),
        ],
      );

      expect(result, brick);

      verifyNoMoreInteractions(di<Logger>());
    });

    group('throws $BrickException', () {
      test('when yaml is error', () {
        expect(
          () => Brick.fromYaml(
            const YamlValue.error('error'),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when yaml is not map', () {
        expect(
          () => Brick.fromYaml(
            const YamlValue.string('Jar Jar Binks'),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when source is incorrect type', () {
        final yaml = loadYaml('''
source: ${1}
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when extra keys are provided', () {
        final yaml = loadYaml('''
vars:
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when dirs is not a map', () {
        final yaml = loadYaml('''
dirs:
  $dirPath
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when files is not a map', () {
        final yaml = loadYaml('''
files:
  $filePath
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<FileException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when partials is not a map', () {
        final yaml = loadYaml('''
partials:
  $partialPath
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when urls is not map', () {
        final yaml = loadYaml('''
urls: url/path
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      group('brick config', () {
        test('runs gracefully when brick config is null', () {
          final yaml = loadYaml('''
brick_config:
''');

          expect(
            () => Brick.fromYaml(
              YamlValue.from(yaml),
              brickName,
            ),
            returnsNormally,
          );

          verifyNoMoreInteractions(di<Logger>());
        });

        test('returns provided brick config', () {
          final yaml = loadYaml('''
brick_config: brick.yaml
''');

          expect(
            Brick.fromYaml(
              YamlValue.from(yaml),
              brickName,
            ).brickYamlConfig,
            const BrickYamlConfig(
              path: './brick.yaml',
              ignoreVars: [],
            ),
          );

          verifyNoMoreInteractions(di<Logger>());
        });
      });
    });

    test('#defaultVariables has correct values', () {
      const expected = [
        Variable(name: '.', placeholder: kIndexValue),
      ];

      expect(Brick.defaultVariables, expected);
    });

    group('exclude', () {
      test('when type is not a list or string', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  path: $excludeDir
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('parses list', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  - $excludeDir
''');

        expect(
          Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          Brick(
            exclude: const [excludeDir],
            name: brickName,
            source: BrickSource(
              localPath: localPath,
            ),
          ),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('parses string', () {
        final yaml = loadYaml('''
source: $localPath
exclude: $excludeDir
''');

        expect(
          Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          Brick(
            exclude: const [excludeDir],
            name: brickName,
            source: BrickSource(
              localPath: localPath,
            ),
          ),
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('throws $BrickException non strings are provided', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  - some/path
  - ${123}
  - ${true}
  - ${<String, dynamic>{}}
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(di<Logger>());
      });
    });
  });

  // Watcher only listens to local files, so we need to mock the file system
  group(
    'watcher',
    () {
      late SourceWatcher mockWatcher;
      late TestDirectoryWatcher testDirectoryWatcher;
      late Progress mockProgress;

      setUp(() {
        mockWatcher = MockSourceWatcher();
        testDirectoryWatcher = TestDirectoryWatcher();

        when(() => mockWatcher.addEvent(any())).thenReturn(voidCallback());
        when(() => mockWatcher.start(any())).thenAnswer((_) => Future.value());
        when(() => mockWatcher.hasRun).thenReturn(false);

        mockProgress = MockProgress();

        when(() => mockProgress.complete(any())).thenReturn(voidCallback());
        when(() => mockProgress.fail(any())).thenReturn(voidCallback());
        when(() => mockProgress.update(any())).thenReturn(voidCallback());

        when(() => di<Logger>().progress(any())).thenReturn(mockProgress);
        when(() => di<Logger>().success(any())).thenReturn(null);
      });

      tearDown(() {
        testDirectoryWatcher.close();
      });

      group('#cook', () {
        test(
            'uses default directory bricks/{name}/__brick__ when path not provided',
            () {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              watcher: mockWatcher,
            ),
          );

          final fakeSourcePath =
              di<FileSystem>().file(join(localPath, filePath));

          final targetFile = di<FileSystem>().file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          di<FileSystem>().file(fakeSourcePath).createSync(recursive: true);

          testBrick.cook();

          expect(targetFile.existsSync(), isTrue);

          verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(di<Logger>());
          verifyNoMoreInteractions(mockWatcher);
        });

        test('uses provided path for output when provided', () {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              watcher: mockWatcher,
            ),
          );

          final fakeSourcePath =
              di<FileSystem>().file(join(localPath, filePath));

          const output = 'out';

          final targetFile = di<FileSystem>().file(
            join(output, brickName, '__brick__', filePath),
          );

          expect(targetFile.existsSync(), isFalse);

          di<FileSystem>().file(fakeSourcePath).createSync(recursive: true);

          testBrick.cook(watch: true, output: output);

          expect(targetFile.existsSync(), isTrue);

          verify(() => mockWatcher.addEvent(any())).called(2);

          verify(() => mockWatcher.start(any())).called(1);
          verify(() => mockWatcher.hasRun).called(1);

          verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(di<Logger>());
          verifyNoMoreInteractions(mockWatcher);
        });

        test('file gets updated on modify event', () async {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              watcher: SourceWatcher.config(
                dirPath: localPath,
                watcher: testDirectoryWatcher,
              ),
            ),
          );

          final sourceFile = di<FileSystem>().file(join(localPath, filePath));

          const content = '// content';

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final targetFile = di<FileSystem>().file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          const newContent = '// new content';
          sourceFile.writeAsStringSync(newContent);

          final event = WatchEvent(ChangeType.MODIFY, sourceFile.path);
          testDirectoryWatcher.triggerEvent(event);

          expect(targetFile.readAsStringSync(), newContent);
          expect(testBrick.source.watcher?.isRunning, isTrue);

          verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(di<Logger>());
        });

        test('file gets added on create event', () async {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              watcher: SourceWatcher.config(
                dirPath: localPath,
                watcher: testDirectoryWatcher,
              ),
            ),
          );

          final sourceFile = di<FileSystem>().file(join(localPath, filePath));

          const content = '// content';

          final targetFile = di<FileSystem>().file(join(brickPath, filePath));

          expect(sourceFile.existsSync(), isFalse);
          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final event = WatchEvent(ChangeType.ADD, sourceFile.path);
          testDirectoryWatcher.triggerEvent(event);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          expect(testBrick.source.watcher?.isRunning, isTrue);
          verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(di<Logger>());
        });

        test('file gets delete on delete event', () async {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              watcher: SourceWatcher.config(
                dirPath: localPath,
                watcher: testDirectoryWatcher,
              ),
            ),
          );

          final sourceFile = di<FileSystem>().file(join(localPath, filePath));

          const content = '// content';

          final targetFile = di<FileSystem>().file(join(brickPath, filePath));

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          expect(sourceFile.existsSync(), isTrue);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          sourceFile.deleteSync();

          final event = WatchEvent(ChangeType.REMOVE, sourceFile.path);
          testDirectoryWatcher.triggerEvent(event);

          expect(targetFile.existsSync(), isFalse);

          expect(testBrick.source.watcher?.isRunning, isTrue);

          verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(di<Logger>());
        });

        test('writes bricks when no watcher is available', () {
          const testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
            ),
          );

          final sourceFile = di<FileSystem>().file(join(localPath, filePath));

          const content = '// content';

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final targetFile = di<FileSystem>().file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          expect(testBrick.source.watcher?.isRunning, isNull);

          verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(di<Logger>());
        });

        test('prints warning if excess variables exist', () {
          verifyNever(() => di<Logger>().warn(any()));

          di<FileSystem>()
              .file(join('path', 'file1.dart'))
              .createSync(recursive: true);

          di<FileSystem>()
              .file(join('path', 'file2.dart'))
              .createSync(recursive: true);

          di<FileSystem>().file('partial').createSync(recursive: true);

          final brick = Brick(
            name: 'BRICK',
            source: BrickSource(
              localPath: '.',
            ),
            partials: const [
              Partial(
                path: 'partial',
                variables: [Variable(name: 'partialVar')],
              ),
            ],
            dirs: [
              BrickDir(
                path: 'path',
                includeIf: 'dirIncludeIf',
                name: Name('dirName', section: 'dirSection'),
              ),
              BrickDir(
                path: 'path',
                includeIfNot: 'dirIncludeIfNot',
                name: Name('dirName', invertedSection: 'dirInvertedSection'),
              ),
            ],
            files: [
              BrickFile.config(
                join('path', 'file1.dart'),
                includeIf: 'fileIncludeIf',
                name: Name('fileName1', section: 'fileSection'),
                variables: const [Variable(name: 'fileVar1')],
              ),
              BrickFile.config(
                join('path', 'file2.dart'),
                name: Name('fileName2', invertedSection: 'fileInvertedSection'),
                includeIfNot: 'fileIncludeIfNot',
                variables: const [Variable(name: 'fileVar2')],
              ),
            ],
          );

          // ignore: cascade_invocations
          brick.cook();

          const vars = '"fileVar1", "fileVar2", "partialVar"';

          verify(
            () => di<Logger>()
                .warn('Unused variables ("fileVar1") in `./path/file1.dart`'),
          ).called(1);
          verify(
            () => di<Logger>()
                .warn('Unused variables ("fileVar2") in `./path/file2.dart`'),
          ).called(1);
          verify(
            () => di<Logger>()
                .warn('Unused variables ("partialVar") in `./partial`'),
          ).called(1);
          verify(() => di<Logger>().warn('Unused variables ($vars) in BRICK'))
              .called(1);
          verify(() => di<Logger>().progress('Writing Brick: BRICK')).called(1);

          verify(
            () => di<Logger>().warn('Unused partials ("partial") in BRICK'),
          ).called(1);

          verifyNoMoreInteractions(di<Logger>());
        });

        test('does not print warning if excess variables do not exist', () {
          verifyNever(() => di<Logger>().warn(any()));

          di<FileSystem>().file(join('path', 'file1.dart'))
            ..createSync(recursive: true)
            ..writeAsStringSync('fileVar1');

          di<FileSystem>().file(join('path', 'to', 'file2.dart'))
            ..createSync(recursive: true)
            ..writeAsStringSync('fileVar2\npartials.partial');

          di<FileSystem>().file('partial')
            ..createSync(recursive: true)
            ..writeAsStringSync('partialVar');

          final brick = Brick(
            name: 'BRICK',
            source: BrickSource(
              localPath: '.',
            ),
            partials: const [
              Partial(
                path: 'partial',
                variables: [Variable(name: 'partialVar')],
              ),
            ],
            dirs: [
              BrickDir(
                path: 'path',
                includeIf: 'dirIncludeIf',
                name: Name('dirName', section: 'dirSection'),
              ),
              BrickDir(
                path: join('path', 'to'),
                includeIfNot: 'dirIncludeIfNot',
                name: Name('dirName', invertedSection: 'dirInvertedSection'),
              ),
            ],
            files: [
              BrickFile.config(
                join('path', 'file1.dart'),
                includeIf: 'fileIncludeIf',
                name: Name('fileName1', section: 'fileSection'),
                variables: const [Variable(name: 'fileVar1')],
              ),
              BrickFile.config(
                join('path', 'to', 'file2.dart'),
                name: Name('fileName2', invertedSection: 'fileInvertedSection'),
                includeIfNot: 'fileIncludeIfNot',
                variables: const [Variable(name: 'fileVar2')],
              ),
            ],
          );

          // ignore: cascade_invocations
          brick.cook();

          verify(() => di<Logger>().progress('Writing Brick: BRICK')).called(1);

          verifyNoMoreInteractions(di<Logger>());
        });
      });

      test('stops watching files for updates', () async {
        final testBrick = Brick(
          name: brickName,
          source: BrickSource.memory(
            localPath: localPath,
            watcher: SourceWatcher.config(
              dirPath: localPath,
              watcher: testDirectoryWatcher,
            ),
          ),
        );

        final sourceFile = di<FileSystem>().file(join(localPath, filePath));

        const content = '// content';

        sourceFile
          ..createSync(recursive: true)
          ..writeAsStringSync(content);

        final targetFile = di<FileSystem>().file(join(brickPath, filePath));

        expect(targetFile.existsSync(), isFalse);

        testBrick.cook(watch: true);

        expect(targetFile.existsSync(), isTrue);
        expect(targetFile.readAsStringSync(), content);

        expect(testBrick.source.watcher?.isRunning, isTrue);

        await testBrick.source.watcher?.stop();

        expect(testBrick.source.watcher?.isRunning, isFalse);

        verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
            .called(1);

        verifyNoMoreInteractions(di<Logger>());
      });
    },
  );

  group('#cook', () {
    late Progress mockProgress;

    setUp(() {
      mockProgress = MockProgress();

      when(() => mockProgress.complete(any())).thenReturn(voidCallback());
      when(() => mockProgress.fail(any())).thenReturn(voidCallback());
      when(() => mockProgress.update(any())).thenReturn(voidCallback());

      when(() => di<Logger>().progress(any())).thenReturn(mockProgress);
      when(() => di<Logger>().success(any())).thenReturn(null);

      registerFallbackValue(MockLogger());
      registerFallbackValue(MockFile());
      registerFallbackValue(MemoryFileSystem());
    });

    test('throws $BrickException when duplicate partials exist', () {
      final brick = Brick(
        name: 'Brick',
        source: const BrickSource.none(),
        partials: [
          Partial(
            path: join(localPath, filePath),
          ),
          Partial(
            path: join(localPath, 'to', filePath),
          ),
        ],
      );

      expect(
        brick.cook,
        throwsA(
          isA<BrickException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate partials ("$fileName") in Brick'),
          ),
        ),
      );

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
    });

    test('throws $BrickException when partial #writeFile throws', () {
      final mockPartial = MockBrickPartial();

      when(() => mockPartial.fileName).thenReturn(fileName);
      when(() => mockPartial.path).thenReturn(filePath);

      when(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).thenThrow(
        const PartialException(partial: 'this one', reason: 'for no reason'),
      );

      final brick = Brick(
        name: 'Brick',
        source: const BrickSource.none(),
        partials: [mockPartial],
      );

      expect(
        brick.cook,
        throwsA(isA<BrickException>()),
      );

      verify(
        () => mockProgress.fail(
          '(Brick) Failed to write partial: $filePath',
        ),
      ).called(1);
      verify(() => di<Logger>().progress('Writing Brick: Brick')).called(1);

      verify(() => mockPartial.path).called(3);
      verify(() => mockPartial.fileName).called(2);

      verify(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPartial);
    });

    test('throws $Exception when partial #writeFile throws', () {
      final mockPartial = MockBrickPartial();

      when(() => mockPartial.fileName).thenReturn(fileName);
      when(() => mockPartial.path).thenReturn(filePath);

      when(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).thenThrow(
        Exception('error'),
      );

      final brick = Brick(
        name: 'Brick',
        source: const BrickSource.none(),
        partials: [mockPartial],
      );

      expect(
        brick.cook,
        throwsA(isA<Exception>()),
      );

      verify(
        () => mockProgress.fail(
          '(Brick) Failed to write partial: $filePath',
        ),
      ).called(1);
      verify(() => di<Logger>().progress('Writing Brick: Brick')).called(1);
      verify(() => mockPartial.path).called(3);
      verify(() => mockPartial.fileName).called(2);

      verify(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPartial);
    });

    test('throws $BrickException when file #writefile throws', () {
      final mockFile = MockBrickFile();
      final mockSource = MockBrickSource();

      when(
        () => mockSource.mergeFilesAndConfig(
          any(),
          excludedPaths: any(named: 'excludedPaths'),
        ),
      ).thenReturn([mockFile]);

      when(
        () => mockSource.fromSourcePath(any()),
      ).thenReturn('');

      when(mockFile.formatName).thenReturn(fileName);
      when(() => mockFile.path).thenReturn(filePath);
      when(() => mockFile.variables).thenReturn([]);

      when(
        () => mockFile.writeTargetFile(
          urls: any(named: 'urls'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).thenThrow(
        const FileException(file: 'this one', reason: 'for no reason'),
      );

      final brick = Brick(
        name: 'Brick',
        source: mockSource,
        files: [mockFile],
      );

      expect(
        brick.cook,
        throwsA(isA<BrickException>()),
      );

      verify(() => mockProgress.fail('(Brick) Failed to write file: $filePath'))
          .called(1);
      verify(() => di<Logger>().progress('Writing Brick: Brick')).called(1);
      verify(() => mockFile.path).called(3);
      verify(
        () => mockFile.writeTargetFile(
          urls: any(named: 'urls'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).called(1);

      verify(() => mockSource.watcher).called(1);
      verify(
        () => mockSource.mergeFilesAndConfig(
          [mockFile],
          excludedPaths: any(named: 'excludedPaths'),
        ),
      ).called(1);
      verify(
        () => mockSource.fromSourcePath(filePath),
      ).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockFile);
      verifyNoMoreInteractions(mockSource);
    });

    test('throws $Exception when file #writefile throws', () {
      final mockFile = MockBrickFile();
      final mockSource = MockBrickSource();

      when(
        () => mockSource.mergeFilesAndConfig(
          any(),
          excludedPaths: any(named: 'excludedPaths'),
        ),
      ).thenReturn([mockFile]);

      when(
        () => mockSource.fromSourcePath(any()),
      ).thenReturn('');

      when(mockFile.formatName).thenReturn(fileName);
      when(() => mockFile.path).thenReturn(filePath);
      when(() => mockFile.variables).thenReturn([]);

      when(
        () => mockFile.writeTargetFile(
          urls: any(named: 'urls'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).thenThrow(
        Exception('error'),
      );

      final brick = Brick(
        name: 'Brick',
        source: mockSource,
        files: [mockFile],
      );

      expect(
        brick.cook,
        throwsA(isA<Exception>()),
      );

      verify(() => mockProgress.fail('(Brick) Failed to write file: $filePath'))
          .called(1);
      verify(() => di<Logger>().progress('Writing Brick: Brick')).called(1);
      verify(() => mockFile.path).called(3);
      verify(
        () => mockFile.writeTargetFile(
          urls: any(named: 'urls'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).called(1);

      verify(() => mockSource.watcher).called(1);
      verify(
        () => mockSource.mergeFilesAndConfig(
          [mockFile],
          excludedPaths: any(named: 'excludedPaths'),
        ),
      ).called(1);
      verify(
        () => mockSource.fromSourcePath(filePath),
      ).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockFile);
      verifyNoMoreInteractions(mockSource);
    });

    test(
        'uses default directory bricks/{name}/__brick__ when path not provided',
        () {
      final testBrick = Brick(
        name: brickName,
        source: const BrickSource.memory(
          localPath: localPath,
        ),
        files: [BrickFile(filePath)],
      );

      final fakeSourcePath = di<FileSystem>().file(
        testBrick.source.fromSourcePath(testBrick.files.single.path),
      );

      final targetFile = di<FileSystem>().file(join(brickPath, filePath));

      expect(targetFile.existsSync(), isFalse);

      di<FileSystem>().file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook();

      expect(targetFile.existsSync(), isTrue);

      verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
          .called(1);
      verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
          .called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
    });

    test('uses provided path for output when provided', () {
      final testBrick = Brick(
        name: brickName,
        source: const BrickSource.memory(
          localPath: localPath,
        ),
        files: [BrickFile(filePath)],
      );

      final fakeSourcePath = di<FileSystem>().file(
        testBrick.source.fromSourcePath(testBrick.files.single.path),
      );

      const output = 'out';

      final targetFile = di<FileSystem>().file(
        join(output, brickName, '__brick__', filePath),
      );

      expect(targetFile.existsSync(), isFalse);

      di<FileSystem>().file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook(output: output);

      expect(targetFile.existsSync(), isTrue);

      verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
          .called(1);
      verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
          .called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
    });

    test('deletes directory if exists', () {
      final testBrick = Brick(
        name: brickName,
        source: const BrickSource.memory(
          localPath: localPath,
        ),
        files: [BrickFile(filePath)],
      );

      final fakeSourcePath = di<FileSystem>().file(
        testBrick.source.fromSourcePath(testBrick.files.single.path),
      );

      final fakeUnneededFile =
          di<FileSystem>().file(join(brickPath, 'unneeded.dart'));

      expect(fakeUnneededFile.existsSync(), isFalse);

      fakeUnneededFile.createSync(recursive: true);

      expect(fakeUnneededFile.existsSync(), isTrue);

      di<FileSystem>().file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook();

      expect(fakeUnneededFile.existsSync(), isFalse);

      verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
          .called(1);
      verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
          .called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
    });

    test('loops through files to write', () {
      const files = ['file1.dart', 'file2.dart', 'file3.dart'];

      for (final file in files) {
        final fakeSourcePath = di<FileSystem>().file(join(localPath, file));

        di<FileSystem>().file(fakeSourcePath).createSync(recursive: true);
      }

      final testBrick = Brick(
        name: brickName,
        source: const BrickSource.memory(
          localPath: localPath,
        ),
        files: [for (final file in files) BrickFile(file)],
      );

      for (final file in testBrick.files) {
        expect(
          di<FileSystem>().file(join(brickPath, file.path)).existsSync(),
          isFalse,
        );
      }

      testBrick.cook();

      for (final file in testBrick.files) {
        expect(
          di<FileSystem>().file(join(brickPath, file.path)).existsSync(),
          isTrue,
        );
      }

      verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
          .called(1);

      verify(() => mockProgress.complete('super_awesome: cooked 3 files'))
          .called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
    });

    test('loops through partials to write', () {
      const files = ['file1.dart', 'path/file2.dart', 'path/to/file3.dart'];

      for (final file in files) {
        final fakeSourcePath = di<FileSystem>().file(join(localPath, file));

        di<FileSystem>().file(fakeSourcePath).createSync(recursive: true);
      }

      final testBrick = Brick(
        name: brickName,
        source: const BrickSource.memory(
          localPath: localPath,
        ),
        partials: [for (final file in files) Partial(path: file)],
      );

      for (final partial in testBrick.partials) {
        expect(
          di<FileSystem>()
              .file(join(brickPath, partial.toPartialFile()))
              .existsSync(),
          isFalse,
        );
      }

      testBrick.cook();

      for (final partial in testBrick.partials) {
        expect(
          di<FileSystem>()
              .file(join(brickPath, partial.toPartialFile()))
              .existsSync(),
          isTrue,
        );

        expect(
          di<FileSystem>().file(join(brickPath, partial.path)).existsSync(),
          isFalse,
        );
      }

      verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
          .called(1);
      verify(
        () => di<Logger>().warn(
          'Unused partials ("file1.dart", "file2.dart", "file3.dart") in super_awesome',
        ),
      ).called(1);

      verify(() => mockProgress.complete('super_awesome: cooked 3 files'))
          .called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
    });

    group('#defaultVariables write', () {
      test('files', () {
        const filePath = 'file1.dart';
        const file = BrickFile.config(
          filePath,
          variables: [Variable(name: 'name', placeholder: '_VAL_')],
        );

        di<FileSystem>().file(join(localPath, filePath))
          ..createSync(recursive: true)
          ..writeAsStringSync('_VAL_ $kIndexValue');

        final targetFile = di<FileSystem>().file(join(brickPath, file.path));

        const Brick(
          name: brickName,
          source: BrickSource.memory(
            localPath: localPath,
          ),
          files: [file],
        ).cook();

        const expected = '{{name}} {{.}}';

        expect(targetFile.readAsStringSync(), expected);

        verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
            .called(1);

        verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
            .called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(mockProgress);
      });

      test('partials', () {
        const file = 'file1.dart';
        const partial = Partial(path: file);

        di<FileSystem>().file(join(localPath, file))
          ..createSync(recursive: true)
          ..writeAsStringSync(kIndexValue);

        final targetFile =
            di<FileSystem>().file(join(brickPath, partial.toPartialFile()));

        const Brick(
          name: brickName,
          source: BrickSource.memory(
            localPath: localPath,
          ),
          partials: [partial],
        ).cook();

        const expected = '{{.}}';

        expect(targetFile.readAsStringSync(), expected);

        verify(() => di<Logger>().progress('Writing Brick: super_awesome'))
            .called(1);
        verify(
          () => di<Logger>()
              .warn('Unused partials ("file1.dart") in super_awesome'),
        ).called(1);

        verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
            .called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(mockProgress);
      });
    });
  });

  group('#allBrickVariables', () {
    test('ignores dot annotation', () {
      const brick = Brick(
        name: '',
        source: BrickSource.none(),
        files: [
          BrickFile.config(
            '',
            variables: [
              Variable(name: 'var1.sup'),
              Variable(name: 'var1.yo'),
              Variable(name: 'var1.hi'),
            ],
          ),
        ],
      );

      expect(brick.allBrickVariables(), {'var1'});

      verifyNoMoreInteractions(di<Logger>());
    });

    group('files', () {
      test('gets #variables from files', () {
        const brick = Brick(
          name: '',
          source: BrickSource.none(),
          files: [
            BrickFile.config(
              '',
              variables: [
                Variable(name: 'var1'),
                Variable(name: 'var2'),
                Variable(name: 'var3'),
              ],
            ),
            BrickFile.config(
              '',
              variables: [
                Variable(name: 'var4'),
                Variable(name: 'var5'),
                Variable(name: 'var6'),
              ],
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
            'var3',
            'var4',
            'var5',
            'var6',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('gets #variables from partials', () {
        const brick = Brick(
          name: '',
          source: BrickSource.none(),
          partials: [
            Partial(
              path: '',
              variables: [
                Variable(name: 'var1'),
                Variable(name: 'var2'),
                Variable(name: 'var3'),
              ],
            ),
            Partial(
              path: '',
              variables: [
                Variable(name: 'var4'),
                Variable(name: 'var5'),
                Variable(name: 'var6'),
              ],
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
            'var3',
            'var4',
            'var5',
            'var6',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('gets #includeIf', () {
        const brick = Brick(
          name: '',
          source: BrickSource.none(),
          files: [
            BrickFile.config(
              '',
              includeIf: 'var1',
            ),
            BrickFile.config(
              '',
              includeIf: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('gets #includeIfNot', () {
        const brick = Brick(
          name: '',
          source: BrickSource.none(),
          files: [
            BrickFile.config(
              '',
              includeIfNot: 'var1',
            ),
            BrickFile.config(
              '',
              includeIfNot: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('gets #name', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          files: [
            BrickFile.config(
              '',
              name: Name('var1', section: 'section'),
            ),
            BrickFile.config(
              '',
              name: Name('var2', invertedSection: 'invertedSection'),
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
            'section',
            'invertedSection',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });
    });

    group('dirs', () {
      test('gets #names', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          dirs: [
            BrickDir(name: Name('name1', section: 'section'), path: ''),
            BrickDir(
              name: Name('name2', invertedSection: 'invertedSection'),
              path: '',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'name1',
            'name2',
            'section',
            'invertedSection',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('gets #includeIf', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          dirs: [
            BrickDir(
              path: '',
              includeIf: 'var1',
            ),
            BrickDir(
              path: '',
              includeIf: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('gets #includeIfNot', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          dirs: [
            BrickDir(
              path: '',
              includeIfNot: 'var1',
            ),
            BrickDir(
              path: '',
              includeIfNot: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );
      });
    });

    group('urls', () {
      test('gets #names', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          urls: [
            BrickUrl('path', name: Name('name1', section: 'section')),
            BrickUrl(
              'path/to',
              name: Name('name2', invertedSection: 'invertedSection'),
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'name1',
            'name2',
            'section',
            'invertedSection',
          },
        );

        verifyNoMoreInteractions(di<Logger>());
      });
    });
  });

  group('#checkBrickYamlConfig', () {
    late BrickYamlConfig mockBrickYamlConfig;

    setUp(() {
      printLogs = [];

      mockBrickYamlConfig = MockBrickYamlConfig();
    });

    test('returns when shouldSync is false', () {
      const Brick(
        name: '',
        source: BrickSource.none(),
      ).checkBrickYamlConfig(shouldSync: false);

      expect(printLogs, isEmpty);
    });

    test('returns when brickYamlConfig is null', () {
      const Brick(
        name: '',
        source: BrickSource.none(),
      ).checkBrickYamlConfig(shouldSync: true);

      expect(printLogs, isEmpty);
    });

    test('warns when data returns null in reading brick.yaml file', () {
      when(() => mockBrickYamlConfig.data).thenReturn(null);
      verifyNever(() => di<Logger>().warn(any()));

      Brick(
        name: '',
        source: const BrickSource.none(),
        brickYamlConfig: mockBrickYamlConfig,
      ).checkBrickYamlConfig(shouldSync: true);
    });

    test('warns when names are not in sync', () {
      when(() => mockBrickYamlConfig.data)
          .thenReturn(const BrickYamlData(name: 'Master Skywalker', vars: []));

      when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

      verifyNever(() => di<Logger>().warn(any()));

      Brick(
        name: 'Master Yoda',
        source: const BrickSource.none(),
        brickYamlConfig: mockBrickYamlConfig,
      ).checkBrickYamlConfig(shouldSync: true);

      verify(
        () => di<Logger>().warn(
          '`name` (Master Skywalker) in brick.yaml does not '
          'match the name in brick_oven.yaml (Master Yoda)',
        ),
      ).called(1);

      verify(() => di<Logger>().err('brick.yaml is out of sync')).called(1);
    });

    test('alerts when brick.yaml is in sync', () {
      when(() => mockBrickYamlConfig.data)
          .thenReturn(const BrickYamlData(name: 'Count Dooku', vars: []));

      when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

      verifyNever(() => di<Logger>().info(any()));

      Brick(
        name: 'Count Dooku',
        source: const BrickSource.none(),
        brickYamlConfig: mockBrickYamlConfig,
      ).checkBrickYamlConfig(shouldSync: true);

      verifyNever(() => di<Logger>().warn(any()));
      verifyNever(() => di<Logger>().err(any()));
      verify(() => di<Logger>().info(darkGray.wrap('brick.yaml is in sync')))
          .called(1);
    });

    test('ignores extra default variables', () {
      when(() => mockBrickYamlConfig.data)
          .thenReturn(const BrickYamlData(name: 'Count Dooku', vars: []));

      when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

      verifyNever(() => di<Logger>().info(any()));

      Brick(
        name: 'Count Dooku',
        source: const BrickSource.none(),
        files: [
          BrickFile.config(
            '',
            variables: [
              ...Brick.defaultVariables,
              const Variable(name: '_INDEX_VALUE_'),
              const Variable(name: '.'),
            ],
          ),
        ],
        brickYamlConfig: mockBrickYamlConfig,
      ).checkBrickYamlConfig(shouldSync: true);

      verifyNever(() => di<Logger>().warn(any()));
      verifyNever(() => di<Logger>().err(any()));
      verify(() => di<Logger>().info(darkGray.wrap('brick.yaml is in sync')))
          .called(1);
    });

    test('ignores $BrickYamlConfig.ignoreVars from sync', () {
      when(() => mockBrickYamlConfig.data)
          .thenReturn(const BrickYamlData(name: 'Count Dooku', vars: []));
      when(() => mockBrickYamlConfig.ignoreVars).thenReturn(['favorite_color']);

      verifyNever(() => di<Logger>().info(any()));

      Brick(
        name: 'Count Dooku',
        source: const BrickSource.none(),
        files: const [
          BrickFile.config(
            '',
            variables: [
              Variable(name: 'favorite_color', placeholder: '_FAVORITE_COLOR_'),
            ],
          ),
        ],
        brickYamlConfig: mockBrickYamlConfig,
      ).checkBrickYamlConfig(shouldSync: true);

      verifyNever(() => di<Logger>().warn(any()));
      verifyNever(() => di<Logger>().err(any()));
      verify(() => di<Logger>().info(darkGray.wrap('brick.yaml is in sync')))
          .called(1);
    });

    group('alerts when brick.yaml is in out of sync', () {
      test('when brick.yaml contains extra variables', () {
        when(() => mockBrickYamlConfig.data).thenReturn(
          const BrickYamlData(
            name: 'Count Dooku',
            vars: ['var1', 'var2'],
          ),
        );

        when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

        verifyNever(() => di<Logger>().warn(any()));
        verifyNever(() => di<Logger>().err(any()));

        Brick(
          name: 'Count Dooku',
          source: const BrickSource.none(),
          brickYamlConfig: mockBrickYamlConfig,
        ).checkBrickYamlConfig(shouldSync: true);

        verify(
          () => di<Logger>().warn(
            darkGray.wrap(
              'Variables ("var1", "var2") exist in brick.yaml but not in brick_oven.yaml',
            ),
          ),
        ).called(1);

        verify(
          () => di<Logger>().err('brick.yaml is out of sync'),
        ).called(1);
      });

      test('when brick_oven.yaml contains extra variables', () {
        when(() => mockBrickYamlConfig.data).thenReturn(
          const BrickYamlData(
            name: 'Count Dooku',
            vars: [],
          ),
        );

        when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

        verifyNever(() => di<Logger>().warn(any()));
        verifyNever(() => di<Logger>().err(any()));

        Brick(
          name: 'Count Dooku',
          source: const BrickSource.none(),
          brickYamlConfig: mockBrickYamlConfig,
          dirs: [
            BrickDir(
              name: Name('var1'),
              includeIf: 'var2',
              path: '',
            ),
          ],
        ).checkBrickYamlConfig(shouldSync: true);

        verify(
          () => di<Logger>().warn(
            darkGray.wrap(
              'Variables ("var1", "var2") exist in brick_oven.yaml but not in brick.yaml',
            ),
          ),
        ).called(1);

        verify(
          () => di<Logger>().err('brick.yaml is out of sync'),
        ).called(1);
      });
    });
  });
}
