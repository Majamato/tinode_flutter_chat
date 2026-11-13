const _accented = 'àáâãäåāăąçćčďèéêëēęěìíîïīñńňòóôõöøōŕřśšťùúûüūůýÿźżž';
const _plain = 'aaaaaaaaacccdeeeeeeeiiiiinnnoooooooorrsstuuuuuuyyzzz';

final _word = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true);

/// Whether a person named [name] matches what the user typed: every word
/// of [input] starts a word of [name], so "ma mar" finds "Mario Martínez".
/// Case and accents don't count ("jose" finds "José"). Blank input
/// matches everyone.
bool nameMatches(String name, String input) {
  final wanted = _words(input);
  if (wanted.isEmpty) {
    return true;
  }
  final words = _words(name);
  return wanted.every((w) => words.any((word) => word.startsWith(w)));
}

List<String> _words(String text) => [
  for (final match in _word.allMatches(_fold(text))) match[0]!,
];

String _fold(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final char in lower.split('')) {
    final index = _accented.indexOf(char);
    out.write(index < 0 ? char : _plain[index]);
  }
  return out.toString();
}
