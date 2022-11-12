import 'package:brick_oven/domain/brick_partial.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/enums/mustache_loops.dart';
import 'package:brick_oven/enums/mustache_sections.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template file_replacements}
/// the methods to replace variables and partials in a file
/// {@endtemplate}
mixin FileReplacements {
  static const _loopSetUp = '---set-up-loop---';

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

    final variablesResult =
        _writeVariables(variables: variables, content: content);
    content = variablesResult.content;

    usedVariables.addAll(variablesResult.used);

    final partialsResult = _writePartials(partials: partials, content: content);
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

  _ReplacementResult _writePartials({
    required String content,
    required Iterable<BrickPartial> partials,
  }) {
    var newContent = content;

    final partialsUsed = <String>{};

    for (final partial in partials) {
      final partialPattern = RegExp('.*partial.${partial.name}.*');
      final compareContent = newContent;
      newContent =
          newContent.replaceAll(partialPattern, partial.toPartialInput());

      if (compareContent != newContent) {
        partialsUsed.add(partial.path);
      }
    }

    return _ReplacementResult(content: newContent, used: partialsUsed);
  }

  _ReplacementResult _writeVariables({
    required List<Variable> variables,
    required String content,
  }) {
    var newContent = content;

    final usedVariables = <String>{};

    for (final variable in variables) {
      // formats the content
      final loopResult = _checkForLoops(newContent, variable);
      newContent = loopResult.content;
      if (loopResult.used.isNotEmpty) {
        usedVariables.addAll(loopResult.used);
      }

      final variableResult = _checkForVariables(newContent, variable);
      newContent = variableResult.content;
      usedVariables.addAll(variableResult.used);
    }

    return _ReplacementResult(
      content: newContent,
      used: usedVariables,
    );
  }

  Pattern _loopPattern() => RegExp('.*$_loopSetUp' r'({{.[\w-+$\.]+}}).*');
  Pattern _variablePattern(Variable variable) =>
      RegExp(r'([\w-{#^/]*)' '${variable.placeholder}' r'([\w}]*)');

  _ReplacementResult _checkForLoops(
    String content,
    Variable variable,
  ) {
    var isVariableUsed = false;

    final setUpLoops =
        content.replaceAllMapped(_variablePattern(variable), (match) {
      final possibleLoop = match.group(1);
      final loop = MustacheLoops.values.from(possibleLoop);

      // if loop is found, then replace the content
      if (loop == null) {
        return match.group(0)!;
      }

      isVariableUsed = true;

      final formattedLoop = loop.format(variable.name);

      return '$_loopSetUp$formattedLoop';
    });

    // remove the loop setup and all pre/post content
    final looped = setUpLoops.replaceAllMapped(_loopPattern(), (match) {
      return match.group(1)!;
    });

    // remove all extra linebreaks before & after the loop
    final clean = looped.replaceAllMapped(
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

    return _ReplacementResult(
      content: clean,
      used: {
        if (isVariableUsed) variable.name,
      },
    );
  }

  _ReplacementResult _checkForVariables(
    String content,
    Variable variable,
  ) {
    var isVariableUsed = false;

    final newContent =
        content.replaceAllMapped(_variablePattern(variable), (match) {
      final possibleSection = match.group(1);
      MustacheSections? section;
      String result;
      var suffix = '';
      var prefix = '';

      // check for section or loop
      if (possibleSection != null && possibleSection.isNotEmpty) {
        section = MustacheSections.values.from(possibleSection);

        if (section == null) {
          if (possibleSection.isNotEmpty) {
            final additionalVariables =
                _checkForVariables(possibleSection, variable);

            if (additionalVariables.used.isNotEmpty) {
              isVariableUsed = true;
            }

            prefix = additionalVariables.content;
          }
        } else {
          prefix = prefix.replaceAll(section.matcher, '');
        }
      }

      if (section == null &&
          possibleSection?.startsWith(RegExp(r'{{[\^#\\]')) == false) {
        final completeMatch = match.group(0);

        if (completeMatch != null && completeMatch.isNotEmpty) {
          if (completeMatch.startsWith('{') || completeMatch.endsWith('}')) {
            throw VariableException(
              variable: completeMatch,
              reason: 'Please remove curly braces from variable '
                  '`$completeMatch` '
                  'This will cause unexpected behavior '
                  'when creating the brick',
            );
          }
        }
      }

      final possibleFormat = match.group(2);

      final format = MustacheFormat.values.getMustacheValue(possibleFormat);

      if (format == null) {
        if (possibleFormat != null && possibleFormat.isNotEmpty) {
          suffix = possibleFormat;
        }

        if (section == null) {
          result = '{{${variable.name}}}';
        } else {
          result = section.format(variable.name);
        }
      } else {
        // format the variable
        suffix = MustacheFormat.values.getSuffix(possibleFormat) ?? '';
        result = variable.formatName(format);
      }

      if (prefix.startsWith(RegExp('{{[#^/]')) || suffix.endsWith('}}')) {
        return match.group(0)!;
      }

      isVariableUsed = true;

      return '$prefix$result$suffix';
    });

    return _ReplacementResult(
      content: newContent,
      used: {
        if (isVariableUsed) variable.name,
      },
    );
  }
}

class _ReplacementResult {
  const _ReplacementResult({
    required this.content,
    required this.used,
  });

  final String content;

  final Set<String> used;
}
