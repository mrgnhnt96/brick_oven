import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_tag.dart';

void main() {
  const formatTags = [
    MustacheTag.camelCase,
    MustacheTag.constantCase,
    MustacheTag.dotCase,
    MustacheTag.headerCase,
    MustacheTag.lowerCase,
    MustacheTag.mustacheCase,
    MustacheTag.pascalCase,
    MustacheTag.paramCase,
    MustacheTag.pathCase,
    MustacheTag.sentenceCase,
    MustacheTag.snakeCase,
    MustacheTag.titleCase,
    MustacheTag.upperCase,
  ];

  const nonFormatTags = [
    MustacheTag.escaped,
    MustacheTag.unescaped,
    MustacheTag.if_,
    MustacheTag.ifNot,
    MustacheTag.endIf,
  ];

  const suffix = 'ASDF';

  const tagsWithoutSuffixes = {
    MustacheTag.camelCase: [
      'camelCase',
      'camelcase',
      'camel',
    ],
    MustacheTag.constantCase: [
      'constantCase',
      'constantcase',
      'constant',
    ],
    MustacheTag.dotCase: [
      'dotCase',
      'dotcase',
      'dot',
    ],
    MustacheTag.headerCase: [
      'headerCase',
      'headercase',
      'header',
    ],
    MustacheTag.lowerCase: [
      'lowerCase',
      'lowercase',
      'lower',
    ],
    MustacheTag.mustacheCase: [
      'mustacheCase',
      'mustachecase',
      'mustache',
    ],
    MustacheTag.pascalCase: [
      'pascalCase',
      'pascalcase',
      'pascal',
    ],
    MustacheTag.paramCase: [
      'paramCase',
      'paramcase',
      'param',
    ],
    MustacheTag.pathCase: [
      'pathCase',
      'pathcase',
      'path',
    ],
    MustacheTag.sentenceCase: [
      'sentenceCase',
      'sentencecase',
      'sentence',
    ],
    MustacheTag.snakeCase: [
      'snakeCase',
      'snakecase',
      'snake',
    ],
    MustacheTag.titleCase: [
      'titleCase',
      'titlecase',
      'title',
    ],
    MustacheTag.upperCase: [
      'upperCase',
      'uppercase',
      'upper',
    ],
    MustacheTag.escaped: [
      'escaped',
    ],
    MustacheTag.unescaped: [
      'unescaped',
    ],
    MustacheTag.if_: [
      'if',
    ],
    MustacheTag.ifNot: [
      'ifNot',
      'ifnot',
    ],
    MustacheTag.endIf: [
      'endIf',
      'endif',
    ],
  };

  const tagsWithSuffixes = {
    MustacheTag.camelCase: [
      'camelCase$suffix',
      'camelcase$suffix',
      'camel$suffix',
    ],
    MustacheTag.constantCase: [
      'constantCase$suffix',
      'constantCase$suffix',
      'constant$suffix',
    ],
    MustacheTag.dotCase: [
      'dotCase$suffix',
      'dotcase$suffix',
      'dot$suffix',
    ],
    MustacheTag.headerCase: [
      'headerCase$suffix',
      'headercase$suffix',
      'header$suffix',
    ],
    MustacheTag.lowerCase: [
      'lowerCase$suffix',
      'lowercase$suffix',
      'lower$suffix',
    ],
    MustacheTag.mustacheCase: [
      'mustacheCase$suffix',
      'mustacheCase$suffix',
      'mustache$suffix',
    ],
    MustacheTag.pascalCase: [
      'pascalCase$suffix',
      'pascalcase$suffix',
      'pascal$suffix',
    ],
    MustacheTag.paramCase: [
      'paramCase$suffix',
      'paramcase$suffix',
      'param$suffix',
    ],
    MustacheTag.pathCase: [
      'pathCase$suffix',
      'pathcase$suffix',
      'path$suffix',
    ],
    MustacheTag.sentenceCase: [
      'sentenceCase$suffix',
      'sentenceCase$suffix',
      'sentence$suffix',
    ],
    MustacheTag.snakeCase: [
      'snakeCase$suffix',
      'snakecase$suffix',
      'snake$suffix',
    ],
    MustacheTag.titleCase: [
      'titleCase$suffix',
      'titlecase$suffix',
      'title$suffix',
    ],
    MustacheTag.upperCase: [
      'upperCase$suffix',
      'uppercase$suffix',
      'upper$suffix',
    ],
    MustacheTag.escaped: [
      'escaped$suffix',
    ],
    MustacheTag.unescaped: [
      'unescaped$suffix',
    ],
    MustacheTag.if_: [
      'if$suffix',
    ],
    MustacheTag.ifNot: [
      'ifNot$suffix',
      'ifnot$suffix',
    ],
    MustacheTag.endIf: [
      'endIf$suffix',
      'endif$suffix',
    ],
  };

  const allTags = [...formatTags, ...nonFormatTags];

  test('MustacheTag.values', () {
    final tagsWithSuffixesKeys = tagsWithSuffixes.keys.toList();
    final tagsWithoutSuffixesKeys = tagsWithoutSuffixes.keys.toList();

    for (final value in MustacheTag.values) {
      expect(allTags, contains(value));
      expect(tagsWithSuffixesKeys, contains(value));
      expect(tagsWithoutSuffixesKeys, contains(value));
    }
  });

  group('MustacheTagX', () {
    group('#wrappedPattern', () {
      test('is correct value', () {
        final expected = RegExp(r'\S*\{{2,3}\S+\}{2,3}\S*');

        expect(MustacheTagX.wrappedPattern, expected);
      });

      test('matches', () {
        const matches = [
          'prefix{{foo}}',
          'prefix{{foo}}suffix',
          '{{foo}}suffix',
          '{{foo}}',
          '{{foo}}}',
          '{{{foo}}}',
          '{{{foo}}',
        ];

        for (final match in matches) {
          expect(MustacheTagX.wrappedPattern.hasMatch(match), isTrue);
        }
      });
    });

    group('#wrap', () {
      test('throws assertion when content is configured correctly', () {
        for (final tag in formatTags) {
          expect(() => tag.wrap('foo'), returnsNormally);
          expect(() => tag.wrap('{{foo}}'), returnsNormally);
          expect(() => tag.wrap('{{{foo}}}'), returnsNormally);
        }

        for (final tag in nonFormatTags) {
          expect(
            () => tag.wrap('{{foo}}'),
            throwsA(isA<AssertionError>()),
          );
          expect(
            () => tag.wrap('{{{foo}}}'),
            throwsA(isA<AssertionError>()),
          );
          expect(
            () => tag.wrap('foo'),
            returnsNormally,
          );
        }
      });

      test('tags the content correctly', () {
        for (final tag in formatTags) {
          expect(
            tag.wrap('{{{sup_dude}}}'),
            '{{#${tag.name}}}{{{sup_dude}}}{{/${tag.name}}}',
          );

          expect(
            tag.wrap('{{sup_dude}}'),
            '{{#${tag.name}}}{{sup_dude}}{{/${tag.name}}}',
          );
        }

        const nonFormatTagExpected = {
          MustacheTag.escaped: '{{{DUDE}}}',
          MustacheTag.unescaped: '{{DUDE}}',
          MustacheTag.if_: '{{#DUDE}}',
          MustacheTag.ifNot: '{{^DUDE}}',
          MustacheTag.endIf: '{{/DUDE}}',
        };

        for (final tag in nonFormatTags) {
          expect(
            tag.wrap('DUDE'),
            nonFormatTagExpected[tag],
          );
        }
      });
    });

    test('#isTag returns true when the value is a tag type', () {
      for (final tag in formatTags) {
        expect(tag.isFormat, isTrue);
      }

      for (final tag in nonFormatTags) {
        expect(tag.isFormat, isFalse);
      }
    });

    test('#isValue is correct for all values', () {
      final values = {
        MustacheTag.camelCase: () => MustacheTag.camelCase.isCamelCase,
        MustacheTag.constantCase: () => MustacheTag.constantCase.isConstantCase,
        MustacheTag.dotCase: () => MustacheTag.dotCase.isDotCase,
        MustacheTag.headerCase: () => MustacheTag.headerCase.isHeaderCase,
        MustacheTag.lowerCase: () => MustacheTag.lowerCase.isLowerCase,
        MustacheTag.mustacheCase: () => MustacheTag.mustacheCase.isMustacheCase,
        MustacheTag.pascalCase: () => MustacheTag.pascalCase.isPascalCase,
        MustacheTag.paramCase: () => MustacheTag.paramCase.isParamCase,
        MustacheTag.pathCase: () => MustacheTag.pathCase.isPathCase,
        MustacheTag.sentenceCase: () => MustacheTag.sentenceCase.isSentenceCase,
        MustacheTag.snakeCase: () => MustacheTag.snakeCase.isSnakeCase,
        MustacheTag.titleCase: () => MustacheTag.titleCase.isTitleCase,
        MustacheTag.upperCase: () => MustacheTag.upperCase.isUpperCase,
        MustacheTag.escaped: () => MustacheTag.escaped.isEscaped,
        MustacheTag.unescaped: () => MustacheTag.unescaped.isUnescaped,
        MustacheTag.if_: () => MustacheTag.if_.isIf,
        MustacheTag.ifNot: () => MustacheTag.ifNot.isIfNot,
        MustacheTag.endIf: () => MustacheTag.endIf.isEndIf,
      };

      final keys = values.keys;

      for (final key in MustacheTag.values) {
        expect(keys, contains(key));
      }

      for (final key in keys) {
        expect(values[key]!(), isTrue);
      }
    });
  });

  group('ListMustacheX', () {
    group('#findFrom', () {
      test('returns when the correct enum for value', () {
        final keys = tagsWithoutSuffixes.keys;

        for (final key in keys) {
          for (final value in tagsWithoutSuffixes[key]!) {
            final result = MustacheTag.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns appropriate value when provided with suffixes', () {
        final keys = tagsWithSuffixes.keys;

        for (final key in keys) {
          for (final value in tagsWithSuffixes[key]!) {
            final result = MustacheTag.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns null when value is not found', () {
        expect(MustacheTag.values.findFrom('nothing'), isNull);
        expect(MustacheTag.values.findFrom(null), isNull);
      });
    });

    group('#suffixFrom', () {
      test('returns the suffix for the provided value', () {
        final keys = tagsWithSuffixes.keys;

        for (final key in keys) {
          for (final value in tagsWithSuffixes[key]!) {
            final result = MustacheTag.values.suffixFrom(value);
            expect(result, suffix);
          }
        }
      });

      test('returns null when value is not found', () {
        expect(MustacheTag.values.suffixFrom('nothing'), isNull);
        expect(MustacheTag.values.suffixFrom(null), isNull);
      });
    });
  });
}
