// ignore_for_file: cascade_invocations

import 'package:brick_oven/utils/extensions/datetime_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('DateTimeX', () {
    test('#formatted', () {
      final dateTime = DateTime(2021, 1, 1, 12);
      expect(dateTime.formatted, '12:00:00 PM');

      final dateTime2 = DateTime(2021, 1, 1, 1, 1, 1);
      expect(dateTime2.formatted, '1:01:01 AM');
    });
  });
}
