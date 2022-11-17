// ignore_for_file: cascade_invocations

import 'package:brick_oven/utils/extensions/datetime_extensions.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../test_utils/mocks.dart';

void main() {
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  group('LoggerX', () {
    group('#preheat', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.preheat();

        verify(() => mockLogger.info('\n🔥  Preheating...')).called(1);
      });
    });

    group('#configChanged', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.configChanged();

        verify(() => mockLogger.info('\n🔧  Configuration changed')).called(1);
      });
    });

    group('#fileChanged', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.fileChanged('brick');

        verify(
          () => mockLogger.info('\n📁  File changed (brick)'),
        ).called(1);
      });
    });

    group('#watching', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.watching();

        verify(
          () => mockLogger.info('\n👀 Watching config & source files...'),
        ).called(1);
      });
    });

    group('#dingDing', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        final date = DateTime(2021, 1, 1, 12);
        mockLogger.dingDing(date);

        verify(
          () => mockLogger.info('🔔  Ding Ding! (${date.formatted})'),
        ).called(1);
      });
    });

    group('#keyStrokes', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.keyStrokes();

        verify(
          () => mockLogger.info('Press q to quit...'),
        ).called(1);

        verify(
          () => mockLogger.info('Press r to reload...'),
        ).called(1);
      });
    });
  });
}
