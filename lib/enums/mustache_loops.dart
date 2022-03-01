Pattern _matcher([String? char]) {
  final str = char ?? r'\w+';
  return RegExp(r'((?!\w)(\s))?(' '$str' r')$');
}

/// The loops from Mustache
enum MustacheLoops {
  /// the start of a loop
  start,

  /// the end of a loop
  end,

  /// the inverted start of a loop
  invert,
}

/// extensions on lists of [MustacheLoops]
extension ListMustacheLoopX on List<MustacheLoops> {
  /// checks [str] if it contains any of the [MustacheLoops]
  MustacheLoops? from(String? str) {
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

  /// gets the configName of the [MustacheLoops]
  List<String> get configNames {
    return map((section) => section.configName).toList();
  }

  /// retrieves the [MustacheLoops] from the [char]
  MustacheLoops section(String char) {
    return firstWhere((section) => section.configName == char);
  }
}

/// extension on mustache loops
extension MustacheLoopX on MustacheLoops {
  /// the letter(s) of the section
  String get configName {
    switch (this) {
      case MustacheLoops.start:
        return 'start';
      case MustacheLoops.end:
        return 'end';
      case MustacheLoops.invert:
        return 'nstart';
    }
  }

  /// whether this section is the start
  bool get isStart => this == MustacheLoops.start;

  /// whether this section is the end
  bool get isEnd => this == MustacheLoops.end;

  /// whether this section is inverted
  bool get isInvert => this == MustacheLoops.invert;

  /// the symbol of the section
  String get symbol {
    switch (this) {
      case MustacheLoops.start:
        return '#';
      case MustacheLoops.end:
        return '/';
      case MustacheLoops.invert:
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
