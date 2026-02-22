import '../models/api_models.dart';

class MockData {
  static final FoodLog logBurger = FoodLog(
    id: "log-1",
    food: FoodPayload(
      id: "food-1",
      name: "Burger",
      brand: "McDonald's",
      imageUrl:
          "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80&w=800",
      per100g: {"calories": 295, "protein_g": 17, "carbs_g": 24, "fat_g": 14},
    ),
    mealType: "lunch",
    servingWeightG: 200,
    calculated: {"calories": 500, "protein_g": 25, "carbs_g": 18, "fat_g": 22},
    healthScore: 6,
    notes: "Too much calories in one meal, watch out",
    loggedAt: "2024-11-20T09:20:00Z",
  );

  static final FoodLog logNasiPadang = FoodLog(
    id: "log-2",
    food: FoodPayload(
      id: "food-2",
      name: "Nasi Padang",
      brand: "RM Padang",
      imageUrl:
          "https://images.unsplash.com/photo-1572222718104-e3c660f7e4a7?auto=format&fit=crop&q=80&w=800",
    ),
    mealType: "lunch",
    servingWeightG: 300,
    calculated: {"calories": 720, "protein_g": 25, "carbs_g": 18, "fat_g": 22},
    healthScore: 5,
    notes: "",
    loggedAt: "2024-11-20T09:20:00Z",
  );

  static final DailySummary dailySummary = DailySummary(
    totalCalories: 1250,
    totalProteinG: 75,
    totalCarbsG: 135,
    totalFatG: 40,
  );

  static final FullDailySummary fullSummary = FullDailySummary(
    period: "daily",
    date: "2024-11-20",
    consumed: {"calories": 1250, "protein_g": 75, "carbs_g": 135, "fat_g": 40},
    targets: {"calories": 2500, "protein_g": 188, "carbs_g": 281, "fat_g": 69},
    progress: {
      "calories_pct": 50,
      "protein_pct": 40,
      "carbs_pct": 48,
      "fat_pct": 58,
    },
    activeCaloriesBurned: 420,
  );

  static TrendsData get trendsMonthly => TrendsData(
    period: "monthly",
    totalCalories: 61050,
    avgCaloriesPerDay: 2035,
    changePct: 8,
    chart: [
      {
        "date": "1",
        "calories": 1800,
        "protein_g": 120,
        "carbs_g": 220,
        "fat_g": 65,
      },
      {
        "date": "5",
        "calories": 1900,
        "protein_g": 130,
        "carbs_g": 240,
        "fat_g": 70,
      },
      {
        "date": "10",
        "calories": 2300,
        "protein_g": 150,
        "carbs_g": 250,
        "fat_g": 80,
      },
      {
        "date": "15",
        "calories": 2100,
        "protein_g": 130,
        "carbs_g": 210,
        "fat_g": 60,
      },
      {
        "date": "20",
        "calories": 2500,
        "protein_g": 160,
        "carbs_g": 270,
        "fat_g": 85,
      },
      {
        "date": "25",
        "calories": 2400,
        "protein_g": 155,
        "carbs_g": 260,
        "fat_g": 80,
      },
      {
        "date": "30",
        "calories": 2600,
        "protein_g": 170,
        "carbs_g": 280,
        "fat_g": 90,
      },
    ],
  );

  static TrendsData get trendsWeekly => TrendsData(
    period: "weekly",
    totalCalories: 14245,
    avgCaloriesPerDay: 2035,
    changePct: 3,
    chart: [
      {
        "date": "1", // monday
        "calories": 1800,
        "protein_g": 120,
        "carbs_g": 220,
        "fat_g": 65,
      },
      {
        "date": "2", // tuesday
        "calories": 1950,
        "protein_g": 140,
        "carbs_g": 220,
        "fat_g": 70,
      },
      {
        "date": "3", // wed
        "calories": 2100,
        "protein_g": 150,
        "carbs_g": 230,
        "fat_g": 75,
      },
      {
        "date": "4", // thu
        "calories": 1850,
        "protein_g": 125,
        "carbs_g": 210,
        "fat_g": 60,
      },
      {
        "date": "5", // fri
        "calories": 2000,
        "protein_g": 135,
        "carbs_g": 240,
        "fat_g": 65,
      },
      {
        "date": "6", // sat
        "calories": 2245,
        "protein_g": 155,
        "carbs_g": 260,
        "fat_g": 80,
      },
      {
        "date": "7", // sun
        "calories": 2300,
        "protein_g": 160,
        "carbs_g": 250,
        "fat_g": 85,
      },
    ],
  );

  static TrendsData get trendsCustom => TrendsData(
    period: "custom",
    totalCalories: 12000,
    avgCaloriesPerDay: 1500,
    changePct: -5,
    chart: [
      {
        "date": "1",
        "calories": 1400,
        "protein_g": 100,
        "carbs_g": 180,
        "fat_g": 50,
      },
      {
        "date": "2",
        "calories": 1500,
        "protein_g": 110,
        "carbs_g": 190,
        "fat_g": 55,
      },
      {
        "date": "3",
        "calories": 1600,
        "protein_g": 120,
        "carbs_g": 200,
        "fat_g": 60,
      },
      {
        "date": "4",
        "calories": 1300,
        "protein_g": 90,
        "carbs_g": 170,
        "fat_g": 45,
      },
      {
        "date": "5",
        "calories": 1550,
        "protein_g": 115,
        "carbs_g": 195,
        "fat_g": 55,
      },
      {
        "date": "6",
        "calories": 1650,
        "protein_g": 125,
        "carbs_g": 205,
        "fat_g": 60,
      },
      {
        "date": "7",
        "calories": 1700,
        "protein_g": 130,
        "carbs_g": 210,
        "fat_g": 65,
      },
      {
        "date": "8",
        "calories": 1300,
        "protein_g": 90,
        "carbs_g": 170,
        "fat_g": 45,
      },
    ],
  );
}
