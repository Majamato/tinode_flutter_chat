/// [bytes] for people: `512 B`, `1.5 KB`, `32 MB`.
String fileSizeLabel(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 || value >= 10 || value == value.roundToDouble()
      ? 0
      : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
