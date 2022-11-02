import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/utils/extensions.dart';
import 'mocks.dart';
import 'print_override.dart';

void main() {
  late Logger logger;
  late Logger mockLogger;

  setUp(() {
    printLogs = [];
    logger = Logger();
    mockLogger = MockLogger();
  });

  group('LoggerX', () {
    group('#cooking', () {
      test('prints', () {
        overridePrint(() {
          logger.cooking();

          expect(printLogs, ['\n⏲️  Cooking...']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.cooking();

        verify(() => mockLogger.info(cyan.wrap('\n⏲️  Cooking...'))).called(1);
      });
    });

    group('#configChanged', () {
      test('prints', () {
        overridePrint(() {
          logger.configChanged();

          expect(printLogs, ['\n🔧  Configuration changed']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.configChanged();

        verify(() => mockLogger.info('\n🔧  Configuration changed')).called(1);
      });
    });

    group('#fileChanged', () {
      test('prints', () {
        overridePrint(() {
          logger.fileChanged('brick');

          expect(printLogs, ['\n🔧  File changed ${darkGray.wrap('(brick)')}']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.fileChanged('brick');

        verify(
          () =>
              mockLogger.info('\n🔧  File changed ${darkGray.wrap('(brick)')}'),
        ).called(1);
      });
    });

    group('#watching', () {
      test('prints', () {
        overridePrint(() {
          logger.watching();

          expect(printLogs, ['\n👀 Watching local files...']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.watching();

        verify(
          () =>
              mockLogger.info(lightYellow.wrap('\n👀 Watching local files...')),
        ).called(1);
      });
    });

    group('#cooked', () {
      test('prints', () {
        overridePrint(() {
          final date = DateTime(2021, 1, 1, 12);
          mockLogger.cooked(date);

          final cooked = lightGreen.wrap('\n🍽️  Cooked! (');
          final timed = darkGray.wrap(date.formatted);
          final end = lightGreen.wrap(')');

          final expected = '$cooked$timed$end\n';

          expect(printLogs, [expected]);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        final date = DateTime(2021, 1, 1, 12);
        mockLogger.cooked(date);

        final cooked = lightGreen.wrap('\n🍽️  Cooked! (');
        final timed = darkGray.wrap(date.formatted);
        final end = lightGreen.wrap(')');

        final expected = '$cooked$timed$end\n';

        verify(
          () => mockLogger.info(expected),
        ).called(1);
      });
    });

    group('#qToQuit', () {
      test('prints', () {
        overridePrint(() {
          logger.qToQuit();

          expect(printLogs, ['Press q to quit...']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.qToQuit();

        verify(
          () => mockLogger.info(darkGray.wrap('Press q to quit...')),
        ).called(1);
      });
    });
  });
}
