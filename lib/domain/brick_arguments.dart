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
    var watch = false;
    if (arguments.contains('--watch') || arguments.contains('-w')) {
      watch = true;
    }
    return BrickArguments(
      watch: watch,
    );
  }

  /// Whether to watch the directory and update on changes
  final bool watch;
}
