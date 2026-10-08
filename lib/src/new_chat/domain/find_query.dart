/// The shortest input worth a search.
const minFindLength = 2;

final _separators = RegExp(r'[\s,]+');
final _phone = RegExp(r'^\+?[0-9][0-9()\-]*$');

/// Turns what the user typed into a `fnd` query, or null when it is too
/// short to search.
///
/// Each word may match on its own (the words are OR-ed). A word is looked
/// up as a tag and as a login (`basic:`); emails, phone numbers and words
/// with their own prefix go as typed, since the server prefixes those
/// itself.
String? findQuery(String input) {
  final words = [
    for (final word in input.toLowerCase().split(_separators))
      if (word.isNotEmpty) word,
  ];
  if (words.join().length < minFindLength) {
    return null;
  }
  return {
    for (final word in words)
      if (word.contains(':') || word.contains('@') || _phone.hasMatch(word))
        word
      else ...[
        word,
        'basic:$word',
      ],
  }.join(',');
}
