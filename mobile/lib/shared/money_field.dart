import 'package:intl/intl.dart';

final _grouping = NumberFormat.decimalPattern('id_ID');

/// Ambil nilai integer dari teks nominal (buang titik ribuan & non-digit).
int moneyValue(String text) => int.tryParse(_digitsOnly(text)) ?? 0;

/// Nilai ke teks ber-format ribuan buat prefill controller. Kosong kalau <= 0.
String moneyText(num value) => value <= 0 ? '' : _grouping.format(value.round());

String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
