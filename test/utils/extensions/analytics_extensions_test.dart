// ignore_for_file: cascade_invocations

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import 'package:brick_oven/utils/extensions/analytics_extensions.dart';
import '../../test_utils/mocks.dart';

void main() {
  late Logger mockLogger;
  late Analytics mockAnalytics;

  const consentMessage = '''
+---------------------------------------------------+
|           Welcome to the Brick Oven!              |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Opt-in to help us improve? 🥺 [y/n]               |
+---------------------------------------------------+\n''';

  setUp(() {
    mockLogger = MockLogger();
    mockAnalytics = MockAnalytics();
  });

  group('AnalyticsX', () {
    test('#formatAsk is equal to ask', () {
      expect(AnalyticsX.formatAsk(), AnalyticsX.ask);
    });

    test('#ask is formatted correctly', () {
      expect(AnalyticsX.ask, consentMessage);
    });

    group('#askForConsent', () {
      test('handles accept response', () async {
        when(() => mockAnalytics.firstRun).thenReturn(true);

        when(
          () => mockLogger.chooseOne(
            any<String>(),
            choices: any<List<String>>(named: 'choices'),
            defaultValue: any<String>(named: 'defaultValue'),
          ),
        ).thenReturn(AnalyticsX.yes);

        mockAnalytics.askForConsent(mockLogger);

        verify(() => mockAnalytics.enabled = true).called(1);

        verify(
          () => mockLogger.chooseOne(
            consentMessage,
            choices: [AnalyticsX.yes, AnalyticsX.no],
            defaultValue: AnalyticsX.yes,
          ),
        ).called(1);

        verify(() => mockAnalytics.firstRun).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });

      test('handles reject response', () {
        final mockAnalytics = MockAnalytics();

        when(() => mockAnalytics.firstRun).thenReturn(true);

        when(
          () => mockLogger.chooseOne(
            any<String>(),
            choices: any<List<String>>(named: 'choices'),
            defaultValue: any<String>(named: 'defaultValue'),
          ),
        ).thenReturn(AnalyticsX.no);

        mockAnalytics.askForConsent(mockLogger);

        verify(
          () => mockLogger.chooseOne(
            consentMessage,
            choices: [AnalyticsX.yes, AnalyticsX.no],
            defaultValue: AnalyticsX.yes,
          ),
        ).called(1);

        verify(() => mockAnalytics.firstRun).called(1);

        verify(() => mockAnalytics.enabled = false).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });
    });
  });
}
