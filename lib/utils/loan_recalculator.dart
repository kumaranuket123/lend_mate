import 'dart:math';
import 'emi_calculator.dart';

class RecalcResult {
  /// New EMI rows from the next unpaid instalment onward
  final List<EmiRow> newSchedule;

  /// Reduce-tenure: same EMI, fewer months
  final int? newTenureMonths;

  /// Reduce-interest: same months, lower EMI
  final double? newEmiAmount;

  final double newRemainingPrincipal;
  final double interestSaved;

  const RecalcResult({
    required this.newSchedule,
    this.newTenureMonths,
    this.newEmiAmount,
    required this.newRemainingPrincipal,
    required this.interestSaved,
  });
}

class LoanRecalculator {
  /// Call this after an extra payment is recorded.
  ///
  /// [remainingPrincipal] – balance BEFORE extra payment
  /// [extraAmount]        – the extra amount paid
  /// [annualRate]         – original interest rate % p.a.
  /// [remainingMonths]    – months left BEFORE extra payment
  /// [originalEmiAmount]  – current EMI
  /// [nextEmiDate]        – date of the next due EMI
  /// [emiDayOfMonth]      – fixed day of month for EMIs
  /// [mode]               – 'reduce_tenure' | 'reduce_interest'
  static RecalcResult recalculate({
    required double   remainingPrincipal,
    required double   extraAmount,
    required double   annualRate,
    required int      remainingMonths,
    required double   originalEmiAmount,
    required DateTime nextEmiDate,
    required int      emiDayOfMonth,
    required String   mode,
  }) {
    final newPrincipal = remainingPrincipal - extraAmount;

    if (mode == 'reduce_tenure') {
      final newMonths = _monthsToClose(
          newPrincipal, annualRate, originalEmiAmount);
      final oldTotalInterest =
          originalEmiAmount * remainingMonths - remainingPrincipal;
      final newTotalInterest =
          originalEmiAmount * newMonths - newPrincipal;
      final saved = (oldTotalInterest - newTotalInterest)
          .clamp(0, double.infinity)
          .toDouble();

      final schedule = EmiCalculator.schedule(
        newPrincipal, annualRate, newMonths,
        _monthBefore(nextEmiDate), emiDayOfMonth,
      );

      return RecalcResult(
        newSchedule:           schedule,
        newTenureMonths:       newMonths,
        newRemainingPrincipal: newPrincipal,
        interestSaved:         double.parse(saved.toStringAsFixed(2)),
      );
    } else {
      final newEmi = EmiCalculator.emi(
          newPrincipal, annualRate, remainingMonths);
      final oldTotalInterest =
          originalEmiAmount * remainingMonths - remainingPrincipal;
      final newTotalInterest = newEmi * remainingMonths - newPrincipal;
      final saved = (oldTotalInterest - newTotalInterest)
          .clamp(0, double.infinity)
          .toDouble();

      final schedule = EmiCalculator.schedule(
        newPrincipal, annualRate, remainingMonths,
        _monthBefore(nextEmiDate), emiDayOfMonth,
      );

      return RecalcResult(
        newSchedule:           schedule,
        newEmiAmount:          newEmi,
        newRemainingPrincipal: newPrincipal,
        interestSaved:         double.parse(saved.toStringAsFixed(2)),
      );
    }
  }

  static int _monthsToClose(
      double principal, double annualRate, double emiAmt) {
    if (annualRate == 0) return (principal / emiAmt).ceil();
    final r   = annualRate / 12 / 100;
    final val = 1 - (principal * r / emiAmt);
    if (val <= 0) return 1;
    return (-log(val) / log(1 + r)).ceil();
  }

  static DateTime _monthBefore(DateTime date) =>
      DateTime(date.year, date.month - 1, date.day);
}
