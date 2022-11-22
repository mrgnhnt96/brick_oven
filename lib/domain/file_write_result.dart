import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';

part 'file_write_result.g.dart';

/// {@template file_write_result}
/// returns the used partials and variables
/// of the written file
/// {@endtemplate}
@autoequal
class FileWriteResult extends Equatable {
  /// {@macro file_write_result}
  const FileWriteResult({
    required this.usedPartials,
    required this.usedVariables,
  });

  /// {@macro file_write_result}
  const FileWriteResult.empty()
      : usedPartials = const {},
        usedVariables = const {};

  /// the names of the variables used in the file
  final Set<String> usedVariables;

  /// the paths of the partials used in the file
  final Set<String> usedPartials;

  @override
  List<Object?> get props => _$props;
}
