import 'package:brick_oven/utils/extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../src/runner_test.dart';
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

          expect(printLogs, ['\nCooking...']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.cooking();

        verify(() => mockLogger.info(cyan.wrap('\nCooking...'))).called(1);
      });
    });

    group('#watching', () {
      test('prints', () {
        overridePrint(() {
          logger.watching();

          expect(printLogs, ['\nWatching local files...']);
        });
      });

      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.watching();

        verify(
          () => mockLogger.info(lightYellow.wrap('\nWatching local files...')),
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
