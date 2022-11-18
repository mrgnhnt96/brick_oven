/// The sections from Mustache
enum MustacheSection {
  /// the inverted start of a section
  ifNot,

  /// the start of a section
  if_,

  /// the end of a section
  endIf,
}

/// extensions on lists of [MustacheSection]
extension ListMustacheSectionX on List<MustacheSection> {
  /// checks [value] if it contains any of the [MustacheSection]
  MustacheSection? findFrom(String? value) {
    if (value == null) {
      return null;
    }

    final valueLower = value.toLowerCase();

    for (final e in this) {
      final name = e.name.toLowerCase().replaceAll('_', '');

      if (valueLower.startsWith(name)) {
        return e;
      }
    }

    return null;
  }
}

/// extension on mustache sections
extension MustacheSectionX on MustacheSection {
  /// whether this section is the start
  bool get isStart => this == MustacheSection.if_;

  /// whether this section is the end
  bool get isEnd => this == MustacheSection.endIf;

  /// whether this section is inverted
  bool get isInvert => this == MustacheSection.ifNot;

  /// the symbol of the section
  String get symbol {
    switch (this) {
      case MustacheSection.if_:
        return '#';
      case MustacheSection.endIf:
        return '/';
      case MustacheSection.ifNot:
        return '^';
    }
  }

  /// formats the [str] using [symbol]
  String format(String str) {
    return '{{$symbol$str}}';
  }
}
