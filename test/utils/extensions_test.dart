import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/utils/extensions.dart';

import '../test_utils/mocks.dart';
import '../test_utils/print_override.dart';

void main() {
  late Logger logger;
  late Logger mockLogger;

  setUp(() {
    printLogs = [];
    logger = Logger();
    mockLogger = MockLogger();
  });

  group('LoggerX', () {
    group('#preheat', () {
      test('prints', () {
        overridePrint(() {
          logger.preheat();

          expect(printLogs, [('\n🔥  Preheating...')]);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.preheat();

        verify(() => mockLogger.info(cyan.wrap('\n🔥  Preheating...')))
            .called(1);
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

          expect(printLogs, ['\n📁  File changed ${darkGray.wrap('(brick)')}']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.fileChanged('brick');

        verify(
          () =>
              mockLogger.info('\n📁  File changed ${darkGray.wrap('(brick)')}'),
        ).called(1);
      });
    });

    group('#watching', () {
      test('prints', () {
        overridePrint(() {
          logger.watching();

          expect(printLogs, ['\n👀 Watching config & source files...']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.watching();

        verify(
          () => mockLogger
              .info(lightYellow.wrap('\n👀 Watching config & source files...')),
        ).called(1);
      });
    });

    group('#dingDing', () {
      test('prints', () {
        overridePrint(() {
          final date = DateTime(2021, 1, 1, 12);
          logger.dingDing(date);

          final cooked = lightGreen.wrap('🔔  Ding Ding! (');
          final timed = darkGray.wrap(date.formatted);
          final end = lightGreen.wrap(')');

          final expected = '$cooked$timed$end\n';

          expect(printLogs, [expected]);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        final date = DateTime(2021, 1, 1, 12);
        mockLogger.dingDing(date);

        final cooked = lightGreen.wrap('🔔  Ding Ding! (');
        final timed = darkGray.wrap(date.formatted);
        final end = lightGreen.wrap(')');

        final expected = '$cooked$timed$end';

        verify(
          () => mockLogger.info(expected),
        ).called(1);
      });
    });

    group('#keyStrokes', () {
      test('prints', () {
        overridePrint(() {
          logger.keyStrokes();

          expect(printLogs, ['Press q to quit...', 'Press r to reload...']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.keyStrokes();

        verify(
          () => mockLogger.info(darkGray.wrap('Press q to quit...')),
        ).called(1);

        verify(
          () => mockLogger.info(darkGray.wrap('Press r to reload...')),
        ).called(1);
      });
    });
  });
}
