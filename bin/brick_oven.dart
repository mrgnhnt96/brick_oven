import 'dart:io';

import 'package:brick_oven/brick_oven.dart';

void main(List<String> arguments) {
  if (arguments.contains('-h')) {
    stdout.write('You need help...');
    return;
  }

  runBrickOven(BrickArguments.from(arguments));
}
