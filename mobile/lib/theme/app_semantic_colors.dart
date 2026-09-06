import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Warna semantik keuangan (income/expense/warning/danger) — tetap universal,
/// gak ikut tema, biar gak ambigu (docs/DESIGN.md #1).
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.danger,
  });

  final Color income;
  final Color expense;
  final Color warning;
  final Color danger;

  static const light = AppSemanticColors(
    income: AppColors.lightIncome,
    expense: AppColors.lightExpense,
    warning: AppColors.lightWarning,
    danger: AppColors.lightDanger,
  );

  static const dark = AppSemanticColors(
    income: AppColors.darkIncome,
    expense: AppColors.darkExpense,
    warning: AppColors.darkWarning,
    danger: AppColors.darkDanger,
  );

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? danger,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
