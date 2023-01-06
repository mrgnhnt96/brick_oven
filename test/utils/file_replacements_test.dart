// ignore_for_file: cascade_invocations

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/content_replacement.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/constants.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import '../test_utils/mocks.dart';

void main() {
  const testFileReplacements = _TestFileReplacements();

  group('#checkForPartials', () {
    test('replaces partial placeholder with partial value', () {
      const content = '''
partials.do_not_replace
{{> partial }}

// partials.replace_me
// partials.replace_me.dart
partials.replace_me_too //
partials.replace_me_too.md //
''';

      const expectedContent = '''
partials.do_not_replace
{{> partial }}

{{> replace_me.dart }}
{{> replace_me.dart }}
{{> replace_me_too.md }}
{{> replace_me_too.md }}
''';

      const partials = [
        Partial(path: 'path/to/replace_me.dart'),
        Partial(path: 'path/to/replace_me_too.md'),
        Partial(path: 'path/to/replace_me_three'),
      ];

      final result = testFileReplacements.checkForPartials(
        content: content,
        partials: partials,
      );

      const expected = ContentReplacement(
        content: expectedContent,
        used: {'path/to/replace_me.dart', 'path/to/replace_me_too.md'},
      );

      expect(result, expected);
    });
  });

  group('#checkForSections', () {
    group('#sectionSetupPattern', () {
      test('is correct value', () {
        final expected =
            RegExp('.*${FileReplacements.sectionSetUp}' r'({{[\^#/]\S+}}).*');

        expect(testFileReplacements.sectionSetupPattern, expected);
      });

      test('matches', () {
        const matches = [
          '{{^asdf}}',
          '{{#asdf}}',
          '{{/asdf}}',
          r'{{#.,<>$({})}}',
        ];

        for (final match in matches) {
          final content = '${FileReplacements.sectionSetUp}$match';
          expect(
            testFileReplacements.sectionSetupPattern.hasMatch(content),
            isTrue,
          );
        }
      });
    });

    group('#sectionPattern', () {
      const variable = Variable(name: 'name', placeholder: '_NAME_');

      test('is correct value', () {
        final expected = RegExp(r'(\w+)' '${variable.placeholder}');

        expect(testFileReplacements.sectionPattern(variable), expected);
      });

      test('matches', () {
        const matches = {
          'if',
          'endIf',
          'endif',
          'ifNot',
          'ifnot',
          'something',
        };

        for (final match in matches) {
          final content = '$match${variable.placeholder}';

          final matches =
              testFileReplacements.sectionPattern(variable).allMatches(content);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), content);
          expect(matchResult.group(1), match);
        }
      });
    });

    test('returns original content if section is not found', () {
      const content = 'content';
      const expected = ContentReplacement(content: content, used: {});

      final result = testFileReplacements.checkForSections(
        content,
        const Variable(name: 'name', placeholder: 'value'),
      );

      expect(result, expected);
    });

    test('returns new content when section is found', () {
      const content = '''
section_NAME_
some content
endSection_NAME_

// section_NAME_
// some more content
// endsection_NAME_

section_NAME_ //
other content //
EndSection_NAME_ //

invertSection_NAME_
last content
endSectioN_NAME_

fake_NAME_

section_NAME_ ENDSECTION_NAME_
''';

      const variable = Variable(name: 'name', placeholder: '_NAME_');

      const expectedContent = '''
{{#name}}
some content
{{/name}}

{{#name}}
// some more content
{{/name}}

{{#name}}
other content //
{{/name}}

{{^name}}
last content
{{/name}}

fake_NAME_

{{/name}}
''';

      const expected = ContentReplacement(
        content: expectedContent,
        used: {'name'},
      );

      final result = testFileReplacements.checkForSections(
        content,
        variable,
      );

      expect(result, expected);
    });
  });

  group('#checkForVariables', () {
    group('#variablePattern', () {
      const placeholder = '_PEANUT_';
      const variable = Variable(name: 'peanut', placeholder: placeholder);

      test('is correct value', () {
        final expected = RegExp(
          r'(\{*\S*)' '$placeholder' r'(?:b(?:race)?(\d+))?(\w*\}*)',
        );

        expect(testFileReplacements.variablePattern(variable), expected);
      });

      test('matches', () {
        const matches = {
          placeholder: ['', null, ''],
          '${placeholder}snake': ['', null, 'snake'],
          '${placeholder}snakeCase': ['', null, 'snakeCase'],
          '${placeholder}snake}': ['', null, 'snake}'],
          '${placeholder}snakeCase}': ['', null, 'snakeCase}'],
          '${placeholder}bsnake': ['', null, 'bsnake'],
          '${placeholder}b2snake': ['', '2', 'snake'],
          '${placeholder}b99snakeCase}': ['', '99', 'snakeCase}'],
          '${placeholder}b999snakeCase}': ['', '999', 'snakeCase}'],
          '${placeholder}b2': ['', '2', ''],
          '${placeholder}b99': ['', '99', ''],
          '${placeholder}b999': ['', '999', ''],
          '${placeholder}brace2': ['', '2', ''],
          '${placeholder}brace99': ['', '99', ''],
          '${placeholder}brace999': ['', '999', ''],
          '{$placeholder': ['{', null, ''],
          '{{$placeholder': ['{{', null, ''],
          '$placeholder}': ['', null, '}'],
          '$placeholder}}': ['', null, '}}'],
          '{{#$placeholder}}': ['{{#', null, '}}'],
          '{{/$placeholder}}': ['{{/', null, '}}'],
          '{{^$placeholder}}': ['{{^', null, '}}'],
          'a$placeholder': ['a', null, ''],
        };

        for (final match in matches.entries) {
          final matches = testFileReplacements
              .variablePattern(variable)
              .allMatches(match.key);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), match.key);
          expect(matchResult.group(1), match.value[0]);
          expect(matchResult.group(2), match.value[1]);
          expect(matchResult.group(3), match.value[2]);
        }

        const otherMatches = {
          '${placeholder}snake}a': [
            '${placeholder}snake}',
            '',
            null,
            'snake}',
          ],
          '${placeholder}snakeCase}a': [
            '${placeholder}snakeCase}',
            '',
            null,
            'snakeCase}',
          ],
        };

        for (final match in otherMatches.entries) {
          final matches = testFileReplacements
              .variablePattern(variable)
              .allMatches(match.key);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), match.value[0]);
          expect(matchResult.group(1), match.value[1]);
          expect(matchResult.group(2), match.value[2]);
          expect(matchResult.group(3), match.value[3]);
        }

        const placeholder2 = 'peanut-butter';
        const variable2 =
            Variable(name: 'variable2', placeholder: placeholder2);

        const sectionMatches = {
          '{{#$placeholder2}}': ['{{#', null, '}}'],
          '{{/$placeholder2}}': ['{{/', null, '}}'],
          '{{^$placeholder2}}': ['{{^', null, '}}'],
        };

        for (final match in sectionMatches.entries) {
          final matches = testFileReplacements
              .variablePattern(variable2)
              .allMatches(match.key);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), match.key);
          expect(matchResult.group(1), match.value[0]);
          expect(matchResult.group(2), match.value[1]);
          expect(matchResult.group(3), match.value[2]);
        }
      });
    });

    test('sets a deliminator when the variable is wrapped with braces', () {
      const content = '{_NAME_}';
      const expected = ContentReplacement(
        content: '{{=<< >>=}}{<<name>>}<<={{ }}=>>',
        used: {'name'},
      );

      final result = testFileReplacements.checkForVariables(
        content,
        const Variable(name: 'name', placeholder: '_NAME_'),
      );

      expect(result, expected);
    });

    group('throws $VariableException', () {
      test('when variables brace quantity is not supported', () {
        const contents = [
          '_NAME_b4',
          '_NAME_b99',
          '_NAME_b1',
          '_NAME_b0',
        ];

        for (final content in contents) {
          const variable = Variable(name: 'name', placeholder: '_NAME_');

          expect(
            () => testFileReplacements.checkForVariables(
              content,
              variable,
            ),
            throwsA(isA<VariableException>()),
          );
        }
      });
    });

    test('returns original content when variable is not found', () {
      const content = 'content';
      const expected = ContentReplacement(content: content, used: {});

      final result = testFileReplacements.checkForVariables(
        content,
        const Variable(name: 'name', placeholder: '_NAME_'),
      );

      expect(result, expected);
    });

    test('returns new content when variable is found', () {
      const variable = Variable(name: 'name', placeholder: '_NAME_');

      const content = '''
{{#_NEW_NAME_}}
{{^_NEW_NAME_}}
{{/_NEW_NAME_}}

{{#_NAME_}}
{{^_NAME_}}
{{/_NAME_}}

_NAME_
prefix_NAME_
_NAME_suffix
_NAME_b3
_NAME_b3suffix
_NAME_b3 _NAME_b2/_NAME_suffix
before text _NAME_ after text
''';

      const expectedContent = '''
{{#_NEW_NAME_}}
{{^_NEW_NAME_}}
{{/_NEW_NAME_}}

{{#_NAME_}}
{{^_NAME_}}
{{/_NAME_}}

{{name}}
prefix{{name}}
{{name}}suffix
{{{name}}}
{{{name}}}suffix
{{{name}}} {{name}}/{{name}}suffix
before text {{name}} after text
''';

      const expected = ContentReplacement(
        content: expectedContent,
        used: {'name'},
      );

      final result = testFileReplacements.checkForVariables(
        content,
        variable,
      );

      expect(result, expected);
    });
  });

  group('#writeFile', () {
    late MockLogger mockLogger;
    late FileSystem fileSystem;
    late File sourceFile;
    late File targetFile;
    const sourceFilePath = 'source.dart';
    const targetFilePath = 'target.dart';

    setUp(() {
      mockLogger = MockLogger();
      fileSystem = MemoryFileSystem();
      sourceFile = fileSystem.file(sourceFilePath)..createSync(recursive: true);

      targetFile = fileSystem.file(targetFilePath);
    });

    test('copies file when no variables or partials are provided', () {
      sourceFile.writeAsStringSync('hello from this side');

      final result = testFileReplacements.writeFile(
        outOfFileVariables: [],
        partials: [],
        variables: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(result, const FileWriteResult.empty());

      expect(targetFile.readAsStringSync(), 'hello from this side');

      verifyNoMoreInteractions(mockLogger);
    });

    test('prints warning if excess variables exist', () {
      verifyNever(() => mockLogger.warn(any()));

      const variable = Variable(placeholder: '_HELLO_', name: 'hello');

      const extraVariable = Variable(placeholder: '_GOODBYE_', name: 'goodbye');

      sourceFile.writeAsStringSync('replace: _HELLO_');

      final result = testFileReplacements.writeFile(
        outOfFileVariables: [],
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [
          variable,
          extraVariable,
        ],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(
        result,
        const FileWriteResult(
          usedVariables: {'hello'},
          usedPartials: {},
        ),
      );

      verify(
        () => mockLogger.warn(
          'Unused variables ("${extraVariable.name}") in `${sourceFile.path}`',
        ),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
    });

    test('ignores out of file variables when checking excess variables', () {
      verifyNever(() => mockLogger.warn(any()));

      const variable = Variable(placeholder: '_HELLO_', name: 'hello');

      // should be ignored by default
      const indexValueVariable = Variable(
        placeholder: kIndexValue,
        name: 'hello',
      );

      const ignoredVariable =
          Variable(placeholder: '_NO_ONE_CARES_', name: 'lol');

      sourceFile.writeAsStringSync('replace: _HELLO_');

      final result = testFileReplacements.writeFile(
        outOfFileVariables: [ignoredVariable, indexValueVariable],
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(
        result,
        const FileWriteResult(
          usedVariables: {'hello'},
          usedPartials: {},
        ),
      );

      verifyNoMoreInteractions(mockLogger);
    });

    test('includes out of file variables in content replacement', () {
      verifyNever(() => mockLogger.warn(any()));

      // should be ignored by default
      const indexValueVariable = Variable(
        placeholder: kIndexValue,
        name: 'sup',
      );

      const variable = Variable(placeholder: '_HELLO_', name: 'hello');

      const ignoredVariable =
          Variable(placeholder: '_NO_ONE_CARES_', name: 'lol');

      sourceFile.writeAsStringSync('replace: _HELLO_ _NO_ONE_CARES_');

      final result = testFileReplacements.writeFile(
        outOfFileVariables: [ignoredVariable, indexValueVariable],
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(
        result,
        const FileWriteResult(
          usedPartials: {},
          usedVariables: {'hello', 'lol'},
        ),
      );

      expect(targetFile.readAsStringSync(), 'replace: {{hello}} {{lol}}');

      verifyNoMoreInteractions(mockLogger);
    });

    test('prints warning if file does not exist', () {
      verifyNever(() => mockLogger.warn(any()));

      const variable = Variable(placeholder: '_HELLO_', name: 'hello');
      const extraVariable = Variable(placeholder: '_GOODBYE_', name: 'goodbye');

      sourceFile.deleteSync();

      final result = testFileReplacements.writeFile(
        outOfFileVariables: [],
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable, extraVariable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(result, const FileWriteResult.empty());

      verify(
        () => mockLogger.warn(
          'source file does not exist: ${sourceFile.path}',
        ),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
    });

    test('writes sections, variables, and partials', () {
      const content = '''
_VAR_ _VAR_snake _VAR_b3

section_SECTION_
invertSection_SECTION_
endSection_SECTION_

partials.page
partials.page.md
''';

      const expectedContent = '''
{{var}} {{#snakeCase}}{{{var}}}{{/snakeCase}} {{{var}}}

{{#section}}
{{^section}}
{{/section}}

{{> page.md }}
{{> page.md }}
''';

      const variable = Variable(placeholder: '_VAR_', name: 'var');
      const section = Variable(placeholder: '_SECTION_', name: 'section');
      const partial = Partial(path: 'path/page.md');

      sourceFile.writeAsStringSync(content);

      final result = testFileReplacements.writeFile(
        outOfFileVariables: [],
        partials: [partial],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable, section],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(
        result,
        const FileWriteResult(
          usedVariables: {'var', 'section'},
          usedPartials: {'path/page.md'},
        ),
      );

      expect(targetFile.readAsStringSync(), expectedContent);

      verifyNoMoreInteractions(mockLogger);
    });
  });
}

class _TestFileReplacements with FileReplacements {
  const _TestFileReplacements();
}
