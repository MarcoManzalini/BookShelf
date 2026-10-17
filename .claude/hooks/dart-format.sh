#!/usr/bin/env bash
# PostToolUse: format the edited Dart file (skips generated l10n code).
f=$(jq -r '.tool_input.file_path // empty')
[[ "$f" == *.dart && "$f" != */lib/l10n/gen/* ]] || exit 0
dart format "$f" >/dev/null 2>&1
exit 0
