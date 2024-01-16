import 'package:rrule/rrule.dart';

class RecurringDateCalculator {
  String rrule;

  RecurringDateCalculator(this.rrule);

  List<DateTime> calculateRecurringDates() {
    List<DateTime> recurringDates = [];

    RecurrenceRule rule = RecurrenceRule.fromString(rrule);
    Iterable<DateTime> dates = rule.getInstances(start: DateTime.now().toUtc());
    recurringDates.addAll(dates.take(10));

    return recurringDates;
  }
}

String getWeekDay(int weekDay) {
  switch (weekDay) {
    case 1:
      return 'MO';
    case 2:
      return 'TU';
    case 3:
      return 'WE';
    case 4:
      return 'TH';
    case 5:
      return 'FR';
    case 6:
      return 'SA';
    case 7:
      return 'SU';
    default:
      return 'SU';
  }
}

