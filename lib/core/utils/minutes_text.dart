import '../../l10n/gen/app_localizations.dart';

/// Audiobook positions and lengths as text: "11 h 30 min" to show, "11:30"
/// to type.
abstract final class MinutesText {
  static String format(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l10n.durationM(m);
    return m == 0 ? l10n.durationH(h) : l10n.durationHm(h, m);
  }

  /// "11:30" for editing.
  static String edit(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  static final _hm = RegExp(r'^(\d{1,3})\s*[:.h]\s*(\d{1,2})\s*(min)?$');
  static final _m = RegExp(r'^(\d{1,5})\s*(min)?$');

  /// Reads "11:30", "11.30", "11h30" or plain minutes ("690"); null when
  /// it is not a length.
  static int? parse(String text) {
    final value = text.trim().toLowerCase();
    final hm = _hm.firstMatch(value);
    if (hm != null) {
      final minutes = int.parse(hm[2]!);
      if (minutes > 59) return null;
      return int.parse(hm[1]!) * 60 + minutes;
    }
    final m = _m.firstMatch(value);
    return m == null ? null : int.parse(m[1]!);
  }
}
