String formatTnd(num amount) {
  final v = amount.toDouble();
  final fixed = v.toStringAsFixed(2);
  return '$fixed DT';
}
