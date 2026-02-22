class FoodPayload {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final Map<String, dynamic> per100g;

  FoodPayload({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.per100g = const {},
  });

  factory FoodPayload.fromJson(Map<String, dynamic> json) {
    return FoodPayload(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      imageUrl: json['image_url'] ?? '',
      per100g: json['per_100g'] ?? {},
    );
  }
}

class FoodLog {
  final String id;
  final FoodPayload food;
  final String mealType;
  final num servingWeightG;
  final Map<String, dynamic> calculated;
  final num healthScore;
  final String notes;
  final String loggedAt;

  FoodLog({
    required this.id,
    required this.food,
    required this.mealType,
    required this.servingWeightG,
    required this.calculated,
    required this.healthScore,
    required this.notes,
    required this.loggedAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'] ?? '',
      food: FoodPayload.fromJson(json['food'] ?? {}),
      mealType: json['meal_type'] ?? '',
      servingWeightG: json['serving_weight_g'] ?? 0,
      calculated: json['calculated'] ?? {},
      healthScore: json['health_score'] ?? 0,
      notes: json['notes'] ?? '',
      loggedAt: json['logged_at'] ?? '',
    );
  }
}

class DailySummary {
  final num totalCalories;
  final num totalProteinG;
  final num totalCarbsG;
  final num totalFatG;

  DailySummary({
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalCalories: json['total_calories'] ?? 0,
      totalProteinG: json['total_protein_g'] ?? 0,
      totalCarbsG: json['total_carbs_g'] ?? 0,
      totalFatG: json['total_fat_g'] ?? 0,
    );
  }
}

class FullDailySummary {
  final String period;
  final String date;
  final Map<String, dynamic> consumed;
  final Map<String, dynamic> targets;
  final Map<String, dynamic> progress;
  final num activeCaloriesBurned;

  FullDailySummary({
    required this.period,
    required this.date,
    required this.consumed,
    required this.targets,
    required this.progress,
    required this.activeCaloriesBurned,
  });

  factory FullDailySummary.fromJson(Map<String, dynamic> json) {
    return FullDailySummary(
      period: json['period'] ?? '',
      date: json['date'] ?? '',
      consumed: json['consumed'] ?? {},
      targets: json['targets'] ?? {},
      progress: json['progress'] ?? {},
      activeCaloriesBurned: json['active_calories_burned'] ?? 0,
    );
  }
}

/// User profile from GET /users/{id}/profile/
class UserProfile {
  final int? age;
  final String? gender;
  final num? heightCm;
  final num? weightKg;
  final num? targetWeightKg;
  final String? activityLevel;
  final String? weightGoal;
  final Map<String, dynamic> dailyTargets;

  UserProfile({
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.weightGoal,
    this.dailyTargets = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      heightCm: json['height_cm'] as num?,
      weightKg: json['weight_kg'] as num?,
      targetWeightKg: json['target_weight_kg'] as num?,
      activityLevel: json['activity_level'] as String?,
      weightGoal: json['weight_goal'] as String?,
      dailyTargets: json['daily_targets'] is Map
          ? Map<String, dynamic>.from(json['daily_targets'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (age != null) m['age'] = age;
    if (gender != null) m['gender'] = gender;
    if (heightCm != null) m['height_cm'] = heightCm;
    if (weightKg != null) m['weight_kg'] = weightKg;
    if (targetWeightKg != null) m['target_weight_kg'] = targetWeightKg;
    if (activityLevel != null) m['activity_level'] = activityLevel;
    if (weightGoal != null) m['weight_goal'] = weightGoal;
    return m;
  }
}

class TrendsData {
  final String period;
  final num totalCalories;
  final num avgCaloriesPerDay;
  final num changePct;
  final List<dynamic> chart;

  TrendsData({
    required this.period,
    required this.totalCalories,
    required this.avgCaloriesPerDay,
    required this.changePct,
    required this.chart,
  });

  factory TrendsData.fromJson(Map<String, dynamic> json) {
    return TrendsData(
      period: json['period'] ?? '',
      totalCalories: json['total_calories'] ?? 0,
      avgCaloriesPerDay: json['avg_calories_per_day'] ?? 0,
      changePct: json['change_pct'] ?? 0,
      chart: json['chart'] ?? [],
    );
  }
}

class ScanPrepareResponse {
  final String scanId;

  ScanPrepareResponse({required this.scanId});

  factory ScanPrepareResponse.fromJson(Map<String, dynamic> json) {
    return ScanPrepareResponse(scanId: json['scan_id'] ?? '');
  }
}
