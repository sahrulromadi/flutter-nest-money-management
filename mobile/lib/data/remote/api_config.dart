/// `10.0.2.2` = alias emulator Android buat localhost host machine (dev).
/// Ganti ke URL VPS beneran (https://...) pas backend udah di-deploy
/// (TECH_STACK.md §5, Caddy auto-HTTPS) — jangan lupa juga cabut
/// `android:usesCleartextTraffic="true"` di AndroidManifest.xml pas itu,
/// itu cuma buat http:// localhost dev sekarang.
const String kApiBaseUrl = 'http://10.0.2.2:3000';
