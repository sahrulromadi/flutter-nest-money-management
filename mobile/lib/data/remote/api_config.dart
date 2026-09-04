/// Base URL backend API.
///
/// Default `http://localhost:3000` — jalan buat emulator DAN HP fisik selama
/// `adb reverse tcp:3000 tcp:3000` udah dijalanin (forward port device ->
/// localhost PC lewat kabel/adb).
///
/// Override tanpa ubah kode:
///   flutter run --dart-define=API_BASE_URL=http://192.168.31.8:3000
///
/// Pas backend udah di-deploy: --dart-define=API_BASE_URL=https://api.domain
/// (dan cabut `android:usesCleartextTraffic="true"` di AndroidManifest.xml).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

/// Timeout HTTP — biar gagal cepet & keliatan errornya, bukan spinner
/// muter selamanya kalau backend ga kejangkau.
const Duration kApiConnectTimeout = Duration(seconds: 8);
const Duration kApiReceiveTimeout = Duration(seconds: 15);
