/// Where the app talks to the Laravel backend.
///
/// Default is the live site. To point a build somewhere else (e.g. a staging copy):
///   flutter run --dart-define=API_BASE=https://staging.example.com/api/v1
/// Android emulator talking to `php artisan serve` on your computer:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api/v1
const String kApiBase = String.fromEnvironment('API_BASE', defaultValue: 'https://uttaranchal.vads.ca/api/v1');

/// How often the staff "Shop orders" screen refreshes on its own.
const Duration kStaffRefreshEvery = Duration(seconds: 30);
