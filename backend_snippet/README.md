# Backend: Update profile and persist daily targets

So that when the Flutter app sends a PATCH with `age`, `height_cm`, `weight_kg`, `target_weight_kg`, `activity_level`, `weight_goal`, your Django backend:

1. Saves those fields to `UserProfile`.
2. Recomputes `daily_calorie_target`, `daily_protein_target_g`, `daily_carbs_target_g`, `daily_fat_target_g` (same formulas as the app) and saves them.
3. Returns the updated profile (including `daily_targets`) in the response.

## 1. Copy the calculator

- Copy `goals_calculator.py` into your Django app (e.g. `yourapp/services/goals_calculator.py` or next to your `views.py`).

## 2. Update your PATCH view

In the view that handles `PATCH /users/{id}/profile/` (e.g. `UserProfileView.patch`):

- After `serializer.save()`, reload the profile from DB (or use the updated instance), then:
  - Call `compute_daily_targets(weight_kg, height_cm, age, activity_level, weight_goal, is_female)` with the profile’s current values.
  - Set on the profile:
    - `daily_calorie_target = targets["calories"]`
    - `daily_protein_target_g = targets["protein_g"]`
    - `daily_carbs_target_g = targets["carbs_g"]`
    - `daily_fat_target_g = targets["fat_g"]`
  - Save the profile (e.g. `profile.save(update_fields=[...])`).
- Return the response with the serialized profile (so `daily_targets` in the response are up to date).

See `views_profile_update.py` for a full PATCH example you can adapt.

## 3. Frontend payload (already sent by Flutter)

The app already sends:

- `age`, `height_cm`, `weight_kg`, `target_weight_kg`, `activity_level`, `weight_goal`

All snake_case. No change needed on the frontend for the backend to update and persist data.
