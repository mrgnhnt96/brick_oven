import 'package:args/args.dart';
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
    test('displays description correctly', () {
      expect(
        ListCommand().description,
        'Lists all configured bricks from ${BrickOvenYaml.file}.',
      );
    });

    test('displays name correctly', () {
      expect(ListCommand().name, 'list');
    });

    group('#isVerbose', () {
      test('returns true when verbose is provided', () {
        final command = TestListCommand(verbose: true);

        expect(command.isVerbose, true);
      });

      test('returns false when verbose is not provided', () {
        final command = TestListCommand();

        expect(command.isVerbose, isFalse);
      });

      test('returns false when verbose is provided false', () {
        final command = TestListCommand(verbose: false);

        expect(command.isVerbose, false);
      });
    });
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
  package_2:
    source: example/lib
    dirs:
      lib/nested:
        name:
    files:
      readme.md:
        vars:
          some_var: some_value
''';

      brickConfigFile.writeAsStringSync(contents);
    }

    setUp(() {
      printLogs = [];
      fs = MemoryFileSystem();
      mockLogger = MockLogger();

      brickConfigFile = fs.file(BrickOvenYaml.file)..create(recursive: true);
      writeConfig();

      runner = BrickOvenRunner(fileSystem: fs, logger: mockLogger);
    });

    test(
      'writes config from ${BrickOvenYaml.file}',
      () async {
        final result = await runner.run(['list']);

        expect(result, ExitCode.success.code);

        verify(() => mockLogger.info('\nBricks in the oven:')).called(1);
        verify(
          () => mockLogger.info(
            '''
${lightYellow.wrap('package_1')}
  source: example/lib
  ${cyan.wrap('files')}: 1
  ${cyan.wrap('dirs')}: 1
''',
          ),
        ).called(1);

        verify(
          () => mockLogger.info(
            '''
${lightYellow.wrap('package_2')}
  source: example/lib
  ${cyan.wrap('files')}: 1
  ${cyan.wrap('dirs')}: 1
''',
          ),
        ).called(1);
      },
    );

    test('--verbose writes config from ${BrickOvenYaml.file}', () {
      writeConfig();

      runner.run(['list', '--verbose']);

      verify(() => mockLogger.info('\nBricks in the oven:')).called(1);
      verify(
        () => mockLogger.info(
          '''
${lightYellow.wrap('package_1')}
  source: example/lib
  ${cyan.wrap('files')}:
    - ${darkGray.wrap('/')}readme.md
      ${cyan.wrap('vars')}:
        - some_value ${green.wrap('->')} {some_var}
  ${cyan.wrap('dirs')}:
    - ${darkGray.wrap('lib/')}nested ${green.wrap('->')} {nested}
''',
        ),
      ).called(1);

      verify(
        () => mockLogger.info(
          '''
${lightYellow.wrap('package_2')}
  source: example/lib
  ${cyan.wrap('files')}:
    - ${darkGray.wrap('/')}readme.md
      ${cyan.wrap('vars')}:
        - some_value ${green.wrap('->')} {some_var}
  ${cyan.wrap('dirs')}:
    - ${darkGray.wrap('lib/')}nested ${green.wrap('->')} {nested}
''',
        ),
      ).called(1);
    });
  });
}

class TestListCommand extends ListCommand {
  TestListCommand({this.verbose});

  final bool? verbose;

  @override
  ArgResults get argResults => FakeArgResults(
        data: <String, dynamic>{
          if (verbose != null) 'verbose': verbose,
        },
      );
}
