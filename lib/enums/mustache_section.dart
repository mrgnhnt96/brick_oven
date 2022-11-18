Pattern _matcher([String? char]) {
  final str = char ?? r'\w+';
  return RegExp(r'((?!\w)(\s))?(' '$str' r')$');
}

/// The sections from Mustache
enum MustacheSection {
  /// the start of a section
  start,

  /// the end of a section
  end,

  /// the inverted start of a section
  invert,
}

/// extensions on lists of [MustacheSection]
extension ListMustacheSectionX on List<MustacheSection> {
  /// checks [str] if it contains any of the [MustacheSection]
  MustacheSection? from(String? str) {
    if (str == null) return null;

    final pattern = _matcher();

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

  /// gets the configName of the [MustacheSection]
  List<String> get configNames {
    return map((section) => section.configName).toList();
  }

  /// retrieves the [MustacheSection] from the [char]
  MustacheSection section(String char) {
    return firstWhere((section) => section.configName == char);
  }
}

/// extension on mustache sections
extension MustacheSectionX on MustacheSection {
  /// the letter(s) of the section
  String get configName {
    switch (this) {
      case MustacheSection.start:
        return 'start';
      case MustacheSection.end:
        return 'end';
      case MustacheSection.invert:
        return 'nstart';
    }
  }

  /// whether this section is the start
  bool get isStart => this == MustacheSection.start;

  /// whether this section is the end
  bool get isEnd => this == MustacheSection.end;

  /// whether this section is inverted
  bool get isInvert => this == MustacheSection.invert;

  /// the symbol of the section
  String get symbol {
    switch (this) {
      case MustacheSection.start:
        return '#';
      case MustacheSection.end:
        return '/';
      case MustacheSection.invert:
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
