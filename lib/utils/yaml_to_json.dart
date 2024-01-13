import 'dart:convert';

import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';

class YamlToJson {
  YamlToJson._({
    required this.content,
  });

  static Map<dynamic, dynamic> fromPath(String path) {
    final file = di<FileSystem>().file(path);

    return fromFile(file);
  }

  static Map<dynamic, dynamic> fromFile(File file) {
    final content = file.readAsStringSync();

    return fromContent(content);
  }

  static Map<dynamic, dynamic> fromContent(String content) {
    final yaml = YamlToJson._(content: content);

    return yaml.json;
  }

  final String content;

  Map<dynamic, dynamic> get json {
    final yaml = loadYaml(content);

    final rawJson = jsonDecode(jsonEncode(yaml)) as Map;

    final json = Map<dynamic, dynamic>.from(rawJson);

    return json;
  }
}
