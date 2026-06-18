#!/bin/sh
set -e

cd "$(dirname "$0")/.."

die() { echo "fatal: $*" >&2; exit 1; }

[ -d ".git" ] || die "not a git repository"

if [ "$1" = "--uninstall" ]; then
  rm -f .git/hooks/post-checkout .git/hooks/post-merge
  git update-index --no-assume-unchanged Easydict-debug.xcconfig 2>/dev/null || true
  echo "Done! setup-team hooks removed."
  exit 0
fi

team=$1
if [ -z "$team" ]; then
  team=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | grep -oE '\([A-Z0-9]{10}\)' | tr -d '()')
  [ -n "$team" ] || die "no team id found in keychain. usage: $0 [TEAM_ID]"
fi

mkdir -p .git/hooks

cat > .git/hooks/post-checkout << 'EOF'
#!/bin/sh
team="TEAM_ID"
sed -i '' -E "s/DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = ${team}/" Easydict-debug.xcconfig
git update-index --assume-unchanged Easydict-debug.xcconfig 2>/dev/null || true
EOF

sed -i '' "s/TEAM_ID/$team/" .git/hooks/post-checkout
chmod +x .git/hooks/post-checkout
cp .git/hooks/post-checkout .git/hooks/post-merge

.git/hooks/post-checkout

echo "Done! Team ID set to: $team"
