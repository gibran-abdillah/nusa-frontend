/// Research-based goal calculation (Mifflin-St Jeor BMR, TDEE, macro split).
/// Used when API profile has no daily_targets or as fallback.

class GoalsCalculator {
  /// Activity multipliers (TDEE = BMR × multiplier)
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'lightly_active': 1.375,
    'moderate': 1.55,
    'very_active': 1.725,
    'extra_active': 1.9,
  };

  /// Mifflin-St Jeor BMR (kcal/day)
  /// Men: (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
  /// Women: (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
  static double bmr({
    required num weightKg,
    required num heightCm,
    required int age,
    bool isFemale = false,
  }) {
    final w = weightKg.toDouble();
    final h = heightCm.toDouble();
    final base = (10 * w) + (6.25 * h) - (5 * age);
    return base + (isFemale ? -161 : 5);
  }

  /// TDEE (Total Daily Energy Expenditure) in kcal/day
  static double tdee({
    required num weightKg,
    required num heightCm,
    required int age,
    required String activityLevel,
    bool isFemale = false,
  }) {
    final b = bmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      isFemale: isFemale,
    );
    final mult =
        activityMultipliers[activityLevel.toLowerCase().replaceAll(' ', '_')] ??
        1.55;
    return b * mult;
  }

  /// Target calories based on weight goal (lose / maintain / gain)
  /// Lose: -500 kcal/day (~0.5 kg/week), Gain: +300 kcal/day
  static double targetCalories({
    required double tdeeValue,
    required String weightGoal,
  }) {
    switch (weightGoal.toLowerCase()) {
      case 'lose':
        return (tdeeValue - 500).clamp(1200.0, double.infinity);
      case 'gain':
        return tdeeValue + 300;
      case 'maintain':
      default:
        return tdeeValue;
    }
  }

  /// Macro split: protein 30%, carbs 45%, fat 25% (common research-based default).
  /// Protein at least 1.6 g/kg for weight loss, 1.2 for maintain.
  static Map<String, double> targetMacros({
    required double calories,
    required num weightKg,
    required String weightGoal,
    double proteinPct = 0.30,
    double carbsPct = 0.45,
    double fatPct = 0.25,
  }) {
    final w = weightKg.toDouble();
    // Protein: at least 1.6 g/kg for lose, 1.2 for maintain, 1.6 for gain
    final proteinPerKg = weightGoal.toLowerCase() == 'lose'
        ? 1.8
        : (weightGoal.toLowerCase() == 'gain' ? 1.8 : 1.2);
    final proteinG = (w * proteinPerKg).clamp(50.0, 300.0);
    final proteinKcal = proteinG * 4;
    final remainingKcal = calories - proteinKcal;
    // Fat: 25% of total, min 0.5 g/kg
    final fatKcal = calories * fatPct;
    final fatG = fatKcal / 9;
    final carbsKcal = remainingKcal - fatKcal;
    final carbsG = (carbsKcal / 4).clamp(0.0, 500.0);
    return {
      'calories': calories.roundToDouble(),
      'protein_g': proteinG.roundToDouble(),
      'carbs_g': carbsG.roundToDouble(),
      'fat_g': fatG.roundToDouble(),
    };
  }

  /// Full calculation: TDEE → target calories → macros
  static Map<String, double> calculateDailyTargets({
    required num weightKg,
    required num heightCm,
    required int age,
    required String activityLevel,
    required String weightGoal,
    bool isFemale = false,
  }) {
    final tdeeVal = tdee(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activityLevel: activityLevel,
      isFemale: isFemale,
    );
    final cal = targetCalories(tdeeValue: tdeeVal, weightGoal: weightGoal);
    return targetMacros(
      calories: cal,
      weightKg: weightKg,
      weightGoal: weightGoal,
    );
  }
}
