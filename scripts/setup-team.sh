#!/bin/sh
set -e

# Always run from the project root directory
cd "$(dirname "$0")/.."

die() { echo "fatal: $*" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not a git repository"

CONFIG_FILE=$(git rev-parse --git-path setup-team-id)
HOOKS_DIR=$(git rev-parse --git-path hooks)

# --- Patching functions ---
patch_team() {
  team="$1"
  sed -i '' -E "s/DEVELOPMENT_TEAM *= *.*/DEVELOPMENT_TEAM = ${team}/" Easydict-debug.xcconfig
  sed -i '' -E "s/CODE_SIGN_IDENTITY *= *.*/CODE_SIGN_IDENTITY = Apple Development/" Easydict-debug.xcconfig
  sed -i '' -E "s/CODE_SIGN_STYLE *= *.*/CODE_SIGN_STYLE = Automatic/" Easydict-debug.xcconfig
  git update-index --assume-unchanged Easydict-debug.xcconfig 2>/dev/null || true
}

patch_adhoc() {
  sed -i '' -E "s/DEVELOPMENT_TEAM *= *.*/DEVELOPMENT_TEAM =/" Easydict-debug.xcconfig
  sed -i '' -E "s/CODE_SIGN_IDENTITY *= *.*/CODE_SIGN_IDENTITY = -/" Easydict-debug.xcconfig
  sed -i '' -E "s/CODE_SIGN_STYLE *= *.*/CODE_SIGN_STYLE = Manual/" Easydict-debug.xcconfig
  git update-index --assume-unchanged Easydict-debug.xcconfig 2>/dev/null || true
}

# --- Uninstall ---
if [ "$1" = "--uninstall" ]; then
  rm -f "$HOOKS_DIR/post-checkout" "$HOOKS_DIR/post-merge" "$CONFIG_FILE"
  git update-index --no-assume-unchanged Easydict-debug.xcconfig 2>/dev/null || true
  echo "Done! setup-team hooks and configuration removed."
  exit 0
fi

# --- Hook execution ---
if [ "$1" = "--hook" ]; then
  if [ ! -f "$CONFIG_FILE" ]; then
    exit 0
  fi
  stored=$(cat "$CONFIG_FILE")
  if [ "$stored" = "adhoc" ]; then
    patch_adhoc
  elif [ -n "$stored" ]; then
    patch_team "$stored"
  fi
  exit 0
fi

# --- Configure mode ---
MODE="team"
team=""

if [ "$1" = "--adhoc" ]; then
  MODE="adhoc"
elif [ -n "$1" ]; then
  team="$1"
else
  certs=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development" || true)
  count=$(printf '%s\n' "$certs" | grep -c "Apple Development" 2>/dev/null || true)

  if [ "$count" -eq 0 ]; then
    echo "info: no Apple Development certificate found, using ad-hoc signing"
    MODE="adhoc"
  elif [ "$count" -eq 1 ]; then
    team=$(printf '%s\n' "$certs" | grep -oE '\([A-Z0-9]{10}\)' | tr -d '()')
  else
    echo "Multiple Apple Development certificates found:"
    printf '%s\n' "$certs" | cat -n
    printf "Select [1-%d] (default 1): " "$count"
    read -r choice </dev/tty
    choice=${choice:-1}
    team=$(printf '%s\n' "$certs" | sed -n "${choice}p" | grep -oE '\([A-Z0-9]{10}\)' | tr -d '()')
  fi

  [ "$MODE" = "team" ] && [ -z "$team" ] && die "failed to detect team id"
fi

# Save configuration
if [ "$MODE" = "adhoc" ]; then
  echo "adhoc" > "$CONFIG_FILE"
  patch_adhoc
else
  echo "$team" > "$CONFIG_FILE"
  patch_team "$team"
fi

# Install hooks
mkdir -p "$HOOKS_DIR"

cat > "$HOOKS_DIR/post-checkout" << 'HOOK'
#!/bin/sh
if [ -f "./scripts/setup-team.sh" ]; then
  ./scripts/setup-team.sh --hook
fi
HOOK

chmod +x "$HOOKS_DIR/post-checkout"
cp "$HOOKS_DIR/post-checkout" "$HOOKS_DIR/post-merge"

# Report
if [ "$MODE" = "adhoc" ]; then
  echo "Done! Ad-hoc signing configured locally (no Apple account needed)."
else
  echo "Done! Team ID set to: $team"
  echo ""
  echo "Make sure this team's Apple ID is logged in under Xcode > Settings > Accounts."
fi
