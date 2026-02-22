"""
Research-based daily targets calculator (Mifflin-St Jeor BMR, TDEE).
Use this in your Django backend so PATCH profile updates and persists daily_targets.
"""

# Activity multipliers for TDEE (TDEE = BMR × multiplier)
ACTIVITY_MULTIPLIERS = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "very_active": 1.725,
    "extra_active": 1.9,
}


def bmr(weight_kg: float, height_cm: float, age: int, is_female: bool) -> float:
    """Mifflin-St Jeor BMR (kcal/day)."""
    base = (10 * weight_kg) + (6.25 * height_cm) - (5 * age)
    return base + (-161 if is_female else 5)


def tdee(
    weight_kg: float,
    height_cm: float,
    age: int,
    activity_level: str,
    is_female: bool = False,
) -> float:
    """Total Daily Energy Expenditure (kcal/day)."""
    bmr_val = bmr(weight_kg, height_cm, age, is_female)
    mult = ACTIVITY_MULTIPLIERS.get(
        activity_level.strip().lower().replace(" ", "_"), 1.55
    )
    return bmr_val * mult


def target_calories(tdee_value: float, weight_goal: str) -> float:
    """Target calories from TDEE and weight goal."""
    goal = weight_goal.strip().lower()
    if goal == "lose":
        return max(1200.0, tdee_value - 500)
    if goal == "gain":
        return tdee_value + 300
    return tdee_value


def target_macros(
    calories: float,
    weight_kg: float,
    weight_goal: str,
) -> dict:
    """Return dict with calories, protein_g, carbs_g, fat_g (research-based split)."""
    goal = weight_goal.strip().lower()
    protein_per_kg = 1.8 if goal in ("lose", "gain") else 1.2
    protein_g = max(50, min(300, weight_kg * protein_per_kg))
    protein_kcal = protein_g * 4
    fat_pct = 0.25
    fat_kcal = calories * fat_pct
    fat_g = fat_kcal / 9
    carbs_kcal = calories - protein_kcal - fat_kcal
    carbs_g = max(0, min(500, carbs_kcal / 4))
    return {
        "calories": round(calories),
        "protein_g": round(protein_g, 1),
        "carbs_g": round(carbs_g, 1),
        "fat_g": round(fat_g, 1),
    }


def compute_daily_targets(
    weight_kg: float,
    height_cm: float,
    age: int,
    activity_level: str,
    weight_goal: str,
    is_female: bool = False,
) -> dict:
    """Compute daily_targets from profile fields (same logic as Flutter app)."""
    tdee_val = tdee(weight_kg, height_cm, age, activity_level, is_female)
    cal = target_calories(tdee_val, weight_goal)
    return target_macros(cal, weight_kg, weight_goal)
