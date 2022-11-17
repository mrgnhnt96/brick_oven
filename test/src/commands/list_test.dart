import 'package:args/args.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/list.dart';
import 'package:brick_oven/src/runner.dart';
import '../../test_utils/fakes.dart';
import '../../test_utils/mocks.dart';
import '../../test_utils/print_override.dart';

void main() {
  group('$ListCommand', () {
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
    });

    test('displays description correctly', () {
      expect(
        ListCommand(
          logger: mockLogger,
          analytics: MockAnalytics(),
          fileSystem: MemoryFileSystem(),
        ).description,
        'Lists all configured bricks from ${BrickOvenYaml.file}',
      );
    });

    test('accepts alias ls', () {
      expect(
        ListCommand(
          logger: mockLogger,
          analytics: MockAnalytics(),
          fileSystem: MemoryFileSystem(),
        ).aliases,
        ['ls'],
      );
    });

    test('displays name correctly', () {
      expect(
        ListCommand(
          logger: mockLogger,
          analytics: MockAnalytics(),
          fileSystem: MemoryFileSystem(),
        ).name,
        'list',
      );
    });

    group('#isVerbose', () {
      test('returns true when verbose is provided', () {
        final command = TestListCommand(logger: mockLogger, verbose: true);

        expect(command.isVerbose, true);
      });

      test('returns false when verbose is not provided', () {
        final command = TestListCommand(logger: mockLogger);

        expect(command.isVerbose, isFalse);
      });

      test('returns false when verbose is provided false', () {
        final command = TestListCommand(logger: mockLogger, verbose: false);

        expect(command.isVerbose, false);
      });
    });
  });

  test('prints error when configuration is bad and exits with 78', () async {
    final logger = MockLogger();
    final fileSystem = MemoryFileSystem();
    final command = TestListCommand(
      logger: logger,
      fileSystem: fileSystem,
    )..brickOrErrorResponse = const BrickOrError(null, 'bad config');

    verifyNever(() => logger.err(any()));

    final code = await command.run();

    expect(code, 78);
    verify(() => logger.err('bad config')).called(1);
  });

  group('brick_oven list', () {
    late FileSystem fs;
    late File brickConfigFile;
    late BrickOvenRunner runner;
    late MockLogger mockLogger;

    void writeConfig([String? content]) {
      final contents = content ??
          '''
bricks:
  package_1:
    source: example/lib
    dirs:
      lib/nested:
        name:
    files:
      readme.md:
        vars:
          some_var: some_value
    partials:
      header.md:
  package_2:
    source: example/lib
    dirs:
      lib/nested:
        name:
    files:
      readme.md:
        vars:
          some_var: some_value
    partials:
      header.md:
''';

      brickConfigFile.writeAsStringSync(contents);
    }

    setUp(() {
      printLogs = [];
      fs = MemoryFileSystem();
      mockLogger = MockLogger();

      brickConfigFile = fs.file(BrickOvenYaml.file)..create(recursive: true);
      writeConfig();

      runner = BrickOvenRunner(
        fileSystem: fs,
        logger: mockLogger,
        pubUpdater: MockPubUpdater(),
        analytics: MockAnalytics(),
      );
    });

    test(
      'writes config from ${BrickOvenYaml.file}',
      () async {
        final result = await runner.run(['list']);

        expect(result, ExitCode.success.code);

        verify(
          () => mockLogger.info('package_1: example/lib'),
        ).called(1);

        verify(
          () => mockLogger.info('package_2: example/lib'),
        ).called(1);
      },
    );

    test('--verbose writes config from ${BrickOvenYaml.file}', () {
      writeConfig();

      runner.run(['list', '--verbose']);

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
    });
  });
}

class TestListCommand extends ListCommand {
  TestListCommand({
    this.verbose,
    required Logger logger,
    FileSystem? fileSystem,
  }) : super(
          logger: logger,
          fileSystem: fileSystem,
          analytics: MockAnalytics(),
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
