import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';

part 'content_replacement.g.dart';

/// {@template replacement_result}
/// The result of content replacement
/// {@endtemplate}
@autoequal
class ContentReplacement extends Equatable {
  /// {@macro replacement_result}
  const ContentReplacement({
    required this.content,
    required this.used,
  });

  /// the new content
  final String content;

  /// the variables used in the content
  final Set<String> used;

  @override
  List<Object?> get props => _$props;
}
