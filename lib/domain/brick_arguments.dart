/// {@template brick_arguments}
/// The arguments to be provided to the brick_oven package
/// {@endtemplate}
class BrickArguments {
  /// {@macro brick_arguments}
  const BrickArguments({
    this.watch = false,
  });

  /// parses the arguments from the command line
  factory BrickArguments.from(List<String> arguments) {
    final args = List<String>.from(arguments);

    final watch = args.containsArg('--watch', '-w');

    if (args.isNotEmpty) {
      throw ArgumentError('unrecognized args, $args');
    }

    return BrickArguments(
      watch: watch,
    );
  }

  /// Whether to watch the directory and update on changes
  final bool watch;
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
}
