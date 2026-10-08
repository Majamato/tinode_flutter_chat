/// Up to two letters for an avatar: the first letters of the first two
/// words of [title].
String initialsOf(String title) => title
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
    .join();
