import 'dart:io';

import 'package:brick_oven/domain/brick_config.dart';
import 'package:path/path.dart';

/// {@template brick_arguments}
/// The arguments to be provided to the brick_oven package
/// {@endtemplate}
class BrickArguments {
  /// {@macro brick_arguments}
  const BrickArguments({
    this.watch = false,
    this.outputDir = '',
  });

  /// parses the arguments from the command line
  factory BrickArguments.from(List<String> arguments) {
    final args = List<String>.from(arguments);

    if (args.containsArg('--help', '-h')) {
      logger.info('brick_oven: you need help...');
      exit(0);
    }

    final watch = args.containsArg('--watch', '-w');
    final output = args.retrieveArg('--output', '-o');

    if (args.isNotEmpty) {
      throw ArgumentError('unrecognized args, $args');
    }

    return BrickArguments(
      watch: watch,
      outputDir: output,
    );
  }

  /// Whether to watch the directory and update on changes
  final bool watch;

  /// the output directory for the bricks
  final String? outputDir;
}

extension on List<String> {
  bool containsArg(String flag, [String? shortFlag]) {
    final containsFlag = remove(flag);

    if (!containsFlag && shortFlag != null) {
      final containsShortFlag = remove(shortFlag);

      return containsShortFlag;
    }

    return containsFlag;
  }

  String? retrieveArg(String flag, [String? shortFlag]) {
    final flagIndex = indexOf(flag);

    String get(int index) {
      if (index == -1) {
        throw ArgumentError('$flag is not found');
      }

      removeAt(index);
      final result = removeAt(index);

      final path = normalize(result);

      return path;
    }

    if (flagIndex == -1 && shortFlag != null) {
      final shortFlagIndex = indexOf(shortFlag);

      if (shortFlagIndex != -1) {
        return get(shortFlagIndex);
      }
    } else if (flagIndex != -1) {
      return get(flagIndex);
    }

    return null;
  }
}
