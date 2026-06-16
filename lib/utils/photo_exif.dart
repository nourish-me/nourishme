import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';

// Reads the DateTimeOriginal tag out of a JPEG byte buffer (Task #98).
// Returns null when:
//   - the file has no EXIF block (e.g. screenshots, edited PNGs)
//   - the tag is missing or unparseable
//   - the captured date is more than 30 days old (probably a stock image
//     or accidentally picked old screenshot - we don't want to silently
//     anchor a meal to last month)
//   - the captured date is in the future (clock skew)
//
// Best-effort: any exception in the EXIF library degrades to null so
// the caller can safely fall back to DateTime.now() without try-catch.
//
// EXIF format quirks the parser handles:
//   - DateTimeOriginal is formatted "YYYY:MM:DD HH:MM:SS" (note the
//     colons in the date part - intentional EXIF spec)
//   - some cameras populate DateTime (file mod time) but not
//     DateTimeOriginal; we read DateTimeOriginal first, then fall back
//     to DateTimeDigitized, then DateTime
Future<DateTime?> readPhotoExifTimestamp(Uint8List bytes) async {
  try {
    final tags = await readExifFromBytes(bytes);
    if (tags.isEmpty) return null;
    final raw = tags['EXIF DateTimeOriginal']?.printable ??
        tags['EXIF DateTimeDigitized']?.printable ??
        tags['Image DateTime']?.printable;
    if (raw == null || raw.isEmpty) return null;
    final parsed = _parseExifDate(raw);
    if (parsed == null) return null;
    final now = DateTime.now();
    if (parsed.isAfter(now.add(const Duration(minutes: 5)))) {
      // Future timestamp: clock skew on the device. Discard rather than
      // shift the meal into tomorrow.
      return null;
    }
    if (now.difference(parsed).inDays > 30) {
      // More than a month old: probably a stock photo or an accidental
      // pick from the gallery. Better to default to "now" than to
      // anchor a meal to last month and confuse the user.
      return null;
    }
    return parsed;
  } catch (e) {
    debugPrint('readPhotoExifTimestamp: $e');
    return null;
  }
}

DateTime? _parseExifDate(String raw) {
  // EXIF DateTimeOriginal canonical format: "YYYY:MM:DD HH:MM:SS"
  // (date part uses colons, not dashes - that's the spec).
  final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$')
      .firstMatch(raw.trim());
  if (m == null) return null;
  final year = int.tryParse(m.group(1)!);
  final month = int.tryParse(m.group(2)!);
  final day = int.tryParse(m.group(3)!);
  final hour = int.tryParse(m.group(4)!);
  final minute = int.tryParse(m.group(5)!);
  final second = int.tryParse(m.group(6)!);
  if (year == null ||
      month == null ||
      day == null ||
      hour == null ||
      minute == null ||
      second == null) {
    return null;
  }
  try {
    return DateTime(year, month, day, hour, minute, second);
  } catch (_) {
    return null;
  }
}
