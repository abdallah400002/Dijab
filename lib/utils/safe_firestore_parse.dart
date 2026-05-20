/// Utilities for safely parsing Firestore data on web.
/// Avoids "Int64 accessor not supported by dart2js" errors when Firestore
/// returns numeric values that may use 64-bit representation internally.

/// Safely converts a Firestore value to int. Use instead of `value as int`
/// to avoid Int64 accessor errors on Flutter web (dart2js).
int safeInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
