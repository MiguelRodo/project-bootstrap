#!/usr/bin/env bash

operator_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
updater="$operator_dir/update-managed-skills.sh"
tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT

home="$tmp/home"
workspace="$home/planning"
remote="$tmp/remote.git"
seed="$tmp/seed"
fake_bin="$tmp/bin"
mkdir -p "$workspace" "$fake_bin" || exit 1

git init --bare "$remote" >/dev/null || exit 1
git init -b main "$seed" >/dev/null || exit 1
git -C "$seed" config user.name 'Test User'
git -C "$seed" config user.email 'test@example.invalid'
mkdir -p "$seed/.agents/skills/github-project-admin" || exit 1
printf 'old skill\n' > "$seed/.agents/skills/github-project-admin/SKILL.md"
printf 'remote baseline\n' > "$seed/local.txt"
git -C "$seed" add . || exit 1
git -C "$seed" commit -m 'Initial managed repository' >/dev/null || exit 1
git -C "$seed" remote add origin "$remote" || exit 1
git -C "$seed" push -u origin main >/dev/null || exit 1
git --git-dir="$remote" symbolic-ref HEAD refs/heads/main || exit 1

git clone "$remote" "$workspace/demo" >/dev/null || exit 1
git -C "$workspace/demo" config user.name 'Test User'
git -C "$workspace/demo" config user.email 'test@example.invalid'
printf 'local unfinished work\n' > "$workspace/demo/local.txt"

cat > "$fake_bin/gh" <<'EOF'
#!/usr/bin/env bash

if [ "$1" = 'auth' ] && [ "$2" = 'status' ]; then
  exit 0
fi

if [ "$1" = 'skill' ] && [ "$2" = 'update' ] && \
   [ "$3" = 'github-project-admin' ] && [ "$4" = '--all' ]; then
  printf 'new skill\n' > .agents/skills/github-project-admin/SKILL.md
  exit 0
fi

printf 'unexpected gh invocation:' >&2
printf ' <%s>' "$@" >&2
printf '\n' >&2
exit 2
EOF
chmod +x "$fake_bin/gh" || exit 1

HOME="$home" \
  PJ_WORKSPACE="$workspace" \
  PATH="$fake_bin:/usr/bin:/bin" \
  bash "$updater" >/dev/null || exit 1

# The skill refresh was committed and pushed.
[ "$(cat "$workspace/demo/.agents/skills/github-project-admin/SKILL.md")" = 'new skill' ] || exit 1
[ "$(git -C "$workspace/demo" log -1 --pretty=%s)" = 'Update github-project-admin skill' ] || exit 1
git --git-dir="$remote" show main:.agents/skills/github-project-admin/SKILL.md | grep -Fxq 'new skill' || exit 1

# Pre-existing local work was restored and was not included in the pushed commit.
[ "$(cat "$workspace/demo/local.txt")" = 'local unfinished work' ] || exit 1
[ -n "$(git -C "$workspace/demo" status --porcelain -- local.txt)" ] || exit 1
git --git-dir="$remote" show main:local.txt | grep -Fxq 'remote baseline' || exit 1

# Running again is idempotent when the fake provider reports the same skill.
HOME="$home" \
  PJ_WORKSPACE="$workspace" \
  PATH="$fake_bin:/usr/bin:/bin" \
  bash "$updater" >/dev/null || exit 1
[ "$(git -C "$workspace/demo" log -1 --pretty=%s)" = 'Update github-project-admin skill' ] || exit 1
[ "$(cat "$workspace/demo/local.txt")" = 'local unfinished work' ] || exit 1

printf 'managed skill updater tests passed\n'
