mixin VarsMixin {
  List<dynamic> get variablesToProcess => [];
  List<Iterable<(String, String)>> get combine => [];

  Set<(String, String)> _processVariables(List<dynamic> items) {
    final vars = <(String, String)>{};

    for (final item in items) {
      if (item == null || (item is String && item.isEmpty)) {
        continue;
      }

      if (item is String) {
        vars.add((item, item));
      } else if (item is Map<String, String?>) {
        for (final e in item.entries) {
          vars.add((e.key, e.value ?? e.key));
        }
      } else if (item is Iterable<String>) {
        vars.addAll(item.map((e) => (e, e)));
      } else {
        throw Exception('item must be a String, Map, or Iterable<String>');
      }
    }

    return vars;
  }

  Iterable<String> get vars => varsMap.map((e) => e.$2);

  Set<(String, String)> get varsMap {
    final vars = <(String, String)>{};

    if (variablesToProcess.isNotEmpty) {
      vars.addAll(_processVariables(variablesToProcess));
    }

    if (combine.isNotEmpty) {
      for (final item in combine) {
        vars.addAll(item);
      }
    }

    return vars;
  }
}
