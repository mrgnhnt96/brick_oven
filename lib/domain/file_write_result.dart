/// {@template file_write_result}
/// returns the used partials and variables
/// of the written file
/// {@endtemplate}
class FileWriteResult {
  /// {@macro file_write_result}
  const FileWriteResult({
    required this.usedPartials,
    required this.usedVariables,
  });

  /// {@macro file_write_result}
  const FileWriteResult.empty()
      : this(usedPartials: const {}, usedVariables: const {});

  /// the names of the variables used in the file
  final Set<String> usedVariables;

  /// the paths of the partials used in the file
  final Set<String> usedPartials;
}
