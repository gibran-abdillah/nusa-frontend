class ApiConstants {
  // Base URL for the REST API
  // You can change this to your local server (e.g. http://10.0.2.2:8000/api for Android emulator)
  // or your production server (e.g. https://api.yourdomain.com/v1)
  static const String baseUrl =
      'http://103.103.20.112:8002/api/v1'; // Placeholder, set later

  // Endpoints (as defined in plan.md)
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String scanPrepare = '/scan/prepare/';
  static const String scanAnalyze = '/scan/analyze/';
  static const String scanList = '/scan/';
  static const String logFood = '/logs/';
  static const String statsDaily = '/stats/daily/';
  static const String statsTrends = '/stats/trends/';
  static const String usersPath = '/users';
  // GET/PATCH /users/{id}/profile/

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
