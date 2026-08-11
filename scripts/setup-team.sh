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

certificate_name_from_identity() {
  printf '%s\n' "$1" | awk -F '"' 'NF >= 3 { print $2; exit }'
}

certificate_hash_from_identity() {
  printf '%s\n' "$1" | awk '{ print $2; exit }'
}

# Apple's code-signing certificates store the Team ID in the Subject OU.
# The identifier in the certificate's display name is not necessarily a Team ID.
team_id_from_identity() {
  identity="$1"
  certificate_name=$(certificate_name_from_identity "$identity")
  certificate_hash=$(certificate_hash_from_identity "$identity")
  [ -n "$certificate_name" ] || die "unable to read certificate name"
  printf '%s\n' "$certificate_hash" | grep -Eq '^[A-Fa-f0-9]{40}$' ||
    die "unable to read certificate SHA-1: $certificate_name"

  certificates=$(
    security find-certificate -a -c "$certificate_name" -Z -p 2>/dev/null
  ) || die "unable to read certificate: $certificate_name"
  certificate=$(printf '%s\n' "$certificates" | awk \
    -v wanted_hash="$certificate_hash" '
      $0 == "SHA-1 hash: " wanted_hash { matched = 1; next }
      matched && $0 == "-----BEGIN CERTIFICATE-----" { in_certificate = 1 }
      in_certificate { print }
      in_certificate && $0 == "-----END CERTIFICATE-----" { exit }
    ')
  [ -n "$certificate" ] ||
    die "unable to find selected certificate by SHA-1: $certificate_hash"

  subject=$(
    printf '%s\n' "$certificate" |
      openssl x509 -noout -subject -nameopt multiline 2>/dev/null
  ) || die "unable to read certificate: $certificate_name"

  parsed_team=$(printf '%s\n' "$subject" | sed -nE \
    's/^[[:space:]]*organizationalUnitName[[:space:]]*=[[:space:]]*([A-Z0-9]{10})[[:space:]]*$/\1/p' |
    head -n 1)
  [ -n "$parsed_team" ] ||
    die "certificate does not contain a valid Team ID: $certificate_name"

  printf '%s\n' "$parsed_team"
}

print_certificate_options() {
  option=1
  while IFS= read -r identity; do
    certificate_name=$(certificate_name_from_identity "$identity")
    certificate_team=$(team_id_from_identity "$identity")
    printf '  %d) %s [Team ID: %s]\n' \
      "$option" "$certificate_name" "$certificate_team"
    option=$((option + 1))
  done <<EOF
$certs
EOF
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
    awk '/"Apple Development:/ && $0 !~ /CSSMERR_/ { print }' || true)
  count=$(printf '%s\n' "$certs" |
    awk 'NF { count++ } END { print count + 0 }')

  if [ "$count" -eq 0 ]; then
    die "no Apple Development certificate found; pass a Team ID or use --adhoc"
  elif [ "$count" -eq 1 ]; then
    selected_identity="$certs"
  else
    echo "Multiple Apple Development certificates found:"
    print_certificate_options
    printf "Select [1-%d] (default 1): " "$count"
    read -r choice </dev/tty
    choice=${choice:-1}
    case "$choice" in
      *[!0-9]* | "") die "selection must be a number" ;;
    esac
    [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ] ||
      die "selection is outside the available range"
    selected_identity=$(printf '%s\n' "$certs" | sed -n "${choice}p")
  fi

  team=$(team_id_from_identity "$selected_identity")
fi

validate_team "$team"
migrate_legacy_setup
write_config "$team" "Apple Development" "Automatic"

echo "Done! Team ID set to: $team"
echo ""
echo "Make sure this team's Apple ID is logged in under Xcode > Settings > Accounts."
