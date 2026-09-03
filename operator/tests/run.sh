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

HOME="$tmp/home" PATH="$tmp/bin:$PATH" bash "$installer" >/dev/null || exit 1

[ -x "$tmp/home/bin/pj" ] || exit 1
[ -L "$tmp/home/bin/pja" ] || exit 1
[ -L "$tmp/home/bin/pjc" ] || exit 1
grep -q 'pj-managed-projects:start' "$tmp/home/.gemini/GEMINI.md" || exit 1
grep -q 'pj-managed-projects:start' "$tmp/home/.copilot/copilot-instructions.md" || exit 1

run_named() {
  name="$1"
  shift
  HOME="$tmp/home" PATH="$tmp/home/bin:$tmp/bin:$PATH" "$tmp/home/bin/$name" "$@"
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

agy_options="$(run_named pja --model gemini-test -- 'Prompt - with dash')" || exit 1
assert_contains "$agy_options" '<--model>'
assert_contains "$agy_options" '<gemini-test>'
assert_contains "$agy_options" '<-p>'
assert_contains "$agy_options" '<Prompt - with dash>'

copilot_alias="$(run_named pjc Create the issue - with a dash)" || exit 1
assert_contains "$copilot_alias" 'copilot'
assert_contains "$copilot_alias" '<--allow-all>'
assert_contains "$copilot_alias" '<-p>'
assert_contains "$copilot_alias" '<Create the issue - with a dash>'

copilot_options="$(run_named pjc --model test-model -- 'Prompt - with dash')" || exit 1
assert_contains "$copilot_options" '<--model>'
assert_contains "$copilot_options" '<test-model>'
assert_contains "$copilot_options" '<-p>'
assert_contains "$copilot_options" '<Prompt - with dash>'

copilot_env="$(PJ_BACKEND=copilot run_named pj 'Use Copilot from the environment')" || exit 1
assert_contains "$copilot_env" 'copilot'
assert_contains "$copilot_env" '<Use Copilot from the environment>'

printf 'operator pj tests passed\n'
