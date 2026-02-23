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

  /// Approximate kcal to lose or gain 1 kg body weight (research range ~7000–7800).
  static const double kcalPerKgBodyWeight = 7700;

  /// Estimated days to reach target weight at the given daily calorie target.
  /// Returns null for "maintain" or when estimate is not meaningful (e.g. no deficit/surplus).
  static int? estimatedDaysToTargetWeight({
    required num currentWeightKg,
    required num targetWeightKg,
    required double targetCaloriesPerDay,
    required double tdeeValue,
    required String weightGoal,
  }) {
    final goal = weightGoal.toLowerCase();
    if (goal == 'maintain') return null;

    if (goal == 'lose') {
      final kgToLose = currentWeightKg.toDouble() - targetWeightKg.toDouble();
      if (kgToLose <= 0) return null;
      final dailyDeficit = tdeeValue - targetCaloriesPerDay;
      if (dailyDeficit <= 0) return null;
      final days = (kgToLose * kcalPerKgBodyWeight) / dailyDeficit;
      return days.round().clamp(1, 365 * 2); // cap for display sanity
    }

    // gain
    final kgToGain = targetWeightKg.toDouble() - currentWeightKg.toDouble();
    if (kgToGain <= 0) return null;
    final dailySurplus = targetCaloriesPerDay - tdeeValue;
    if (dailySurplus <= 0) return null;
    final days = (kgToGain * kcalPerKgBodyWeight) / dailySurplus;
    return days.round().clamp(1, 365 * 2);
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
