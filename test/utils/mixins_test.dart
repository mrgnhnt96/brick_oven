import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/mixins.dart';
import 'package:file/file.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'fakes.dart';
import 'mocks.dart';
import 'print_override.dart';
import 'testing_env.dart';

void main() {
  setUp(() {
    printLogs = [];
  });

  group('$QuitAfterMixin', () {
    test('update should start at 0', () {
      final quitAfterMixin = TestQuitAfterMixin();

      expect(quitAfterMixin.updates, 0);
    });

    group('#fileChanged', () {
      test('increments #update by 1', () {
        final quitAfterMixin = TestQuitAfterMixin()..fileChanged();

        expect(quitAfterMixin.updates, 1);
      });

      test('throws $MaxUpdateException when #update increments to #quitAfter',
          () {
        final quitAfterMixin = TestQuitAfterMixin(quitAfterX: 2)..fileChanged();

        expect(quitAfterMixin.fileChanged, throwsA(isA<MaxUpdateException>()));
      });

      test('should log quitting after X updates on quit', () {
        overridePrint(() {
          final quitAfterMixin = TestQuitAfterMixin(quitAfterX: 2)
            ..fileChanged();

          expect(
            quitAfterMixin.fileChanged,
            throwsA(isA<MaxUpdateException>()),
          );

          expect(printLogs, [
            'Quitting after 2 updates.',
          ]);
        });
      });
    });

    group('#quitAfter', () {
      test('should return number when provided', () {
        final quitAfterMixin = TestQuitAfterMixin(quitAfterX: 2);

        expect(quitAfterMixin.quitAfter, 2);
      });

      test('should return null when is not provided', () {
        final quitAfterMixin = TestQuitAfterMixin();

        expect(quitAfterMixin.quitAfter, isNull);
      });
    });

    group('#shouldQuit', () {
      test('should return false when quit after is not provided', () {
        final quitAfterMixin = TestQuitAfterMixin();

        expect(quitAfterMixin.shouldQuit, isFalse);
      });

      test(
        'should return false when quit after is provided and not greater updates',
        () {
          final quitAfterMixin = TestQuitAfterMixin(quitAfterX: 2)
            ..fileChanged();

          expect(quitAfterMixin.shouldQuit, isFalse);
        },
      );

      test(
        'should return true when quit after is provided and greater updates',
        () {
          final quitAfterMixin = TestQuitAfterMixin(quitAfterX: 2)
            ..fileChanged();

          final mockLogger = MockLogger();

          when(() => mockLogger.info(any())).thenReturn(voidCallback());

          verifyNever(() => mockLogger.info(any()));

          expect(
            () => quitAfterMixin.fileChanged(logger: mockLogger),
            throwsA(isA<MaxUpdateException>()),
          );

          verify(() => mockLogger.info('Quitting after 2 updates')).called(1);

          expect(quitAfterMixin.shouldQuit, isTrue);
        },
      );
    });
  });

  group('$ConfigWatcherMixin', () {
    late FileSystem fs;
    late File configFile;

    setUp(() async {
      fs = setUpTestingEnvironment();

      final configPath = join(fs.currentDirectory.path, BrickOvenYaml.file);

      configFile = fs.file(configPath);

      await configFile.create(recursive: true);
    });

    tearDown(() {
      tearDownTestingEnvironment(fs);
    });

    test('#watchForChanges should return true when file changes', () async {
      var hasChanged = false;
      final testConfigWatcher = TestConfigWatcher();

      final listener = testConfigWatcher.watchForConfigChanges(
        configFile.path,
        onChange: () => hasChanged = true,
      );

      configFile.writeAsStringSync('update');

      await listener;

      expect(hasChanged, isTrue);
    });

    test('#cancelWatchers can be called', () async {
      final testConfigWatcher = TestConfigWatcher();

      expect(testConfigWatcher.cancelWatchers, returnsNormally);
    });
  });
}

class TestQuitAfterMixin extends Command<int> with QuitAfterMixin {
  TestQuitAfterMixin({this.quitAfterX});

  final int? quitAfterX;

  @override
  String get description => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  @override
  ArgResults get argResults => FakeArgResults(
        data: <String, dynamic>{
          if (quitAfterX != null) ...<String, dynamic>{
            'quit-after': '$quitAfterX'
          }
        },
      );
}

class TestConfigWatcher with ConfigWatcherMixin {}
