#!/usr/bin/env bash
set -euo pipefail

TASK="${1:-Unnamed Animal Kingdom task}"
QA_RESULT="${2:-Not Tested}"
NEXT_ACTION="${3:-Run affected Roblox Studio verification.}"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  echo "ERROR: not inside a Git repository" >&2
  exit 1
fi
cd "$ROOT"

BRANCH="$(git branch --show-current)"
SHA="$(git rev-parse HEAD)"
SHORT_SHA="$(git rev-parse --short HEAD)"
ORIGIN="$(git remote get-url origin 2>/dev/null || echo MISSING)"
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo NONE)"
STATUS="$(git status --short)"
if [[ -z "$STATUS" ]]; then TREE_STATE="clean"; else TREE_STATE="dirty"; fi
SUBJECT="$(git log -1 --format=%s)"

EXPECTED_SSH="git@github.com:wardmaciah-web/Animal-Kingdom.git"
EXPECTED_HTTPS="https://github.com/wardmaciah-web/Animal-Kingdom.git"
REMOTE_OK="NO"
if [[ "$ORIGIN" == "$EXPECTED_SSH" || "$ORIGIN" == "$EXPECTED_HTTPS" ]]; then REMOTE_OK="YES"; fi

printf '%s\n' "ANIMAL_KINGDOM_HANDOFF"
printf 'Task: %s\n' "$TASK"
printf 'QA Result: %s\n' "$QA_RESULT"
printf 'Next Action: %s\n' "$NEXT_ACTION"
printf 'Branch: %s\n' "$BRANCH"
printf 'Commit: %s\n' "$SHA"
printf 'Short Commit: %s\n' "$SHORT_SHA"
printf 'Commit Subject: %s\n' "$SUBJECT"
printf 'Origin: %s\n' "$ORIGIN"
printf 'Origin Matches Canonical Repo: %s\n' "$REMOTE_OK"
printf 'Upstream: %s\n' "$UPSTREAM"
printf 'Working Tree: %s\n' "$TREE_STATE"
printf '%s\n' 'Files in latest commit:'
git diff-tree --no-commit-id --name-only -r HEAD | sed 's/^/  - /'
if [[ "$TREE_STATE" == "dirty" ]]; then
  printf '%s\n' 'Uncommitted changes still present:'
  printf '%s\n' "$STATUS" | sed 's/^/  /'
fi
printf '%s\n' 'END_ANIMAL_KINGDOM_HANDOFF'

if [[ "$REMOTE_OK" != "YES" ]]; then
  echo "WARNING: origin is not the canonical Animal Kingdom GitHub repository." >&2
fi
if [[ "$BRANCH" != "main" ]]; then
  echo "WARNING: handoff is not on main." >&2
fi
