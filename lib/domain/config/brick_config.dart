import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

import 'package:brick_oven/domain/config/brick_config_entry.dart';
import 'package:brick_oven/domain/config/directory_config.dart';
import 'package:brick_oven/domain/config/file_config.dart';
import 'package:brick_oven/domain/config/mason_brick_config.dart';
import 'package:brick_oven/domain/config/partial_config.dart';
import 'package:brick_oven/domain/config/string_or_entry.dart';
import 'package:brick_oven/domain/config/url_config.dart';
import 'package:brick_oven/utils/vars_mixin.dart';

part 'brick_config.g.dart';

extension _MasonBrickConfigX on StringOr<MasonBrickConfig> {
  StringOr<MasonBrickConfig> updateRootPath(String rootPath) {
    if (isString) {
      return StringOr(string: p.join(rootPath, string));
    }

    return StringOr(
      object: MasonBrickConfig(
        path: p.join(rootPath, object!.path),
        ignoreVars: object!.ignoreVars,
      ),
    );
  }
}

@JsonSerializable()
class BrickConfig extends BrickConfigEntry with EquatableMixin, VarsMixin {
  factory BrickConfig({
    required String sourcePath,
    required StringOr<MasonBrickConfig>? masonBrickConfig,
    required Map<String, FileConfig>? fileConfigs,
    required Map<String, DirectoryConfig>? directoryConfigs,
    required Map<String, UrlConfig>? urlConfigs,
    required Map<String, PartialConfig?>? partialConfigs,
    required List<String>? exclude,
    required String? configPath,
  }) {
    if (configPath == null) {
      return BrickConfig._(
        sourcePath: sourcePath,
        masonBrickConfig: masonBrickConfig,
        fileConfigs: fileConfigs,
        directoryConfigs: directoryConfigs,
        urlConfigs: urlConfigs,
        partialConfigs: partialConfigs,
        exclude: exclude,
        configPath: configPath,
      );
    }

    final configDir = p.dirname(configPath);

    final updatedSourcePath = p.join(configDir, sourcePath);

    final updateMasonBrickConfig = masonBrickConfig?.updateRootPath(configDir);

    return BrickConfig._(
      sourcePath: updatedSourcePath,
      masonBrickConfig: updateMasonBrickConfig,
      fileConfigs: fileConfigs,
      directoryConfigs: directoryConfigs,
      urlConfigs: urlConfigs,
      partialConfigs: partialConfigs,
      exclude: exclude,
      configPath: configPath,
    );
  }
  BrickConfig._({
    required this.sourcePath,
    required this.masonBrickConfig,
    required this.fileConfigs,
    required this.directoryConfigs,
    required this.urlConfigs,
    required this.partialConfigs,
    required this.exclude,
    required this.configPath,
  }) : assert(
          configPath == null || configPath.endsWith('brick_oven.yaml'),
          'configPath must end with brick_oven.yaml',
        );

  BrickConfig.self(BrickConfig self)
      : this._(
          sourcePath: self.sourcePath,
          masonBrickConfig: self.masonBrickConfig,
          fileConfigs: self.fileConfigs,
          directoryConfigs: self.directoryConfigs,
          urlConfigs: self.urlConfigs,
          partialConfigs: self.partialConfigs,
          exclude: self.exclude,
          configPath: self.configPath,
        );

  factory BrickConfig.fromJson(
    Map json, {
    required String? configPath,
  }) {
    json['config_path'] = configPath;

    return _$BrickConfigFromJson(json);
  }

  @JsonKey(name: 'source')
  final String sourcePath;
  @JsonKey(name: 'brick_config')
  final StringOr<MasonBrickConfig>? masonBrickConfig;
  @JsonKey(name: 'files')
  final Map<String, FileConfig>? fileConfigs;
  @JsonKey(name: 'dirs')
  final Map<String, DirectoryConfig>? directoryConfigs;
  @JsonKey(name: 'urls')
  final Map<String, UrlConfig>? urlConfigs;
  @JsonKey(name: 'partials')
  final Map<String, PartialConfig?>? partialConfigs;
  final List<String>? exclude;
  final String? configPath;

  @override
  List<Iterable<(String, String)>> get combine => [
        ...?fileConfigs?.values.map((e) => e.varsMap),
        ...?directoryConfigs?.values.map((e) => e.varsMap),
        ...?urlConfigs?.values.map((e) => e.varsMap),
        ...?partialConfigs?.values.map((e) => e?.varsMap ?? []),
      ];

  @override
  Map<String, dynamic> toJson() => _$BrickConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
