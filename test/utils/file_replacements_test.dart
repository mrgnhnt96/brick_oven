// ignore_for_file: cascade_invocations

import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/content_replacement.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test_utils/mocks.dart';

void main() {
  const testFileReplacements = _TestFileReplacements();

  group('#checkForPartials', () {
    test('replaces partial placeholder with partial value', () {
      const content = '''
partial.do_not_replace
{{> partial }}

// partial.replace_me
// partial.replace_me.dart
partial.replace_me_too //
partial.replace_me_too.md //
''';

      const expectedContent = '''
partial.do_not_replace
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
if_NAME_
some content
endIf_NAME_

// if_NAME_
// some more content
// endif_NAME_

if_NAME_ //
other content //
EndIf_NAME_ //

ifNot_NAME_
last content
endiF_NAME_

fake_NAME_

if_NAME_ ENDIF_NAME_
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
        final expected = RegExp(r'(\{*\S*)' '$placeholder' r'(\w*\}*)');

        expect(testFileReplacements.variablePattern(variable), expected);
      });

      test('matches', () {
        const matches = {
          placeholder: ['', ''],
          '${placeholder}snake': ['', 'snake'],
          '${placeholder}snakeCase': ['', 'snakeCase'],
          '${placeholder}snake}': ['', 'snake}'],
          '${placeholder}snakeCase}': ['', 'snakeCase}'],
          '{${placeholder}snake': ['{', 'snake'],
          '{${placeholder}snakeCase': ['{', 'snakeCase'],
          '{$placeholder': ['{', ''],
          '{{$placeholder': ['{{', ''],
          '{$placeholder}': ['{', '}'],
          '{{$placeholder}}': ['{{', '}}'],
          '$placeholder}': ['', '}'],
          '$placeholder}}': ['', '}}'],
          '{{#$placeholder}}': ['{{#', '}}'],
          '{{/$placeholder}}': ['{{/', '}}'],
          '{{^$placeholder}}': ['{{^', '}}'],
          'a$placeholder': [
            'a',
            '',
          ],
        };

        const otherMatches = {
          '${placeholder}snake}a': [
            '${placeholder}snake}',
            '',
            'snake}',
          ],
          '${placeholder}snakeCase}a': [
            '${placeholder}snakeCase}',
            '',
            'snakeCase}',
          ],
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
        }

        for (final match in otherMatches.entries) {
          final matches = testFileReplacements
              .variablePattern(variable)
              .allMatches(match.key);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), match.value[0]);
          expect(matchResult.group(1), match.value[1]);
          expect(matchResult.group(2), match.value[2]);
        }

        const placeholder2 = 'peanut-butter';
        const variable2 =
            Variable(name: 'variable2', placeholder: placeholder2);

        const otherMatches2 = {
          '{{#$placeholder2}}': ['{{#', '}}'],
          '{{/$placeholder2}}': ['{{/', '}}'],
          '{{^$placeholder2}}': ['{{^', '}}'],
        };

        for (final match in otherMatches2.entries) {
          final matches = testFileReplacements
              .variablePattern(variable2)
              .allMatches(match.key);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), match.key);
          expect(matchResult.group(1), match.value[0]);
          expect(matchResult.group(2), match.value[1]);
        }
      });
    });

    group('throws $VariableException', () {
      test('when variables starts or ends with a bracket', () {
        const contents = [
          '{{{_NAME_}}}',
          '{{_NAME_}}',
          '{_NAME_}',
          '{_NAME_',
          '_NAME_}',
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
_NAME_escaped
_NAME_escapedsuffix
_NAME_escaped _NAME_unescaped/_NAME_suffix
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

      testFileReplacements.writeFile(
        ignoreVariablesIfNotPresent: [],
        partials: [],
        variables: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(targetFile.readAsStringSync(), 'hello from this side');
    });

    test('prints warning if excess variables exist', () {
      verifyNever(() => mockLogger.warn(any()));

      const variable = Variable(placeholder: '_HELLO_', name: 'hello');
      const extraVariable = Variable(placeholder: '_GOODBYE_', name: 'goodbye');
      const ignoredVariable =
          Variable(placeholder: '_NO_ONE_CARES_', name: 'lol');

      sourceFile.writeAsStringSync('replace: _HELLO_');

      testFileReplacements.writeFile(
        ignoreVariablesIfNotPresent: [ignoredVariable],
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable, extraVariable, ignoredVariable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      verify(
        () => mockLogger.warn(
          'Unused variables ("${extraVariable.name}") in `${sourceFile.path}`',
        ),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
    });

    test('prints warning if file does not exist', () {
      verifyNever(() => mockLogger.warn(any()));

      const variable = Variable(placeholder: '_HELLO_', name: 'hello');
      const extraVariable = Variable(placeholder: '_GOODBYE_', name: 'goodbye');

      sourceFile.deleteSync();

      testFileReplacements.writeFile(
        ignoreVariablesIfNotPresent: [],
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable, extraVariable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      verify(
        () => mockLogger.warn(
          'source file does not exist: ${sourceFile.path}',
        ),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
    });

    test('writes sections, variables, and partials', () {
      const content = '''
_VAR_ _VAR_snake _VAR_escaped

if_SECTION_
ifNot_SECTION_
endIf_SECTION_

partial.page
partial.page.md
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

      testFileReplacements.writeFile(
        ignoreVariablesIfNotPresent: [],
        partials: [partial],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable, section],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(targetFile.readAsStringSync(), expectedContent);
    });
  });
}

class _TestFileReplacements with FileReplacements {
  const _TestFileReplacements();
}
