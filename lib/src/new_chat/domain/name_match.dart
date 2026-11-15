const _accented = 'àáâãäåāăąçćčďèéêëēęěìíîïīñńňòóôõöøōŕřśšťùúûüūůýÿźżž';
const _plain = 'aaaaaaaaacccdeeeeeeeiiiiinnnoooooooorrsstuuuuuuyyzzz';

final _word = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true);

/// The shortest typed word that may be one letter off.
const minTypoLength = 3;

/// How well a name matches what the user typed, worst first.
enum NameMatch {
  none,

  /// Matches with a letter off in at least one typed word.
  typo,

  /// Every typed word starts a word of the name.
  exact,
}

/// How well a person or group named [name] matches what the user typed.
///
/// It is [NameMatch.exact] when every word of [input] starts a word of
/// [name], so "ma mar" finds "Mario Martínez". A typed word of
/// [minTypoLength] letters or more may also be one letter off: a letter
/// missing, extra, wrong, or swapped with the next one ("alce", "allice",
/// "alise" and "laice" all find "Alice"), which makes it a
/// [NameMatch.typo]. Case and accents don't count ("jose" finds "José").
/// Blank input matches everyone exactly.
NameMatch matchName(String name, String input) {
  final wanted = _words(input);
  if (wanted.isEmpty) {
    return NameMatch.exact;
  }
  final words = _words(name);
  var match = NameMatch.exact;
  for (final typed in wanted) {
    if (words.any((word) => word.startsWith(typed))) {
      continue;
    }
    if (typed.length < minTypoLength ||
        !words.any((word) => _startsWithTypo(word, typed))) {
      return NameMatch.none;
    }
    match = NameMatch.typo;
  }
  return match;
}

/// Whether [input] has no word to match, so that it matches every name.
bool matchesEveryone(String input) => _words(input).isEmpty;

/// Whether [typed] is one letter off the start of [word].
bool _startsWithTypo(String word, String typed) {
  for (var length = typed.length - 1; length <= typed.length + 1; length++) {
    if (length <= word.length &&
        _oneEditApart(word.substring(0, length), typed)) {
      return true;
    }
  }
  return false;
}

/// Whether [a] and [b] differ by at most one letter added, removed,
/// changed, or swapped with the next one.
bool _oneEditApart(String a, String b) {
  if (a.length == b.length) {
    final differ = [
      for (var i = 0; i < a.length; i++)
        if (a[i] != b[i]) i,
    ];
    return switch (differ) {
      [] || [_] => true,
      [final i, final j] => j == i + 1 && a[i] == b[j] && a[j] == b[i],
      _ => false,
    };
  }
  final (short, long) = a.length < b.length ? (a, b) : (b, a);
  if (long.length - short.length != 1) {
    return false;
  }
  var i = 0;
  while (i < short.length && short[i] == long[i]) {
    i++;
  }
  return short.substring(i) == long.substring(i + 1);
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
