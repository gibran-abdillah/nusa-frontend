# NUSA Nutrition API Documentation

## Base Information
- **Base URL:** `/api/v1/`
- **Content-Type:** `application/json`
- **Authentication:** JWT Bearer Token (`Authorization: Bearer <access_token>`)
- **Interactive Documentation:** Available at `/api/docs/` (Swagger UI) and `/api/redoc/` when running the server locally.

---

## Standard Response Format

Every API response follows a strict standardized structure:

### Success Response (2XX)
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }, // Can be an object, array, or null
  "meta": { ... }, // Used for pagination or extra metadata, otherwise null
  "error": null
}
```

### Error Response (4XX, 5XX)
```json
{
  "success": false,
  "message": "Validation failed",
  "data": null,
  "meta": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "detail": {
      "field_name": ["Error detail message"]
    }
  }
}
```

### Pagination Meta Format
```json
"meta": {
  "page": 1,
  "per_page": 20,
  "total": 150,
  "total_pages": 8
}
```

---

## Auth Endpoints (`/api/v1/auth/`)

### 1. Register
- **Endpoint:** `POST /auth/register/`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "strongpassword123",
    "password_confirm": "strongpassword123"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Registration successful",
    "data": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "expires_in": 3600,
      "user": {
        "id": "uuid",
        "name": "John Doe",
        "email": "john@example.com",
        "role": "user"
      }
    },
    "meta": null,
    "error": null
  }
  ```

### 2. Login
- **Endpoint:** `POST /auth/login/`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "email": "john@example.com",
    "password": "strongpassword123"
  }
  ```
- **Response (200 OK):** *(Same as Register response)*

### 3. Token Refresh
- **Endpoint:** `POST /auth/refresh/`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "refresh_token": "eyJ..."
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "OK",
    "data": {
      "access_token": "eyJ_new_access_token...",
      "expires_in": 3600
    },
    ...
  }
  ```

### 4. Logout
- **Endpoint:** `POST /auth/logout/`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "refresh_token": "eyJ..."
  }
  ```
- **Response (200 OK):** `message: "Logged out successfully"`

---

## User Endpoints (`/api/v1/users/`)

### 1. List Users
- **Endpoint:** `GET /users/`
- **Auth Required:** Yes (Admin only)
- **Query Params:** `?page=1&per_page=20&search=john&role=user`
- **Response (200 OK):** Paginated list of users.

### 2. Get User Detail
- **Endpoint:** `GET /users/{id}/`
- **Auth Required:** Yes (Self or Admin)
- **Response (200 OK):** CustomUser object details.

### 3. Update User
- **Endpoint:** `PATCH /users/{id}/`
- **Auth Required:** Yes (Self or Admin)
- **Request Body (User):** `{"name": "New Name", "avatar_url": "url"}`
- **Request Body (Admin):** Can also update `"role"`, `"is_active"`.
- **Response (200 OK):** Updated user object.

### 4. Get User Profile
- **Endpoint:** `GET /users/{id}/profile/`
- **Auth Required:** Yes (Self or Admin)
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "age": 25,
      "gender": "male",
      "height_cm": 175.0,
      "weight_kg": 75.0,
      "target_weight_kg": 70.0,
      "activity_level": "moderate",
      "weight_goal": "lose",
      "daily_targets": {
        "calories": 2000,
        "protein_g": 150.0,
        "carbs_g": 200.0,
        "fat_g": 60.0
      }
    }
  }
  ```

### 5. Update User Profile
- **Endpoint:** `PATCH /users/{id}/profile/`
- **Auth Required:** Yes (Self or Admin)
- **Request Body:** Any profile fields (e.g. `age`, `weight_kg`, `activity_level`).
- **Response (200 OK):** Updated profile object.

### 6. Get Daily Scan Quota
- **Endpoint:** `GET /users/{id}/quota/`
- **Auth Required:** Yes (Self or Admin)
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "plan": "Free",
      "scans_used": 1,
      "scans_limit": 3,
      "scans_remaining": 2,
      "resets_at": "2024-11-21T00:00:00Z",
      "is_grace_period": false
    }
  }
  ```

---

## Foods Endpoints (`/api/v1/foods/`)

### 1. List Foods
- **Endpoint:** `GET /foods/`
- **Auth Required:** Yes
- **Query Params:** `?page=1&search=apple&source=manual`
- **Response (200 OK):** Paginated list of foods. Users see verified foods + their own created foods.

### 2. Create Custom Food
- **Endpoint:** `POST /foods/`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "name": "My Custom Meal",
    "brand": "Homemade",
    "calories_per_100g": 150.0,
    "protein_per_100g": 10.0,
    "carbs_per_100g": 20.0,
    "fat_per_100g": 5.0
  }
  ```
- **Response (201 Created):** Created food object (automatically assigned `source="manual"`).

### 3. Get Food Detail
- **Endpoint:** `GET /foods/{id}/`
- **Auth Required:** Yes

### 4. Update Food
- **Endpoint:** `PATCH /foods/{id}/`
- **Auth Required:** Yes (Creator if not verified, or Admin)

---

## Scan Endpoints (`/api/v1/scan/`)

### 1. Prepare Scan (Upload Image)
- **Endpoint:** `POST /scan/prepare/`
- **Auth Required:** Yes
- **Content-Type:** `multipart/form-data`
- **Request Parameters:**
  - `image`: The image file payload to be uploaded (required).
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Image uploaded successfully",
    "data": {
      "scan_id": "uuid",
      "upload_url": "http://127.0.0.1:8000/media/scans/...",
      "expires_in": null
    }
  }
  ```
- **Error (429 Rate Limit):** If user quota is exceeded.

### 2. Analyze Scan (Trigger AI)
- **Endpoint:** `POST /scan/analyze/`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "scan_id": "uuid",
    "meal_type": "lunch"
  }
  ```
- **Response (200 OK):** Returns the final scan session data containing AI confidence, Food details, and the created FoodLog.
- **Error (422 Unprocessable Entity):** If AI confidence is below 0.70.

### 3. List Scans
- **Endpoint:** `GET /scan/`
- **Auth Required:** Yes

### 4. Get Scan Detail
- **Endpoint:** `GET /scan/{id}/`
- **Auth Required:** Yes

---

## Logs Endpoints (`/api/v1/logs/`)

### 1. List Logs
- **Endpoint:** `GET /logs/`
- **Auth Required:** Yes
- **Query Params:** `?date=YYYY-MM-DD` or `?date_from=...&date_to=...`
- **Response (200 OK):** Returns paginated logs. If `?date` is provided, `meta.daily_summary` calculates the total macros consumed for that day.

### 2. Create Log Manually
- **Endpoint:** `POST /logs/`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "food_id": "uuid",
    "meal_type": "breakfast",
    "serving_weight_g": 250.0,
    "notes": "Extra large portion"
  }
  ```
- **Response (201 Created):** Creates log and calculates exact nutrients based on the food's per_100g configuration.

### 3. Update Log
- **Endpoint:** `PATCH /logs/{id}/`
- **Auth Required:** Yes (Owner or Admin)
- **Request Body:** `{"serving_weight_g": 300.0}`
- **Response (200 OK):** Recalculates nutrients instantly.

### 4. Delete Log
- **Endpoint:** `DELETE /logs/{id}/`
- **Auth Required:** Yes

---

## Stats Endpoints (`/api/v1/stats/`)

### 1. Daily/Weekly/Monthly Summary
- **Endpoint:** `GET /stats/summary/`
- **Auth Required:** Yes
- **Query Params:** `?period=daily` (default) & `?date=YYYY-MM-DD`
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "period": "daily",
      "date": "2024-11-20",
      "consumed": {
        "calories": 1250.0,
        "protein_g": 75.0,
        "carbs_g": 135.0,
        "fat_g": 40.0
      },
      "targets": {
        "calories": 2500,
        "protein_g": 188.0,
        "carbs_g": 281.0,
        "fat_g": 69.0
      },
      "progress": {
        "calories_pct": 50.0,
        "protein_pct": 39.9,
        "carbs_pct": 48.0,
        "fat_pct": 58.0
      }
    }
  }
  ```

### 2. Trends Chart
- **Endpoint:** `GET /stats/trends/`
- **Auth Required:** Yes
- **Query Params:** `?period=weekly|monthly|custom` & `?date_from=...&date_to=...`
- **Response (200 OK):** Returns an array `chart` mapping date to aggregated calories/macros for charting libraries.
