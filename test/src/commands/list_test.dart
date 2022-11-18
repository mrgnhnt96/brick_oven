import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/src/commands/list.dart';
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
    });

    test('accepts alias ls', () {
      expect(
        listCommand.aliases,
        ['ls'],
      );
    });

    test('displays name correctly', () {
      expect(
        listCommand.name,
        'list',
      );
    });

    group('#isVerbose', () {
      test('returns true when verbose is provided', () {
        final command =
            TestListCommand(analytics: mockAnalytics, verbose: true);

        expect(command.isVerbose, true);
      });

      test('returns false when verbose is not provided', () {
        final command = TestListCommand(analytics: mockAnalytics);

        expect(command.isVerbose, isFalse);
      });

      test('returns false when verbose is provided false', () {
        final command =
            TestListCommand(analytics: mockAnalytics, verbose: false);

        expect(command.isVerbose, false);
      });
    });

    test('prints error when configuration is bad and exits with 78', () async {
      final command = TestListCommand(
        analytics: mockAnalytics,
        logger: mockLogger,
      )..brickOrErrorResponse = const BrickOrError(null, 'bad config');

      verifyNever(() => mockLogger.err(any()));

      final code = await command.run();

      expect(code, 78);
      verify(() => mockLogger.err('bad config')).called(1);
    });

    group('brick_oven list', () {
      ListCommand listCommand({required bool verbose}) {
        return TestListCommand(
          analytics: mockAnalytics,
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          verbose: verbose,
        )..brickOrErrorResponse = BrickOrError(
            {
              Brick.memory(
                name: 'package_1',
                source: BrickSource.fromString('example/lib'),
                fileSystem: MemoryFileSystem(),
                logger: mockLogger,
                dirs: [
                  BrickDir(
                    path: 'lib/nested',
                    name: const Name('nested'),
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
              Brick.memory(
                name: 'package_2',
                source: BrickSource.fromString('example/lib'),
                fileSystem: MemoryFileSystem(),
                logger: mockLogger,
                dirs: [
                  BrickDir(
                    path: 'lib/nested',
                    name: const Name('nested'),
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
            () => mockAnalytics.waitForLastPing(
              timeout: any(named: 'timeout'),
            ),
          ).called(1);

          expect(result, ExitCode.success.code);
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
          () => mockAnalytics.waitForLastPing(
            timeout: any(named: 'timeout'),
          ),
        ).called(1);

        expect(result, ExitCode.success.code);
      });
    });
  });
}

class TestListCommand extends ListCommand {
  TestListCommand({
    this.verbose,
    FileSystem? fileSystem,
    Logger? logger,
    required Analytics analytics,
  }) : super(
          logger: logger ?? MockLogger(),
          fileSystem: fileSystem ?? MemoryFileSystem(),
          analytics: analytics,
        );

  final bool? verbose;

  @override
  BrickOrError bricks() {
    return brickOrErrorResponse ?? super.bricks();
  }

  BrickOrError? brickOrErrorResponse;

  @override
  ArgResults get argResults => FakeArgResults(
        data: <String, dynamic>{
          if (verbose != null) 'verbose': verbose,
        },
      );
}
