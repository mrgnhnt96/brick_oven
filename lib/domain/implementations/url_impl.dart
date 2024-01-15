import 'package:path/path.dart';

import 'package:brick_oven/domain/config/name_config.dart';
import 'package:brick_oven/domain/implementations/include_impl.dart';
import 'package:brick_oven/domain/implementations/name_impl.dart';
import 'package:brick_oven/domain/interfaces/include.dart';
import 'package:brick_oven/domain/interfaces/name.dart';
import 'package:brick_oven/domain/interfaces/url.dart';

/// {@macro url}
class UrlImpl extends Url {
  /// {@macro url}
  UrlImpl(
    super.config, {
    required this.path,
  })  : name = config.nameConfig == null
            ? NameImpl(
                NameConfig(renameWith: basename(path)),
                originalName: basename(path),
              )
            : NameImpl(
                config.nameConfig!,
                originalName: basename(path),
              ),
        include = config.includeConfig == null
            ? null
            : IncludeImpl(config.includeConfig!);

  @override
  final Name name;

  @override
  final Include? include;

  @override
  final String path;

  @override
  String formatName() {
    return name.format(
      postStartBraces: '% ',
      preEndBraces: ' %',
    );
  }
}
