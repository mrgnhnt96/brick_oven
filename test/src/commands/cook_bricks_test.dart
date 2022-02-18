import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/cook_bricks.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  late FileSystem fs;
  late CookBricksCommand brickOvenCommand;
  late CommandRunner runner;

  setUp(() {
    fs = MemoryFileSystem();
    fs.file(BrickOvenYaml.file)
      ..createSync()
      ..writeAsStringSync(
        '''
bricks:
  first:
    source: path/to/first
  second:
    source: path/to/second
  third:
    source: path/to/third
''',
      );
    brickOvenCommand = CookBricksCommand(fileSystem: fs);
    runner = BrickOvenRunner(fileSystem: fs);
  });

  group('$CookBricksCommand', () {
    test('instanciate without an explicit file system or logger', () {
      expect(CookBricksCommand.new, returnsNormally);
    });

    test('cook all', () {
      expect(
        runner.commands['cook']?.subcommands.keys,
        contains('all'),
      );
    });

    test('cook specific brick', () {
      const subcommands = [
        'first',
        'second',
        'third',
      ];

      expect(
        runner.commands['cook']?.subcommands.keys,
        containsAll(subcommands),
      );
    });

    test('description displays correctly', () {
      expect(
        brickOvenCommand.description,
        'Cook 👨‍🍳 bricks from the config file.',
      );
    });

    test('name is cook', () {
      expect(brickOvenCommand.name, 'cook');
    });
  });
}
