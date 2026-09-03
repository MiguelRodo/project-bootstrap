#!/usr/bin/env bash

operator_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
installer="$operator_dir/install.sh"
tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/home/planning" "$tmp/home/.local/bin" "$tmp/bin" || exit 1

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
test_bin_dir="$tmp/home/.local/bin"
HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$test_bin_dir:$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1

[ -x "$test_bin_dir/pj" ] || exit 1
[ -L "$test_bin_dir/pja" ] || exit 1
[ -L "$test_bin_dir/pjcp" ] || exit 1
[ -L "$test_bin_dir/pjcd" ] || exit 1
[ ! -e "$test_bin_dir/pjc" ] || exit 1
[ "$(cat "$test_config_home/pj/install-bin-dir")" = "$test_bin_dir" ] || exit 1
[ "$(cat "$test_config_home/pj/default-backend")" = "codex" ] || exit 1
grep -q 'pj-managed-projects:start' "$tmp/home/.gemini/GEMINI.md" || exit 1
grep -q 'pj-managed-projects:start' "$tmp/home/.copilot/copilot-instructions.md" || exit 1

run_named() {
  name="$1"
  shift
  HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$test_bin_dir:$tmp/bin:$PATH" "$test_bin_dir/$name" "$@"
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

assert_not_contains() {
  output="$1"
  unexpected="$2"
  case "$output" in
    *"$unexpected"*)
      printf 'Expected output not to contain: %s\nActual output:\n%s\n' "$unexpected" "$output" >&2
      exit 1
      ;;
    *) ;;
  esac
}

# Tests run without a TTY, so auto session mode should use one-shot interfaces.
codex_text="$(run_named pj 'Create the issue - but keep this dash as text')" || exit 1
assert_contains "$codex_text" 'codex'
assert_contains "$codex_text" '<-m>'
assert_contains "$codex_text" '<gpt-5.6-luna>'
assert_contains "$codex_text" '<model_reasoning_effort="xhigh">'
assert_contains "$codex_text" '<exec>'
assert_contains "$codex_text" '<Create the issue - but keep this dash as text>'

codex_words="$(run_named pj Create the issue - with a dash)" || exit 1
assert_contains "$codex_words" '<exec>'
assert_contains "$codex_words" '<Create the issue - with a dash>'

codex_options="$(run_named pj --model test-model -- 'Prompt - with dash')" || exit 1
assert_contains "$codex_options" '<exec>'
assert_contains "$codex_options" '<--model>'
assert_contains "$codex_options" '<test-model>'
assert_contains "$codex_options" '<Prompt - with dash>'

implement_short="$(run_named pj -i)" || exit 1
assert_contains "$implement_short" 'codex'
assert_contains "$implement_short" '<exec>'
assert_contains "$implement_short" '<Process the Chat implementation queue across the managed repositories in this workspace.'
assert_contains "$implement_short" 'references/local-implementation-queue.md'
assert_contains "$implement_short" 'without asking for a routine preview'

implement_issues="$(run_named pj --implement-issues)" || exit 1
assert_contains "$implement_issues" '<Process the Chat implementation queue across the managed repositories in this workspace.'

implement_chat="$(run_named pj --implement-chat)" || exit 1
assert_contains "$implement_chat" '<Process the Chat implementation queue across the managed repositories in this workspace.'

implement_copilot="$(run_named pj --backend copilot -i)" || exit 1
assert_contains "$implement_copilot" 'copilot'
assert_contains "$implement_copilot" '<mai-code-1.1-flash>'
assert_contains "$implement_copilot" '<-p>'
assert_contains "$implement_copilot" '<Process the Chat implementation queue across the managed repositories in this workspace.'

if run_named pj -i extra >/dev/null 2>&1; then
  echo 'pj -i unexpectedly accepted extra arguments' >&2
  exit 1
fi

agy_alias="$(run_named pja Create the issue - with a dash)" || exit 1
assert_contains "$agy_alias" 'agy'
assert_contains "$agy_alias" '<--dangerously-skip-permissions>'
assert_contains "$agy_alias" '<--print-timeout>'
assert_contains "$agy_alias" '<15m>'
assert_not_contains "$agy_alias" '<--sandbox>'
assert_not_contains "$agy_alias" '<--model>'
assert_contains "$agy_alias" '<-p>'
assert_contains "$agy_alias" '<Create the issue - with a dash>'
assert_not_contains "$agy_alias" '<--continue>'

agy_explicit_sandbox="$(run_named pja --sandbox -- 'Prompt - with dash')" || exit 1
assert_contains "$agy_explicit_sandbox" '<--sandbox>'
assert_contains "$agy_explicit_sandbox" '<--print-timeout>'
assert_contains "$agy_explicit_sandbox" '<Prompt - with dash>'

agy_custom_timeout="$(PJ_ANTIGRAVITY_TIMEOUT=30m run_named pja 'Use a longer timeout')" || exit 1
assert_contains "$agy_custom_timeout" '<--print-timeout>'
assert_contains "$agy_custom_timeout" '<30m>'
assert_contains "$agy_custom_timeout" '<Use a longer timeout>'

copilot_alias="$(run_named pjcp Create the issue - with a dash)" || exit 1
assert_contains "$copilot_alias" 'copilot'
assert_contains "$copilot_alias" '<--allow-all>'
assert_contains "$copilot_alias" '<--model>'
assert_contains "$copilot_alias" '<mai-code-1.1-flash>'
assert_contains "$copilot_alias" '<-p>'
assert_not_contains "$copilot_alias" '<-i>'
assert_contains "$copilot_alias" '<Create the issue - with a dash>'

# Forced interactive mode mirrors terminal behaviour: Copilot seeds an
# interactive session and Antigravity seeds one headless turn then resumes it.
copilot_interactive="$(PJ_SESSION_MODE=interactive run_named pjcp 'Keep this conversation open')" || exit 1
assert_contains "$copilot_interactive" '<-i>'
assert_not_contains "$copilot_interactive" '<-p>'
assert_contains "$copilot_interactive" '<Keep this conversation open>'

agy_interactive="$(PJ_SESSION_MODE=interactive run_named pja 'Keep this conversation open')" || exit 1
assert_contains "$agy_interactive" '<-p>'
assert_contains "$agy_interactive" '<Keep this conversation open>'
assert_contains "$agy_interactive" '<--continue>'

implement_interactive="$(PJ_SESSION_MODE=interactive run_named pj --backend copilot -i)" || exit 1
assert_contains "$implement_interactive" '<-i>'
assert_contains "$implement_interactive" '<Process the Chat implementation queue across the managed repositories in this workspace.'

# The pj-level one-shot override wins even when the environment requests an
# interactive session.
copilot_forced_oneshot="$(PJ_SESSION_MODE=interactive run_named pjcp --oneshot -- 'Exit after this turn')" || exit 1
assert_contains "$copilot_forced_oneshot" '<-p>'
assert_not_contains "$copilot_forced_oneshot" '<-i>'
assert_contains "$copilot_forced_oneshot" '<Exit after this turn>'

agy_forced_oneshot="$(PJ_SESSION_MODE=interactive run_named pja --oneshot -- 'Exit after this turn')" || exit 1
assert_contains "$agy_forced_oneshot" '<-p>'
assert_not_contains "$agy_forced_oneshot" '<--continue>'
assert_contains "$agy_forced_oneshot" '<Exit after this turn>'

codex_alias="$(run_named pjcd Create the issue - with a dash)" || exit 1
assert_contains "$codex_alias" 'codex'
assert_contains "$codex_alias" '<gpt-5.6-luna>'
assert_contains "$codex_alias" '<exec>'
assert_contains "$codex_alias" '<Create the issue - with a dash>'

shown_models="$(run_named pj --show-models)" || exit 1
assert_contains "$shown_models" $'codex\tgpt-5.6-luna'
assert_contains "$shown_models" $'antigravity\tprovider-default'
assert_contains "$shown_models" $'copilot\tmai-code-1.1-flash'

shown_copilot_model="$(run_named pj --show-model copilot)" || exit 1
[ "$shown_copilot_model" = "mai-code-1.1-flash" ] || exit 1

set_copilot_model="$(run_named pj --set-model copilot custom-copilot-model)" || exit 1
[ "$set_copilot_model" = $'copilot\tcustom-copilot-model' ] || exit 1
[ "$(cat "$test_config_home/pj/models/copilot")" = "custom-copilot-model" ] || exit 1
copilot_custom="$(run_named pjcp 'Use configured Copilot model')" || exit 1
assert_contains "$copilot_custom" '<custom-copilot-model>'

set_antigravity_model="$(run_named pj --set-model antigravity gemini-3.8-flash-high)" || exit 1
[ "$set_antigravity_model" = $'antigravity\tgemini-3.8-flash-high' ] || exit 1
agy_custom_model="$(run_named pja 'Use configured Antigravity model')" || exit 1
assert_contains "$agy_custom_model" '<--model>'
assert_contains "$agy_custom_model" '<gemini-3.8-flash-high>'

set_codex_model="$(run_named pj --set-model codex custom-codex-model)" || exit 1
[ "$set_codex_model" = $'codex\tcustom-codex-model' ] || exit 1
codex_custom_model="$(run_named pjcd 'Use configured Codex model')" || exit 1
assert_contains "$codex_custom_model" '<custom-codex-model>'
assert_contains "$codex_custom_model" '<model_reasoning_effort="xhigh">'

copilot_env_model="$(PJ_COPILOT_MODEL=env-copilot-model run_named pjcp 'Use environment Copilot model')" || exit 1
assert_contains "$copilot_env_model" '<env-copilot-model>'

agy_env_model="$(PJ_ANTIGRAVITY_MODEL=env-agy-model run_named pja 'Use environment Antigravity model')" || exit 1
assert_contains "$agy_env_model" '<env-agy-model>'

codex_env_model="$(PJ_CODEX_MODEL=env-codex-model run_named pjcd 'Use environment Codex model')" || exit 1
assert_contains "$codex_env_model" '<env-codex-model>'

reset_agy_model="$(run_named pj --reset-model antigravity)" || exit 1
[ "$reset_agy_model" = $'antigravity\tprovider-default' ] || exit 1
[ ! -e "$test_config_home/pj/models/antigravity" ] || exit 1
agy_after_reset="$(run_named pja 'Use provider default again')" || exit 1
assert_not_contains "$agy_after_reset" '<--model>'

shown_default="$(run_named pj --show-default)" || exit 1
[ "$shown_default" = "codex" ] || exit 1

set_default="$(run_named pj --set-default antigravity)" || exit 1
[ "$set_default" = "antigravity" ] || exit 1
[ "$(cat "$test_config_home/pj/default-backend")" = "antigravity" ] || exit 1

agy_default="$(run_named pj 'Use the configured default')" || exit 1
assert_contains "$agy_default" 'agy'
assert_contains "$agy_default" '<Use the configured default>'

# Explicit shorthands ignore the configured backend default.
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

# Reinstalling preserves backend/model choices and the chosen install directory.
HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$test_bin_dir:$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1
[ "$(cat "$test_config_home/pj/install-bin-dir")" = "$test_bin_dir" ] || exit 1
[ "$(cat "$test_config_home/pj/default-backend")" = "antigravity" ] || exit 1
[ "$(cat "$test_config_home/pj/models/copilot")" = "custom-copilot-model" ] || exit 1
[ "$(cat "$test_config_home/pj/models/codex")" = "custom-codex-model" ] || exit 1
[ ! -e "$test_config_home/pj/models/antigravity" ] || exit 1

# Remove the legacy pjc symlink only when it is the old installer-managed link.
ln -sfn "$test_bin_dir/pj" "$test_bin_dir/pjc" || exit 1
HOME="$tmp/home" XDG_CONFIG_HOME="$test_config_home" PATH="$test_bin_dir:$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1
[ ! -e "$test_bin_dir/pjc" ] || exit 1

# If ~/.local/bin is not on PATH but ~/bin is, select ~/bin.
home_bin_home="$tmp/home-bin"
mkdir -p "$home_bin_home/planning" "$home_bin_home/bin" || exit 1
HOME="$home_bin_home" XDG_CONFIG_HOME="$home_bin_home/.config" PATH="$home_bin_home/bin:$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1
[ -x "$home_bin_home/bin/pj" ] || exit 1
[ "$(cat "$home_bin_home/.config/pj/install-bin-dir")" = "$home_bin_home/bin" ] || exit 1

# If neither standard user bin directory is on PATH or exists, fall back to
# ~/.local/bin and let the installer warn that the chosen directory needs PATH.
fallback_home="$tmp/fallback-home"
mkdir -p "$fallback_home/planning" || exit 1
HOME="$fallback_home" XDG_CONFIG_HOME="$fallback_home/.config" PATH="$tmp/bin:/usr/bin:/bin" bash "$installer" >/dev/null 2>&1 || exit 1
[ -x "$fallback_home/.local/bin/pj" ] || exit 1
[ "$(cat "$fallback_home/.config/pj/install-bin-dir")" = "$fallback_home/.local/bin" ] || exit 1

# PJ_BIN_DIR is the explicit escape hatch and accepts a ~/ prefix.
override_home="$tmp/override-home"
mkdir -p "$override_home/planning" || exit 1
HOME="$override_home" XDG_CONFIG_HOME="$override_home/.config" PJ_BIN_DIR='~/tools/bin' PATH="$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1
[ -x "$override_home/tools/bin/pj" ] || exit 1
[ "$(cat "$override_home/.config/pj/install-bin-dir")" = "$override_home/tools/bin" ] || exit 1

# Migrate the historical ~/bin installer layout when the exact managed symlink
# pattern proves the old files belong to pj. This prevents an old ~/bin/pj from
# shadowing the newly selected ~/.local/bin installation.
migration_home="$tmp/migration-home"
migration_old_bin="$migration_home/bin"
migration_new_bin="$migration_home/.local/bin"
mkdir -p "$migration_home/planning" "$migration_old_bin" "$migration_new_bin" || exit 1
cp "$operator_dir/pj" "$migration_old_bin/pj" || exit 1
chmod +x "$migration_old_bin/pj" || exit 1
ln -s "$migration_old_bin/pj" "$migration_old_bin/pja" || exit 1
ln -s "$migration_old_bin/pj" "$migration_old_bin/pjcp" || exit 1
ln -s "$migration_old_bin/pj" "$migration_old_bin/pjcd" || exit 1
ln -s "$migration_old_bin/pj" "$migration_old_bin/pjc" || exit 1
HOME="$migration_home" XDG_CONFIG_HOME="$migration_home/.config" PATH="$migration_new_bin:$migration_old_bin:$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1
[ -x "$migration_new_bin/pj" ] || exit 1
[ ! -e "$migration_old_bin/pj" ] || exit 1
[ ! -e "$migration_old_bin/pja" ] || exit 1
[ ! -e "$migration_old_bin/pjcp" ] || exit 1
[ ! -e "$migration_old_bin/pjcd" ] || exit 1
[ ! -e "$migration_old_bin/pjc" ] || exit 1
[ "$(cat "$migration_home/.config/pj/install-bin-dir")" = "$migration_new_bin" ] || exit 1

printf 'operator pj tests passed\n'
