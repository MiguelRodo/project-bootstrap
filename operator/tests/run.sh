#!/usr/bin/env bash

operator_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
installer="$operator_dir/install.sh"
tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/home/planning" "$tmp/bin" || exit 1

cat > "$tmp/bin/codex" <<'EOF'
#!/usr/bin/env bash
printf 'codex'
for arg in "$@"; do
  printf '\n<%s>' "$arg"
done
printf '\n'
EOF

cat > "$tmp/bin/agy" <<'EOF'
#!/usr/bin/env bash
printf 'agy'
for arg in "$@"; do
  printf '\n<%s>' "$arg"
done
printf '\n'
EOF

cat > "$tmp/bin/copilot" <<'EOF'
#!/usr/bin/env bash
printf 'copilot'
for arg in "$@"; do
  printf '\n<%s>' "$arg"
done
printf '\n'
EOF

chmod +x "$tmp/bin/codex" "$tmp/bin/agy" "$tmp/bin/copilot" || exit 1

test_config_home="$tmp/home/.config"
HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1

[ -x "$tmp/home/bin/pj" ] || exit 1
[ -L "$tmp/home/bin/pja" ] || exit 1
[ -L "$tmp/home/bin/pjcp" ] || exit 1
[ -L "$tmp/home/bin/pjcd" ] || exit 1
[ ! -e "$tmp/home/bin/pjc" ] || exit 1
[ "$(cat "$test_config_home/pj/default-backend")" = "codex" ] || exit 1
grep -q 'pj-managed-projects:start' "$tmp/home/.gemini/GEMINI.md" || exit 1
grep -q 'pj-managed-projects:start' "$tmp/home/.copilot/copilot-instructions.md" || exit 1

run_named() {
  name="$1"
  shift
  HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$tmp/home/bin:$tmp/bin:$PATH" "$tmp/home/bin/$name" "$@"
}

assert_contains() {
  output="$1"
  expected="$2"
  case "$output" in
    *"$expected"*) ;;
    *)
      printf 'Expected output to contain: %s\nActual output:\n%s\n' "$expected" "$output" >&2
      exit 1
      ;;
  esac
}

codex_text="$(run_named pj 'Create the issue - but keep this dash as text')" || exit 1
assert_contains "$codex_text" 'codex'
assert_contains "$codex_text" '<Create the issue - but keep this dash as text>'

codex_words="$(run_named pj Create the issue - with a dash)" || exit 1
assert_contains "$codex_words" '<Create the issue - with a dash>'

codex_options="$(run_named pj --model test-model -- 'Prompt - with dash')" || exit 1
assert_contains "$codex_options" '<--model>'
assert_contains "$codex_options" '<test-model>'
assert_contains "$codex_options" '<Prompt - with dash>'

agy_alias="$(run_named pja Create the issue - with a dash)" || exit 1
assert_contains "$agy_alias" 'agy'
assert_contains "$agy_alias" '<-p>'
assert_contains "$agy_alias" '<Create the issue - with a dash>'

copilot_alias="$(run_named pjcp Create the issue - with a dash)" || exit 1
assert_contains "$copilot_alias" 'copilot'
assert_contains "$copilot_alias" '<--allow-all>'
assert_contains "$copilot_alias" '<-p>'
assert_contains "$copilot_alias" '<Create the issue - with a dash>'

codex_alias="$(run_named pjcd Create the issue - with a dash)" || exit 1
assert_contains "$codex_alias" 'codex'
assert_contains "$codex_alias" '<Create the issue - with a dash>'

shown_default="$(run_named pj --show-default)" || exit 1
[ "$shown_default" = "codex" ] || exit 1

set_default="$(run_named pj --set-default antigravity)" || exit 1
[ "$set_default" = "antigravity" ] || exit 1
[ "$(cat "$test_config_home/pj/default-backend")" = "antigravity" ] || exit 1

agy_default="$(run_named pj 'Use the configured default')" || exit 1
assert_contains "$agy_default" 'agy'
assert_contains "$agy_default" '<Use the configured default>'

# Explicit shorthands ignore the configured default.
codex_alias_after_default="$(run_named pjcd 'Still use Codex')" || exit 1
assert_contains "$codex_alias_after_default" 'codex'

copilot_alias_after_default="$(run_named pjcp 'Still use Copilot')" || exit 1
assert_contains "$copilot_alias_after_default" 'copilot'

# PJ_DEFAULT_BACKEND overrides the saved default for generic pj.
copilot_env_default="$(PJ_DEFAULT_BACKEND=copilot run_named pj 'Use the environment default')" || exit 1
assert_contains "$copilot_env_default" 'copilot'

# PJ_BACKEND remains the one-run generic pj override.
codex_env="$(PJ_BACKEND=codex run_named pj 'Use Codex for one run')" || exit 1
assert_contains "$codex_env" 'codex'

# An explicit --backend wins even when a shorthand selected another agent.
overridden_alias="$(run_named pja --backend copilot 'Override the shorthand')" || exit 1
assert_contains "$overridden_alias" 'copilot'

# Reinstalling preserves the chosen saved default.
HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1
[ "$(cat "$test_config_home/pj/default-backend")" = "antigravity" ] || exit 1

# Remove the legacy pjc symlink only when it is the old installer-managed link.
ln -sfn "$tmp/home/bin/pj" "$tmp/home/bin/pjc" || exit 1
HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1
[ ! -e "$tmp/home/bin/pjc" ] || exit 1

printf 'operator pj tests passed\n'
