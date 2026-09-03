#!/usr/bin/env bash

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 1
launcher="$root/pj"
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

chmod +x "$tmp/bin/codex" "$tmp/bin/agy" || exit 1

run_pj() {
  HOME="$tmp/home" PATH="$tmp/bin:$PATH" "$launcher" "$@"
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

codex_text="$(run_pj 'Create the issue - but keep this dash as text')" || exit 1
assert_contains "$codex_text" '<Create the issue - but keep this dash as text>'

codex_words="$(run_pj Create the issue - with a dash)" || exit 1
assert_contains "$codex_words" '<Create the issue - with a dash>'

codex_options="$(run_pj --model test-model -- 'Prompt - with dash')" || exit 1
assert_contains "$codex_options" '<--model>'
assert_contains "$codex_options" '<test-model>'
assert_contains "$codex_options" '<Prompt - with dash>'

agy_text="$(run_pj --backend antigravity Create the issue - with a dash)" || exit 1
assert_contains "$agy_text" 'agy'
assert_contains "$agy_text" '<-p>'
assert_contains "$agy_text" '<Create the issue - with a dash>'

agy_options="$(run_pj --backend=antigravity --model gemini-test -- 'Prompt - with dash')" || exit 1
assert_contains "$agy_options" '<--model>'
assert_contains "$agy_options" '<gemini-test>'
assert_contains "$agy_options" '<-p>'
assert_contains "$agy_options" '<Prompt - with dash>'

agy_env="$(PJ_BACKEND=antigravity run_pj 'Use Antigravity from the environment')" || exit 1
assert_contains "$agy_env" 'agy'
assert_contains "$agy_env" '<Use Antigravity from the environment>'

printf 'operator pj tests passed\n'
