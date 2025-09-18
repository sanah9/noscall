
extension DatatimeExtension on DateTime {
  bool isSameDay(DateTime date) {
    return year == date.year &&
        month == date.month &&
        day == date.day;
  }
}