import '../../l10n/gen/app_localizations.dart';

typedef Validator = String? Function(String?);

class Validators {
  const Validators._();

  static const minPasswordLength = 6;
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static Validator required(AppLocalizations l10n) => (value) =>
      (value == null || value.trim().isEmpty) ? l10n.validationRequired : null;

  static Validator email(AppLocalizations l10n) => (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return l10n.validationRequired;
        return _email.hasMatch(v) ? null : l10n.validationEmail;
      };

  static Validator password(AppLocalizations l10n) => (value) {
        final v = value ?? '';
        if (v.isEmpty) return l10n.validationRequired;
        return v.length < minPasswordLength
            ? l10n.validationPasswordShort(minPasswordLength)
            : null;
      };

  static Validator confirmPassword(
    AppLocalizations l10n,
    String Function() original,
  ) =>
      (value) {
        if (value == null || value.isEmpty) return l10n.validationRequired;
        return value == original() ? null : l10n.validationPasswordMismatch;
      };
}
