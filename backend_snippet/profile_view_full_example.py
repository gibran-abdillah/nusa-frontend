"""
Full example: UserProfileView with PATCH that updates profile and recomputes daily_targets.
Place goals_calculator.py in the same app and adjust imports / success_response to match your project.
"""

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

# Adjust these imports to your project
# from .models import CustomUser  # or UserProfile
# from .serializers import UserProfileSerializer
# from .goals_calculator import compute_daily_targets
# from your_utils import success_response


def compute_daily_targets(weight_kg, height_cm, age, activity_level, weight_goal, is_female=False):
    """Inline copy of goals_calculator.compute_daily_targets if you prefer not to add a file."""
    ACTIVITY = {"sedentary": 1.2, "light": 1.375, "moderate": 1.55, "very_active": 1.725, "extra_active": 1.9}
    level = (activity_level or "moderate").strip().lower().replace(" ", "_")
    mult = ACTIVITY.get(level, 1.55)
    base = (10 * float(weight_kg)) + (6.25 * float(height_cm)) - (5 * int(age))
    bmr = base + (-161 if is_female else 5)
    tdee_val = bmr * mult
    goal = (weight_goal or "maintain").strip().lower()
    if goal == "lose":
        cal = max(1200.0, tdee_val - 500)
    elif goal == "gain":
        cal = tdee_val + 300
    else:
        cal = tdee_val
    protein_per_kg = 1.8 if goal in ("lose", "gain") else 1.2
    protein_g = max(50, min(300, float(weight_kg) * protein_per_kg))
    fat_g = (cal * 0.25) / 9
    carbs_g = max(0, (cal - protein_g * 4 - fat_g * 9) / 4)
    return {
        "calories": round(cal),
        "protein_g": round(protein_g, 1),
        "carbs_g": round(carbs_g, 1),
        "fat_g": round(fat_g, 1),
    }


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, user_id):
        user = get_object_or_404(CustomUser, id=user_id)
        if self.request.user.role != "admin" and str(self.request.user.id) != str(user.id):
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied()
        return user.profile

    def get(self, request, id):
        profile = self.get_object(id)
        serializer = UserProfileSerializer(profile)
        return success_response(data=serializer.data)

    def patch(self, request, id):
        profile = self.get_object(id)
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        # Recompute and save daily targets so GET and response return correct values
        w = getattr(profile, "weight_kg", None) or 70
        h = getattr(profile, "height_cm", None) or 170
        a = getattr(profile, "age", None) or 25
        activity = getattr(profile, "activity_level", None) or "moderate"
        goal = getattr(profile, "weight_goal", None) or "maintain"
        gender = getattr(profile, "gender", None) or ""
        is_female = str(gender).lower() == "female"

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
        profile.save(
            update_fields=[
                "daily_calorie_target",
                "daily_protein_target_g",
                "daily_carbs_target_g",
                "daily_fat_target_g",
                "updated_at",
            ]
        )

        serializer = UserProfileSerializer(profile)
        return success_response(data=serializer.data)
