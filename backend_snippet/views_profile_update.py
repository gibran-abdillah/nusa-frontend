"""
Update your UserProfileView so PATCH recalculates and saves daily targets.
Copy the relevant parts into your Django app (e.g. views.py or profiles/views.py).
"""

# Add at top of your views file:
# from .goals_calculator import compute_daily_targets  # or from your_app.goals_calculator

# Replace (or extend) your PATCH method like this:

"""
def patch(self, request, id):
    profile = self.get_object(id)
    serializer = UserProfileSerializer(profile, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()

    # Recompute and save daily targets from updated profile data
    w = profile.weight_kg or 70
    h = profile.height_cm or 170
    a = profile.age or 25
    activity = profile.activity_level or "moderate"
    goal = profile.weight_goal or "maintain"
    is_female = (profile.gender or "").lower() == "female"

    targets = compute_daily_targets(
        weight_kg=float(w),
        height_cm=float(h),
        age=int(a),
        activity_level=activity,
        weight_goal=goal,
        is_female=is_female,
    )
    profile.daily_calorie_target = targets["calories"]
    profile.daily_protein_target_g = targets["protein_g"]
    profile.daily_carbs_target_g = targets["carbs_g"]
    profile.daily_fat_target_g = targets["fat_g"]
    profile.save(update_fields=[
        "daily_calorie_target",
        "daily_protein_target_g",
        "daily_carbs_target_g",
        "daily_fat_target_g",
        "updated_at",
    ])

    serializer = UserProfileSerializer(profile)
    return success_response(data=serializer.data)
"""
