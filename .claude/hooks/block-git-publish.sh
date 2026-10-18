#!/usr/bin/env bash
# PreToolUse: block git commit / push and GitHub PR publishing. Read-only git
# (diff, status, log, show, branch...) stays allowed.
cmd=$(jq -r '.tool_input.command // empty')
if printf '%s' "$cmd" | grep -Eq '(^|[;&|(`[:space:]])git([[:space:]]+-[^[:space:];&|]+([[:space:]]+[^-[:space:];&|][^[:space:];&|]*)?)*[[:space:]]+(commit|push)([[:space:];&|)]|$)'; then
  echo "Blocked: git commit/push are reserved to the user. Show the diff and let them commit." >&2
  exit 2
fi
if printf '%s' "$cmd" | grep -Eq '(^|[;&|(`[:space:]])gh[[:space:]]+pr[[:space:]]+(create|merge)([[:space:];&|)]|$)'; then
  echo "Blocked: opening or merging PRs is reserved to the user." >&2
  exit 2
fi
exit 0
