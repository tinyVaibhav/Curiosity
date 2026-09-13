/// Utilities for parsing and formatting text and URLs
class TextUtils {
  /// Parses raw Wikipedia titles:
  /// - Replaces underscores with spaces
  /// - Strips trailing disambiguation tags in parentheses (e.g., "Music_Box_(album)" -> "Music Box")
  static String cleanWikiTitle(String rawTitle) {
    if (rawTitle.isEmpty) return '';

    // Replace underscores with spaces
    String cleaned = rawTitle.replaceAll('_', ' ');

    // Strip trailing disambiguation like "(album)", "(disambiguation)", "(film)", "(planet)"
    // Matches parentheses at the end of the string
    cleaned = cleaned.replaceAll(RegExp(r'\s*\([^)]*\)$'), '');

    return cleaned.trim();
  }

  /// Formats the canonical mobile Wikipedia URL
  static String formatWikipediaUrl(String title) {
    final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
    return 'https://en.m.wikipedia.org/wiki/$encoded';
  }
}
