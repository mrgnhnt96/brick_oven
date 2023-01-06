import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick_url.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';

void main() {
  group('$BrickUrl', () {
    test('can be instantiated', () {
      final url = BrickUrl('path');

      expect(url, isA<BrickUrl>());
    });

    test('throws assertion error when path contains extension', () {
      expect(() => BrickUrl('path.ext'), throwsA(isA<AssertionError>()));
    });

    test('throws assertion error when includeIf and includeIfNot are both set',
        () {
      expect(
        () => BrickUrl(
          'path',
          includeIf: 'check',
          includeIfNot: 'checkNot',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    group('#fromYaml', () {
      group('throws $UrlException when', () {
        test('path contains extension', () {
          expect(
            () => BrickUrl.fromYaml(YamlValue.from('path'), 'path.ext'),
            throwsA(isA<UrlException>()),
          );
        });

        test('yaml is error', () {
          expect(
            () => BrickUrl.fromYaml(const YamlValue.error('error'), 'path'),
            throwsA(isA<UrlException>()),
          );
        });

        test('yaml is not correct type', () {
          expect(
            () => BrickUrl.fromYaml(YamlValue.list(YamlList.wrap([])), 'path'),
            throwsA(isA<UrlException>()),
          );
        });

        test('yaml has extra keys', () {
          expect(
            () => BrickUrl.fromYaml(
              YamlValue.from(
                YamlMap.wrap({
                  'name': 'name',
                  'extra': 'extra',
                }),
              ),
              'path',
            ),
            throwsA(isA<UrlException>()),
          );
        });

        test('include_if and include_if_not are both used', () {
          final yaml = loadYaml('''
include_if: check
include_if_not: check
''') as YamlMap;

          expect(
            () => BrickUrl.fromYaml(YamlValue.from(yaml), 'path'),
            throwsA(isA<ConfigException>()),
          );
        });
      });

      test('returns when yaml is null ', () {
        final url = BrickUrl.fromYaml(const YamlValue.none(), 'path');

        expect(url, BrickUrl('path'));
      });

      test('returns when yaml is map ', () {
        final url = BrickUrl.fromYaml(
          YamlValue.from(
            YamlMap.wrap({
              'name': {
                'value': 'name',
                'format': 'camel',
              }
            }),
          ),
          'path',
        );

        expect(
          url,
          BrickUrl(
            'path',
            name: Name('name', tag: MustacheTag.camelCase),
          ),
        );
      });

      test('can parse include if', () {
        final yaml = loadYaml('''
include_if: check
''') as YamlMap;

        final instance = BrickUrl.fromYaml(
          YamlValue.from(yaml),
          'path/to/url',
        );

        expect(instance.includeIf, 'check');
      });

      test('can parse include if not', () {
        final yaml = loadYaml('''
include_if_not: check
''') as YamlMap;

        final instance = BrickUrl.fromYaml(
          YamlValue.from(yaml),
          'path/to/url',
        );

        expect(instance.includeIfNot, 'check');
      });
    });

    group('#formatName', () {
      group('returns correct format when', () {
        test('name is not provided', () {
          final url = BrickUrl('path/to/file');

          expect(url.formatName(), '{{{% file %}}}');
        });

        test('name is provided', () {
          final url = BrickUrl('path', name: Name('name'));

          expect(url.formatName(), '{{{% name %}}}');
        });

        test('name is provided with additional args', () {
          final url1 = BrickUrl(
            'path',
            name: Name(
              'name',
              prefix: 'prefix',
              suffix: 'suffix',
              tag: MustacheTag.camelCase,
              section: 'section',
            ),
          );

          expect(
            url1.formatName(),
            '{{#section}}prefix{{#camelCase}}{{{% name %}}}{{/camelCase}}suffix{{/section}}',
          );

          final url2 = BrickUrl(
            'path',
            name: Name(
              'name',
              prefix: 'prefix',
              suffix: 'suffix',
              tag: MustacheTag.camelCase,
              invertedSection: 'invertedSection',
            ),
          );

          expect(
            url2.formatName(),
            '{{^invertedSection}}prefix{{#camelCase}}{{{% name %}}}{{/camelCase}}suffix{{/invertedSection}}',
          );
        });
      });
    });

    group('variables', () {
      test('returns when name is provided', () {
        final url = BrickUrl(
          'path/to/somewhere',
          name: Name('name'),
        );

        expect(url.variables, ['name']);
      });

      test('returns when name is not provided', () {
        final url = BrickUrl('path/to/somewhere');

        expect(url.variables, ['somewhere']);
      });
    });
  });
}
