#!/usr/bin/env bash
# PreToolUse: block edits to secrets and generated files.
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in
  */.env)
    echo "Blocked: .env holds the Supabase credentials. Ask the user to edit it." >&2
    exit 2 ;;
  */pubspec.lock)
    echo "Blocked: pubspec.lock is generated. Edit pubspec.yaml and run 'flutter pub get'." >&2
    exit 2 ;;
  */lib/l10n/gen/*)
    echo "Blocked: lib/l10n/gen is generated. Edit lib/l10n/app_it.arb + app_en.arb and run 'flutter gen-l10n'." >&2
    exit 2 ;;
esac
exit 0
