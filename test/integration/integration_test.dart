// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'util/cook_brick.dart';

void main() {
  group('cook single brick runs gracefully', () {
    test('bio', () => cookBrick('bio'));
  });
}
