import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/bricks_or_error.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/src/commands/list.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import '../../test_utils/fakes.dart';
import '../../test_utils/mocks.dart';
import '../../test_utils/print_override.dart';

void main() {
  group('$ListCommand', () {
    late Logger mockLogger;
    late Analytics mockAnalytics;
    late ListCommand listCommand;

    setUp(() {
      mockLogger = MockLogger();
      mockAnalytics = MockAnalytics()..stubMethods();

      listCommand = ListCommand(
        logger: mockLogger,
        analytics: mockAnalytics,
        fileSystem: MemoryFileSystem(),
      );
    });

    test('displays description correctly', () {
      expect(
        listCommand.description,
        'Lists all configured bricks from ${BrickOvenYaml.file}',
      );

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
    });

    test('accepts alias ls', () {
      expect(
        listCommand.aliases,
        ['ls'],
      );

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
    });

    test('displays name correctly', () {
      expect(
        listCommand.name,
        'list',
      );

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
    });

    group('#isVerbose', () {
      test('returns true when verbose is provided', () {
        final command = TestListCommand(
          analytics: mockAnalytics,
          logger: mockLogger,
          verbose: true,
        );

        expect(command.isVerbose, true);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });

      test('returns false when verbose is not provided', () {
        final command =
            TestListCommand(analytics: mockAnalytics, logger: mockLogger);

        expect(command.isVerbose, isFalse);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });

      test('returns false when verbose is provided false', () {
        final command = TestListCommand(
          analytics: mockAnalytics,
          logger: mockLogger,
          verbose: false,
        );

        expect(command.isVerbose, false);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });
    });

    test('prints error when configuration is bad and exits with 78', () async {
      final command = TestListCommand(
        analytics: mockAnalytics,
        logger: mockLogger,
      )..brickOrErrorResponse = const BricksOrError(null, 'bad config');

      verifyNever(() => mockLogger.err(any()));

      final code = await command.run();

      expect(code, 78);
      verify(() => mockLogger.err('bad config')).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
    });

    group('brick_oven list', () {
      ListCommand listCommand({required bool verbose}) {
        return TestListCommand(
          analytics: mockAnalytics,
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          verbose: verbose,
        )..brickOrErrorResponse = BricksOrError(
            {
              Brick(
                name: 'package_1',
                source: BrickSource.fromString(
                  'example/lib',
                  fileSystem: MemoryFileSystem(),
                ),
                fileSystem: MemoryFileSystem(),
                logger: mockLogger,
                dirs: [
                  BrickDir(
                    path: 'lib/nested',
                    name: Name('nested'),
                  ),
                ],
                files: const [
                  BrickFile.config(
                    'readme.md',
                    variables: [
                      Variable(
                        name: 'some_var',
                        placeholder: 'some_value',
                      ),
                    ],
                  ),
                ],
                partials: const [Partial(path: 'header.md')],
              ),
              Brick(
                name: 'package_2',
                source: BrickSource.fromString(
                  'example/lib',
                  fileSystem: MemoryFileSystem(),
                ),
                fileSystem: MemoryFileSystem(),
                logger: mockLogger,
                dirs: [
                  BrickDir(
                    path: 'lib/nested',
                    name: Name('nested'),
                  ),
                ],
                files: const [
                  BrickFile.config(
                    'readme.md',
                    variables: [
                      Variable(
                        name: 'some_var',
                        placeholder: 'some_value',
                      ),
                    ],
                  ),
                ],
                partials: const [Partial(path: 'header.md')],
              )
            },
            null,
          );
      }

      setUp(() {
        printLogs = [];
      });

      test(
        'writes config from ${BrickOvenYaml.file}',
        () async {
          final result = await listCommand(verbose: false).run();

          verify(
            () => mockLogger.info('package_1: example/lib'),
          ).called(1);

          verify(
            () => mockLogger.info('package_2: example/lib'),
          ).called(1);

          verify(
            () => mockAnalytics.sendEvent(
              'list',
              'simple',
              value: 0,
              parameters: {
                'bricks': '2',
              },
            ),
          ).called(1);

          verify(
            () =>
                mockAnalytics.waitForLastPing(timeout: BrickOvenRunner.timeout),
          ).called(1);

          expect(result, ExitCode.success.code);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockAnalytics);
        },
      );

      test('--verbose writes config from ${BrickOvenYaml.file}', () async {
        final result = await listCommand(verbose: true).run();

        verify(
          () => mockLogger.info('package_1: example/lib'),
        ).called(1);

        verify(
          () => mockLogger.info('package_2: example/lib'),
        ).called(1);

        verify(
          () => mockLogger
              .info('  (configured) dirs: 1, files: 1, partials: 1, vars: 2'),
        ).called(2);

        verify(
          () => mockAnalytics.sendEvent(
            'list',
            'verbose',
            value: 0,
            parameters: {
              'bricks': '2',
            },
          ),
        ).called(1);

        verify(
          () => mockAnalytics.waitForLastPing(timeout: BrickOvenRunner.timeout),
        ).called(1);

        expect(result, ExitCode.success.code);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });
    });
  });
}

class TestListCommand extends ListCommand {
  TestListCommand({
    this.verbose,
    FileSystem? fileSystem,
    required Logger logger,
    required Analytics analytics,
  }) : super(
          logger: logger,
          fileSystem: fileSystem ?? MemoryFileSystem(),
          analytics: analytics,
        );

  final bool? verbose;

  @override
  BricksOrError bricks() {
    return brickOrErrorResponse ?? super.bricks();
  }

  BricksOrError? brickOrErrorResponse;

  @override
  ArgResults get argResults => FakeArgResults(
        data: <String, dynamic>{
          if (verbose != null) 'verbose': verbose,
        },
      );
}
