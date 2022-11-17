// ignore_for_file: cascade_invocations

import 'package:brick_oven/utils/extensions/analytics_extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../test_utils/mocks.dart';

void main() {
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  group('AnalyticsX', () {
    test('#formatAsk is equal to ask', () {
      expect(AnalyticsX.formatAsk(), AnalyticsX.ask);
    });

    test('#ask is formatted correctly', () {
      const expected = '''
+---------------------------------------------------+
|           Welcome to the Brick Oven!              |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Would you like to opt-into help us improve? [y/n] |
+---------------------------------------------------+\n''';

      expect(AnalyticsX.ask, expected);
    });

    group('#askForConsent', () {
      test('handles accept response', () async {
        final mockAnalytics = MockAnalytics();

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

        verify(() => mockAnalytics.enabled = false).called(1);
      });
    });
  });
}
