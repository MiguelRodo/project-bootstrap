#!/usr/bin/env bash

operator_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
pj="$operator_dir/pj"
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

cat > "$tmp/bin/copilot" <<'EOF'
#!/usr/bin/env bash
printf 'copilot'
for arg in "$@"; do
  printf '\n<%s>' "$arg"
done
printf '\n'
EOF

chmod +x "$tmp/bin/codex" "$tmp/bin/copilot" || exit 1

run_pj() {
  HOME="$tmp/home" \
    PJ_WORKSPACE="$tmp/home/planning" \
    XDG_CONFIG_HOME="$tmp/home/.config" \
    PATH="$tmp/bin:$PATH" \
    "$pj" "$@"
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

# -o is the short pj-level alias for --oneshot.
oneshot="$(PJ_BACKEND=copilot PJ_SESSION_MODE=interactive run_pj -o -- 'Exit after this turn')" || exit 1
assert_contains "$oneshot" 'copilot'
assert_contains "$oneshot" '<-p>'
assert_not_contains "$oneshot" '<-i>'
assert_contains "$oneshot" '<Exit after this turn>'

# Queue mode accepts one optional bare repository selector.
bare_repo="$(PJ_BACKEND=codex run_pj -i issues)" || exit 1
assert_contains "$bare_repo" '<exec>'
assert_contains "$bare_repo" "Restrict queue discovery to the repository selector 'issues'"
assert_contains "$bare_repo" 'local-implementation-queue.md'

# owner/repo is accepted as the exact managed repository selector form.
full_repo="$(PJ_BACKEND=codex run_pj --implement-chat MiguelRodo/projects)" || exit 1
assert_contains "$full_repo" "Restrict queue discovery to the repository selector 'MiguelRodo/projects'"

# No selector preserves the cross-repository queue request.
all_repos="$(PJ_BACKEND=codex run_pj --implement-issues)" || exit 1
assert_contains "$all_repos" 'Process the Chat implementation queue across the managed repositories in this workspace.'
assert_not_contains "$all_repos" 'Restrict queue discovery to the repository selector'

# Queue mode remains intentionally narrow: one validated repository selector.
if PJ_BACKEND=codex run_pj -i issues extra >/dev/null 2>&1; then
  echo 'pj -i unexpectedly accepted more than one repository selector' >&2
  exit 1
fi

if PJ_BACKEND=codex run_pj -i '../issues' >/dev/null 2>&1; then
  echo 'pj -i unexpectedly accepted an invalid repository selector' >&2
  exit 1
fi

printf 'pj queue option tests passed\n'
