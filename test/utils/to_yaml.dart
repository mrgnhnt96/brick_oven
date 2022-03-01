import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import '../utils/fakes.dart';

extension BrickX on Brick {
  YamlMap toYaml() {
    return FakeYamlMap(toJson());
  }

  Map<String, dynamic> toJson() {
    // ignore: avoid_dynamic_calls, lines_longer_than_80_chars, unused_local_variable
    final dirsData = configuredDirs.fold(
      <String, dynamic>{},
      (Map<String, dynamic> p, e) => p..addAll(e.toJson()),
    );

    final filesData = configuredFiles.fold(
      <String, dynamic>{},
      (Map<String, dynamic> p, e) => p..addAll(e.toJson()),
    );

    return <String, dynamic>{
      'source': source.sourceDir,
      'dirs': FakeYamlMap(dirsData),
      'files': FakeYamlMap(filesData),
    };
  }
}

extension BrickSourceX on BrickSource {
  YamlMap toYaml() {
    return FakeYamlMap(toJson());
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source': FakeYamlMap(<String, dynamic>{'path': localPath}),
    };
  }
}

extension BrickPathX on BrickPath {
  YamlMap toYaml() {
    return FakeYamlMap(toJson());
  }

  Map<String, dynamic> toJson({
    bool? inferred,
    bool? asKey,
  }) {
    if (inferred == true) {
      return <String, dynamic>{
        path: null,
      };
    } else if (asKey == true) {
      return <String, dynamic>{
        path: FakeYamlMap(<String, dynamic>{
          'name': FakeYamlMap(
            <String, dynamic>{
              'value': name.value,
              'prefix': name.prefix,
              'suffix': name.suffix,
            },
          )
        }),
      };
    } else {
      return <String, dynamic>{
        path: name.value,
      };
    }
  }
}

extension BrickFileX on BrickFile {
  YamlMap toYaml() {
    return FakeYamlMap(toJson());
  }

  Map<String, dynamic> toJson() {
    final variableData = <String, dynamic>{};
    for (final variable in variables) {
      variableData[variable.name] = variable.placeholder;
    }

    return <String, dynamic>{
      path: FakeYamlMap(<String, dynamic>{
        'vars': FakeYamlMap(variableData),
        'name': FakeYamlMap(<String, dynamic>{
          'value': name?.value,
          'prefix': name?.prefix,
          'suffix': name?.suffix,
        })
      }),
    };
  }
}
