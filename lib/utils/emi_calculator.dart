import 'dart:math';

class EmiCalculator {
  /// Standard reducing-balance EMI formula
  static double emi(double principal, double annualRate, int months) {
    if (annualRate == 0) return principal / months;
    final r = annualRate / 12 / 100;
    final p = pow(1 + r, months);
    return double.parse(((principal * r * p) / (p - 1)).toStringAsFixed(2));
  }

  static double totalPayable(double emiAmt, int months) =>
      double.parse((emiAmt * months).toStringAsFixed(2));

  static double totalInterest(double principal, double emiAmt, int months) =>
      double.parse(
          (totalPayable(emiAmt, months) - principal).toStringAsFixed(2));

  /// Full amortisation schedule
  static List<EmiRow> schedule(double principal, double annualRate, int months,
      DateTime startDate, int emiDayOfMonth) {
    final r      = annualRate / 12 / 100;
    final emiAmt = emi(principal, annualRate, months);
    final rows   = <EmiRow>[];
    double balance = principal;

    for (int i = 1; i <= months; i++) {
      final interest   = double.parse((balance * r).toStringAsFixed(2));
      final principalC = double.parse((emiAmt - interest).toStringAsFixed(2));
      final closing    = double.parse((balance - principalC).toStringAsFixed(2));

      final baseMonth = startDate.month + i;
      final due = DateTime(
        startDate.year + (baseMonth - 1) ~/ 12,
        ((baseMonth - 1) % 12) + 1,
        emiDayOfMonth,
      );

      rows.add(EmiRow(
        number:    i,
        dueDate:   due,
        emiAmount: emiAmt,
        principal: principalC,
        interest:  interest,
        opening:   balance,
        closing:   closing < 0 ? 0 : closing,
      ));
      balance = closing < 0 ? 0 : closing;
    }
    return rows;
  }
}

class EmiRow {
  final int      number;
  final DateTime dueDate;
  final double   emiAmount;
  final double   principal;
  final double   interest;
  final double   opening;
  final double   closing;

  const EmiRow({
    required this.number,
    required this.dueDate,
    required this.emiAmount,
    required this.principal,
    required this.interest,
    required this.opening,
    required this.closing,
  });
}
