/// The sections from Mustache
enum MustacheSection {
  /// the inverted start of a section
  invertedSection,

  /// the start of a section
  section,

  /// the end of a section
  endSection,
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
      final name = e.name.toLowerCase();

      if (valueLower.startsWith(name)) {
        return e;
      }

      if (e.isInvert) {
        if (valueLower.startsWith('invertsection')) {
          return e;
        }
      }
    }

    return null;
  }
}

/// extension on mustache sections
extension MustacheSectionX on MustacheSection {
  /// whether this section is the start
  bool get isStart => this == MustacheSection.section;

  /// whether this section is the end
  bool get isEnd => this == MustacheSection.endSection;

  /// whether this section is inverted
  bool get isInvert => this == MustacheSection.invertedSection;

  /// the symbol of the section
  String get symbol {
    switch (this) {
      case MustacheSection.section:
        return '#';
      case MustacheSection.endSection:
        return '/';
      case MustacheSection.invertedSection:
        return '^';
    }
  }

  /// formats the [str] using [symbol]
  String format(String str) {
    return '{{$symbol$str}}';
  }
}
