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
mkdir -p "$workspace" "$bin_dir" "$fake_bin" \
  "$home/.codex/rules" "$home/.copilot" "$home/.gemini" || exit 1

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

# Simulate the known older/current backend files that the installer owns and
# should migrate to one canonical home instruction file.
cat > "$home/.codex/AGENTS.md" <<'EOF'
<!-- managed-projects:start -->
## Miguel's managed projects

Old Codex-managed project guidance.
<!-- managed-projects:end -->
EOF

cat > "$home/.copilot/copilot-instructions.md" <<'EOF'
<!-- pj-managed-projects:start -->
Old Copilot pj guidance.
<!-- pj-managed-projects:end -->
EOF

cat > "$home/.gemini/GEMINI.md" <<'EOF'
<!-- pj-managed-projects:start -->
Old Antigravity pj guidance.
<!-- pj-managed-projects:end -->
EOF

cat > "$home/.codex/rules/default.rules" <<'EOF'
# Keep this user-authored Codex rule intact.
prefix_rule(pattern = ["git", "status"], decision = "allow")
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
grep -Fq 'Optional `agy` subagent delegation' "$home/AGENTS.md" || exit 1
grep -Fq 'Only Codex and GitHub Copilot CLI may use `agy`' "$home/AGENTS.md" || exit 1
grep -Fq 'Antigravity itself must not invoke `agy` recursively' "$home/AGENTS.md" || exit 1
grep -Fq 'gemini-3.8-flash-high' "$home/AGENTS.md" || exit 1
grep -Fq 'explicitly authorises' "$home/AGENTS.md" || exit 1

grep -Fq '# My own planning notes' "$workspace/AGENTS.md" || exit 1
grep -Fq 'Keep this user-authored line intact.' "$workspace/AGENTS.md" || exit 1
grep -Fq '<!-- pj-managed-projects:start -->' "$workspace/AGENTS.md" || exit 1
grep -Fq 'Natural-language' "$workspace/AGENTS.md" || exit 1
grep -Fq 'process the implementation issues for X' "$workspace/AGENTS.md" || exit 1
grep -Fq 'references/local-implementation-queue.md' "$workspace/AGENTS.md" || exit 1
grep -Fq 'pj-update-skills' "$workspace/AGENTS.md" || exit 1

for context in \
    "$home/.codex/AGENTS.md" \
    "$home/.copilot/copilot-instructions.md" \
    "$home/.gemini/GEMINI.md"; do
  [ -L "$context" ] || exit 1
  [ "$(readlink -f "$context")" = "$(readlink -f "$home/AGENTS.md")" ] || exit 1
done

grep -Fq '# Keep this user-authored Codex rule intact.' "$home/.codex/rules/default.rules" || exit 1
grep -Fq '# pj-agy-subagent:start' "$home/.codex/rules/default.rules" || exit 1
grep -Fq 'pattern = ["agy"]' "$home/.codex/rules/default.rules" || exit 1
grep -Fq 'decision = "allow"' "$home/.codex/rules/default.rules" || exit 1

# Reinstalling replaces only the managed blocks instead of duplicating them or
# overwriting user-authored home/workspace content or Codex rules.
run_installer || exit 1
[ "$(grep -Fc '<!-- pj-managed-projects:start -->' "$home/AGENTS.md")" -eq 1 ] || exit 1
[ "$(grep -Fc '<!-- pj-managed-projects:start -->' "$workspace/AGENTS.md")" -eq 1 ] || exit 1
[ "$(grep -Fc '# pj-agy-subagent:start' "$home/.codex/rules/default.rules")" -eq 1 ] || exit 1
grep -Fq 'Keep this home-authored line intact.' "$home/AGENTS.md" || exit 1
grep -Fq 'Keep this user-authored line intact.' "$workspace/AGENTS.md" || exit 1
grep -Fq '# Keep this user-authored Codex rule intact.' "$home/.codex/rules/default.rules" || exit 1

# Genuine backend-specific content is preserved rather than silently replaced
# by a link to the canonical home guidance.
custom_home="$tmp/custom-home"
mkdir -p "$custom_home/planning" "$custom_home/.local/bin" "$custom_home/.copilot" || exit 1
cat > "$custom_home/.copilot/copilot-instructions.md" <<'EOF'
# Bespoke Copilot-only instruction

Keep this backend-specific line.
EOF
HOME="$custom_home" \
  XDG_CONFIG_HOME="$custom_home/.config" \
  PATH="$custom_home/.local/bin:$fake_bin:/usr/bin:/bin" \
  bash "$installer" >/dev/null 2>"$tmp/custom-warning" || exit 1
[ ! -L "$custom_home/.copilot/copilot-instructions.md" ] || exit 1
grep -Fq 'Keep this backend-specific line.' "$custom_home/.copilot/copilot-instructions.md" || exit 1
grep -Fq 'preserving custom backend instructions' "$tmp/custom-warning" || exit 1

# PJ_WORKSPACE moves the managed workspace contract to the same directory that
# pj will use, without assuming ~/planning. Home-level maintenance and agy
# delegation guidance remain at ~/AGENTS.md.
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
grep -Fq 'Optional `agy` subagent delegation' "$home/AGENTS.md" || exit 1

printf 'workspace AGENTS context tests passed\n'
