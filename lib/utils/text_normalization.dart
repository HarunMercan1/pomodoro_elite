String withoutLeadingPremiumEmoji(String value) {
  final runes = value.runes.toList(growable: false);
  if (runes.isEmpty) return value;
  if (runes.first != 0x1F48E && runes.first != 0x1F451) {
    return value.trim();
  }
  return String.fromCharCodes(runes.skip(1)).trimLeft();
}

/// Whether [input] matches the localized delete confirmation [word].
///
/// Case-insensitive, tolerant of surrounding whitespace and of Turkish dotted /
/// dotless "i" variants (so "sil", "SIL" and "SİL" all match "SİL"). The
/// English "DELETE" is always accepted as a fallback for every locale.
bool matchesDeleteConfirmation(String input, String word) {
  String normalize(String value) => value
      .trim()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .toLowerCase();

  final normalizedInput = normalize(input);
  if (normalizedInput.isEmpty) return false;
  return normalizedInput == normalize(word) || normalizedInput == 'delete';
}
