String withoutLeadingPremiumEmoji(String value) {
  final runes = value.runes.toList(growable: false);
  if (runes.isEmpty) return value;
  if (runes.first != 0x1F48E && runes.first != 0x1F451) {
    return value.trim();
  }
  return String.fromCharCodes(runes.skip(1)).trimLeft();
}
