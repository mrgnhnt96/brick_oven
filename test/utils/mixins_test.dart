import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/mixins.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../src/runner_test.dart';
import 'fakes.dart';
import 'print_override.dart';

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
