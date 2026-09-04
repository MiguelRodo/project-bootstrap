#!/usr/bin/env bash

operator_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
installer="$operator_dir/install.sh"
tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT

home="$tmp/home"
workspace="$home/planning"
bin_dir="$home/.local/bin"
config_home="$home/.config"
fake_bin="$tmp/bin"
mkdir -p "$workspace" "$bin_dir" "$fake_bin" || exit 1

for tool in codex agy copilot; do
  cat > "$fake_bin/$tool" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$fake_bin/$tool" || exit 1
done

cat > "$home/AGENTS.md" <<'EOF'
# My own home guidance

Keep this home-authored line intact.
EOF

cat > "$workspace/AGENTS.md" <<'EOF'
# My own planning notes

Keep this user-authored line intact.
EOF

run_installer() {
  HOME="$home" \
    XDG_CONFIG_HOME="$config_home" \
    PATH="$bin_dir:$fake_bin:/usr/bin:/bin" \
    bash "$installer" >/dev/null
}

run_installer || exit 1

[ -x "$bin_dir/pj-update-skills" ] || exit 1
grep -Fq '# My own home guidance' "$home/AGENTS.md" || exit 1
grep -Fq 'Keep this home-authored line intact.' "$home/AGENTS.md" || exit 1
grep -Fq '<!-- pj-managed-projects:start -->' "$home/AGENTS.md" || exit 1
grep -Fq 'pj-update-skills' "$home/AGENTS.md" || exit 1
grep -Fq '# My own planning notes' "$workspace/AGENTS.md" || exit 1
grep -Fq 'Keep this user-authored line intact.' "$workspace/AGENTS.md" || exit 1
grep -Fq '<!-- pj-managed-projects:start -->' "$workspace/AGENTS.md" || exit 1
grep -Fq 'Natural-language' "$workspace/AGENTS.md" || exit 1
grep -Fq 'process the implementation issues for X' "$workspace/AGENTS.md" || exit 1
grep -Fq 'references/local-implementation-queue.md' "$workspace/AGENTS.md" || exit 1
grep -Fq 'pj-update-skills' "$workspace/AGENTS.md" || exit 1
grep -Fq 'workspace `AGENTS.md` first' "$home/.gemini/GEMINI.md" || exit 1
grep -Fq 'workspace `AGENTS.md` first' "$home/.copilot/copilot-instructions.md" || exit 1

# Reinstalling replaces only the managed blocks instead of duplicating them or
# overwriting user-authored home/workspace content.
run_installer || exit 1
[ "$(grep -Fc '<!-- pj-managed-projects:start -->' "$home/AGENTS.md")" -eq 1 ] || exit 1
[ "$(grep -Fc '<!-- pj-managed-projects:start -->' "$workspace/AGENTS.md")" -eq 1 ] || exit 1
[ "$(grep -Fc '<!-- pj-managed-projects:start -->' "$home/.gemini/GEMINI.md")" -eq 1 ] || exit 1
[ "$(grep -Fc '<!-- pj-managed-projects:start -->' "$home/.copilot/copilot-instructions.md")" -eq 1 ] || exit 1
grep -Fq 'Keep this home-authored line intact.' "$home/AGENTS.md" || exit 1
grep -Fq 'Keep this user-authored line intact.' "$workspace/AGENTS.md" || exit 1

# PJ_WORKSPACE moves the managed workspace contract to the same directory that
# pj will use, without assuming ~/planning. Home-level maintenance guidance
# remains at ~/AGENTS.md.
custom_workspace="$home/custom-planning"
mkdir -p "$custom_workspace" || exit 1
HOME="$home" \
  XDG_CONFIG_HOME="$config_home" \
  PJ_WORKSPACE="$custom_workspace" \
  PATH="$bin_dir:$fake_bin:/usr/bin:/bin" \
  bash "$installer" >/dev/null || exit 1

grep -Fq '<!-- pj-managed-projects:start -->' "$custom_workspace/AGENTS.md" || exit 1
grep -Fq 'Shared `pj` planning workspace' "$custom_workspace/AGENTS.md" || exit 1
grep -Fq 'pj-update-skills' "$home/AGENTS.md" || exit 1

printf 'workspace AGENTS context tests passed\n'
