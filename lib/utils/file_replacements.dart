import 'package:brick_oven/domain/brick_partial.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/content_replacement.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/enums/mustache_tags.dart';
import 'package:brick_oven/enums/mustache_sections.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

/// {@template file_replacements}
/// the methods to replace variables and partials in a file
/// {@endtemplate}
mixin FileReplacements {
  /// the placeholder when replacing loops
  @visibleForTesting
  static const loopSetUp = '---set-up-loop---';

  /// writes the [targetFile] content using the [sourceFile]'s content and
  /// replacing the [variables] and [partials] with their configured values
  FileWriteResult writeFile({
    required File targetFile,
    required File sourceFile,
    required List<Variable> variables,
    required List<BrickPartial> partials,
    required FileSystem? fileSystem,
    required Logger logger,
  }) {
    if (variables.isEmpty && partials.isEmpty) {
      sourceFile.copySync(targetFile.path);

      return const FileWriteResult.empty();
    }

    /// used to check if variable/partials is goes unused
    final usedVariables = <String>{};
    final usedPartials = <String>{};

    if (!sourceFile.existsSync()) {
      logger.warn('source file does not exist: ${sourceFile.path}');
      return const FileWriteResult.empty();
    }

    var content = sourceFile.readAsStringSync();

    for (final variable in variables) {
      // formats the content
      final loopResult = checkForLoops(content, variable);
      content = loopResult.content;
      if (loopResult.used.isNotEmpty) {
        usedVariables.addAll(loopResult.used);
      }

      final variableResult = checkForVariables(content, variable);
      content = variableResult.content;
      usedVariables.addAll(variableResult.used);
    }

    final partialsResult =
        checkForPartials(partials: partials, content: content);
    content = partialsResult.content;
    usedPartials.addAll(partialsResult.used);

    final variableNames = variables.map((v) => v.name).toSet();
    final unusedVariables = variableNames.difference(usedVariables);

    if (unusedVariables.isNotEmpty) {
      final vars = '"${unusedVariables.map((e) => e).join('", "')}"';
      logger.warn(
        'Unused variables ($vars) in `${sourceFile.path}`',
      );
    }

    targetFile.writeAsStringSync(content);

    return FileWriteResult(
      usedVariables: usedVariables.toSet(),
      usedPartials: usedPartials.toSet(),
    );
  }

  /// writes the [partials] to the [content]
  @visibleForTesting
  ContentReplacement checkForPartials({
    required String content,
    required Iterable<BrickPartial> partials,
  }) {
    var newContent = content;

    final partialsUsed = <String>{};

    for (final partial in partials) {
      final partialPattern = RegExp(r'.*\bpartial\.' '${partial.name}' r'\b.*');
      final compareContent = newContent;
      newContent =
          newContent.replaceAll(partialPattern, partial.toPartialInput());

      if (compareContent != newContent) {
        partialsUsed.add(partial.path);
      }
    }

    return ContentReplacement(content: newContent, used: partialsUsed);
  }

  /// the pattern to find loops (sections) within the content
  @visibleForTesting
  RegExp get loopSetupPattern => RegExp('.*$loopSetUp' r'({{[\^#/]\S+}}).*');

  /// the pattern to find loops within the content
  @visibleForTesting
  RegExp loopPattern(Variable variable) =>
      RegExp(r'(\w+)' '${variable.placeholder}');

  /// checks the [content] for loops (sections) and replaces them with the
  /// [variable]'s value
  @visibleForTesting
  ContentReplacement checkForLoops(String content, Variable variable) {
    var isVariableUsed = false;

    final setUpLoops = content.replaceAllMapped(
      loopPattern(variable),
      (match) {
        final possibleLoop = match.group(1);
        final loop = MustacheSections.values.from(possibleLoop);

        // if loop is found, then replace the content
        if (loop == null) {
          return match.group(0)!;
        }

        isVariableUsed = true;

        final formattedLoop = loop.format(variable.name);

        return '$loopSetUp$formattedLoop';
      },
    );

    // remove the loop setup and all pre/post content
    final looped = setUpLoops.replaceAllMapped(
      loopSetupPattern,
      (match) {
        return match.group(1)!;
      },
    );

    // remove all extra linebreaks before & after the loop
    final _ = looped.replaceAllMapped(
      RegExp(r'(\n*)({{[#^/][\w-]+}})$(\n*)', multiLine: true),
      (match) {
        var before = '';
        var after = '';

        final beforeMatch = match.group(1);
        if (beforeMatch != null && beforeMatch.isNotEmpty) {
          before = '\n';
        }

        final afterMatch = match.group(3);
        if (afterMatch != null && afterMatch.isNotEmpty) {
          after = '\n';
        }

        isVariableUsed = true;
        return '$before${match.group(2)!}$after';
      },
    );

    return ContentReplacement(
      content: looped,
      used: {
        if (isVariableUsed) variable.name,
      },
    );
  }

  /// the pattern to find variables within the content
  @visibleForTesting
  RegExp variablePattern(Variable variable) =>
      RegExp(r'(\{*\S*)' '${variable.placeholder}' r'(\w*\}*)');

  /// replaces the [variable] in the [content]
  @visibleForTesting
  ContentReplacement checkForVariables(
    String content,
    Variable variable,
  ) {
    var isVariableUsed = false;

    final newContent = content.replaceAllMapped(
      variablePattern(variable),
      (match) {
        final completeMatch = match.group(0)!;

        final startsWithBracket =
            RegExp(r'^\{+(?![/^#])$').hasMatch(match.group(1)!);
        final isTag = RegExp(r'^\{+[/^#]').hasMatch(match.group(1)!);
        final endsWithBracket = RegExp(r'\}+$').hasMatch(match.group(2)!);

        if (isTag && endsWithBracket) {
          return completeMatch;
        }

        if (startsWithBracket || endsWithBracket) {
          throw VariableException(
            variable: completeMatch,
            reason: 'Please remove curly braces from variable '
                '`$completeMatch` '
                'This will cause unexpected behavior '
                'when creating the brick',
          );
        }

        String result;
        var suffix = '';
        final prefixResult = checkForVariables(match.group(1)!, variable);
        final prefix = prefixResult.content;
        if (prefixResult.used.isNotEmpty) {
          isVariableUsed = true;
        }

        final possibleFormat = match.group(2);

        final format = MustacheTags.values.findFrom(possibleFormat);

        if (format == null) {
          if (possibleFormat != null) {
            suffix = possibleFormat;
          }

          result = '{{${variable.name}}}';
        } else {
          // format the variable
          suffix = MustacheTags.values.suffixFrom(possibleFormat) ?? '';
          result = format.wrap(variable.name);
        }

        isVariableUsed = true;

        return '$prefix$result$suffix';
      },
    );

    return ContentReplacement(
      content: newContent,
      used: {
        if (isVariableUsed) variable.name,
      },
    );
  }
}
