import 'dart:mirrors' as m;

List<String> reflectProperties(Object obj) {
  final reflection = m.reflect(obj);
  final properties = <String>[];
  for (final p in reflection.type.declarations.values) {
    if (p is m.VariableMirror &&
        p.isStatic == false &&
        p.isPrivate == false &&
        p.isExtensionMember == false &&
        p.isConst == false) {
      properties.add('${p.simpleName}');
    }
  }

  return properties;
}
