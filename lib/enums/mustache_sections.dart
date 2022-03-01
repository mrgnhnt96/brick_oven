/// The sections from Mustache
enum MustacheSections {
  /// the start of a section
  start,

  /// the end of a section
  end,

  /// the inverted start of a section
  invert,
}

Pattern _matcher([String? char]) {
  final str = char ?? r'\w';
  return RegExp(r'((?!\w)(\s))?(' '$str' r')$');
}

/// extension on mustache sections
extension MustacheSectionsX on MustacheSections {
  /// the letter(s) of the section
  String get configName {
    switch (this) {
      case MustacheSections.start:
        return 's';
      case MustacheSections.end:
        return 'e';
      case MustacheSections.invert:
        return 'n';
    }
  }

  /// whether this section is the start
  bool get isStart => this == MustacheSections.start;

  /// whether this section is the end
  bool get isEnd => this == MustacheSections.end;

  /// whether this section is inverted
  bool get isInvert => this == MustacheSections.invert;

  /// the symbol of the section
  String get symbol {
    switch (this) {
      case MustacheSections.start:
        return '#';
      case MustacheSections.end:
        return '/';
      case MustacheSections.invert:
        return '^';
    }
  }

  /// the matcher for the section
  Pattern get matcher {
    return _matcher(configName);
  }

  /// formats the [str] using [symbol]
  String format(String str) {
    return '{{$symbol$str}}';
  }
}

/// extensions on lists of [MustacheSections]
extension MustacheSectionListX on List<MustacheSections> {
  /// checks [str] if it contains any of the [MustacheSections]
  MustacheSections? from(String? str) {
    if (str == null) return null;

    final pattern = RegExp(r'((?!\w)(\s))?(\w)$');

    final matches = pattern.allMatches(str);

    if (matches.isEmpty) {
      return null;
    }

    final section = matches.first.group(3);

    if (configNames.contains(section)) {
      return this.section(section!);
    }

    return null;
  }

  /// gets the configName of the [MustacheSections]
  List<String> get configNames {
    return map((section) => section.configName).toList();
  }

  /// retrieves the [MustacheSections] from the [char]
  MustacheSections section(String char) {
    return firstWhere((section) => section.configName == char);
  }
}
