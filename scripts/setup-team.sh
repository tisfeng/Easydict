#!/bin/sh
set -eu

# Configures local Debug signing through an ignored xcconfig file. It also
# removes state left by earlier versions that edited tracked files or hooks.

cd "$(dirname "$0")/.."

die() {
  echo "fatal: $*" >&2
  exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  die "not a git repository"

LOCAL_CONFIG="Easydict-debug.local.xcconfig"
LEGACY_CONFIG=$(git rev-parse --git-path setup-team-id)
HOOKS_DIR=$(git rev-parse --git-path hooks)

# Removes a hook only when it exactly matches the legacy setup-team hook.
remove_legacy_hook() {
  hook="$1"
  legacy_hook='#!/bin/sh
if [ -f "./scripts/setup-team.sh" ]; then
  ./scripts/setup-team.sh --hook
fi'

  if [ -f "$hook" ] && [ "$(cat "$hook")" = "$legacy_hook" ]; then
    rm -f "$hook"
  fi
}

# Moves legacy or manual signing edits back to the tracked defaults.
migrate_legacy_setup() {
  git update-index --no-assume-unchanged Easydict-debug.xcconfig \
    2>/dev/null || true
  git update-index --no-skip-worktree Easydict-debug.xcconfig \
    2>/dev/null || true

  sed -i '' -E \
    "s/DEVELOPMENT_TEAM *= *.*/DEVELOPMENT_TEAM =/" \
    Easydict-debug.xcconfig
  sed -i '' -E \
    "s/CODE_SIGN_IDENTITY *= *.*/CODE_SIGN_IDENTITY = -/" \
    Easydict-debug.xcconfig
  sed -i '' -E \
    "s/CODE_SIGN_STYLE *= *.*/CODE_SIGN_STYLE = Manual/" \
    Easydict-debug.xcconfig
  if ! grep -Fqx '#include? "Easydict-debug.local.xcconfig"' \
    Easydict-debug.xcconfig; then
    printf '\n#include? "Easydict-debug.local.xcconfig"\n' \
      >> Easydict-debug.xcconfig
  fi

  rm -f "$LEGACY_CONFIG"
  remove_legacy_hook "$HOOKS_DIR/post-checkout"
  remove_legacy_hook "$HOOKS_DIR/post-merge"
}

# Writes the complete local override so repeated setup runs are deterministic.
write_config() {
  team="$1"
  identity="$2"
  style="$3"

  {
    printf 'DEVELOPMENT_TEAM = %s\n' "$team"
    printf 'CODE_SIGN_IDENTITY = %s\n' "$identity"
    printf 'CODE_SIGN_STYLE = %s\n' "$style"
  } > "$LOCAL_CONFIG"
}

validate_team() {
  printf '%s\n' "$1" | grep -Eq '^[A-Z0-9]{10}$' ||
    die "Team ID must contain 10 uppercase letters or digits"
}

[ "$#" -le 1 ] || die "expected at most one argument"

case "${1:-}" in
  --hook)
    # A legacy hook may invoke this once after updating to the new script.
    remove_legacy_hook "$HOOKS_DIR/post-checkout"
    remove_legacy_hook "$HOOKS_DIR/post-merge"
    exit 0
    ;;
  --uninstall)
    migrate_legacy_setup
    rm -f "$LOCAL_CONFIG"
    echo "Done! Local signing configuration removed."
    exit 0
    ;;
esac

if [ "${1:-}" = "--adhoc" ]; then
  migrate_legacy_setup
  write_config "" "-" "Manual"
  echo "Done! Ad-hoc signing configured locally (no Apple account needed)."
  exit 0
fi

team="${1:-}"
if [ -z "$team" ]; then
  certs=$(security find-identity -v -p codesigning 2>/dev/null |
    grep "Apple Development" || true)
  count=$(printf '%s\n' "$certs" |
    grep -c "Apple Development" 2>/dev/null || true)

  if [ "$count" -eq 0 ]; then
    die "no Apple Development certificate found; pass a Team ID or use --adhoc"
  elif [ "$count" -eq 1 ]; then
    team=$(printf '%s\n' "$certs" |
      grep -oE '\([A-Z0-9]{10}\)' | head -n 1 | tr -d '()')
  else
    echo "Multiple Apple Development certificates found:"
    printf '%s\n' "$certs" | cat -n
    printf "Select [1-%d] (default 1): " "$count"
    read -r choice </dev/tty
    choice=${choice:-1}
    case "$choice" in
      *[!0-9]* | "") die "selection must be a number" ;;
    esac
    [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ] ||
      die "selection is outside the available range"
    team=$(printf '%s\n' "$certs" | sed -n "${choice}p" |
      grep -oE '\([A-Z0-9]{10}\)' | tr -d '()')
  fi
fi

validate_team "$team"
migrate_legacy_setup
write_config "$team" "Apple Development" "Automatic"

echo "Done! Team ID set to: $team"
echo ""
echo "Make sure this team's Apple ID is logged in under Xcode > Settings > Accounts."
