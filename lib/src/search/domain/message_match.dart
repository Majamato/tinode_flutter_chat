/// The shortest input worth a message search, in letters and digits.
const minMessageSearchLength = 2;

final _word = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true);

/// Turns what the user typed into a full-text query over the cache, or null
/// when it is too short to search.
///
/// Every word must match (the words are AND-ed), each as the start of a
/// word in the message, so "hel wor" finds "Hello, world". Anything but
/// letters and digits separates words, so the input can't carry query
/// syntax.
String? messageMatch(String input) {
  final words = [for (final match in _word.allMatches(input)) match[0]!];
  if (words.join().length < minMessageSearchLength) {
    return null;
  }
  return [for (final word in words) '"$word"*'].join(' ');
}
