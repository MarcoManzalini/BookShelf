---
name: add-l10n-string
description: Add or change a user-facing string. Use whenever UI text is added or edited — writes the key to both lib/l10n/app_it.arb and app_en.arb with matching placeholders, then runs flutter gen-l10n.
---

# Add a localized string

User-facing text is never hard-coded in widgets. Every string lives in both ARB files.

## Steps

1. **Pick the key**: lowerCamelCase, prefixed by the feature or screen (e.g. `libraryEmptyTitle`, `bookDetailsLoanDue`). Grep `lib/l10n/app_it.arb` first: reuse an existing key if the meaning is the same.
2. **Italian first** — `lib/l10n/app_it.arb` is the template. Add the key next to related keys, with an `@key` entry when there are placeholders or the meaning is ambiguous:
   ```json
   "booksReadCount": "{count, plural, =1{1 libro letto} other{{count} libri letti}}",
   "@booksReadCount": {
     "placeholders": { "count": { "type": "int" } }
   },
   ```
3. **English** — add the same key to `lib/l10n/app_en.arb` in the same position. Placeholder names and types must match exactly; `@key` metadata belongs only in the template.
4. **Generate**: run `flutter gen-l10n`. Never edit `lib/l10n/gen/` by hand.
5. **Use it**: `context.l10n.<key>` (extension in `lib/core/utils/l10n_extension.dart`) or `AppLocalizations.of(context).<key>`.
6. **Check**: `flutter analyze`. If a widget test asserts on the text, remember tests pump in Italian by default (`test/helpers/pump_app.dart`).

## Tone

Italian copy is informal (tu), short and warm, as in the README. English mirrors the meaning, not word for word.
