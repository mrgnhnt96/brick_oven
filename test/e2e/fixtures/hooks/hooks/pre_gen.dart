import 'dart:io';

import 'package:mason/mason.dart';

void run(HookContext context) {
  final file = File('.pre_gen.txt');
  file.writeAsStringSync('pre_gen: ${context.vars['name']}');
}
