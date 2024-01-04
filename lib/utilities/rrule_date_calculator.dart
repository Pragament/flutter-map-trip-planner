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
