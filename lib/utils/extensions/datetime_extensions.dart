/// the extension for [DateTime]
extension DateTimeX on DateTime {
  /// returns a string representation of the [DateTime]
  String get formatted {
    final hour = this.hour.to12Hour;
    final minute = this.minute.padded;
    final second = this.second.padded;
    final meridiem = this.hour.meridiem;

    return '$hour:$minute:$second $meridiem';
  }
}

extension _NumX on num {
  String get padded => toString().padLeft(2, '0');

  String get to12Hour {
    final hour = this % 12;
    return hour == 0 ? '12' : hour.toString();
  }

  String get meridiem => this >= 12 ? 'PM' : 'AM';
}
