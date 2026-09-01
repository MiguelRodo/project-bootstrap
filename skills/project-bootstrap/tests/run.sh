#!/usr/bin/env bash

set -euo pipefail

skill_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
script="$skill_root/scripts/github-resources.sh"
fake_bin="$skill_root/tests/fixtures/bin"
test_root="$(mktemp -d)"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1" needle="$2"
  case "$haystack" in
    *"$needle"*) ;;
    *) fail "Expected output to contain: $needle" ;;
  esac
}

new_case() {
  local name="$1"
  case_dir="$test_root/$name"
  mkdir -p "$case_dir/state"
  : >"$case_dir/gh.log"
}

run_helper() {
  FAKE_GH_STATE="$case_dir/state" \
  FAKE_GH_LOG="$case_dir/gh.log" \
  PATH="$fake_bin:$PATH" \
    bash "$script" "$@"
}

bash -n "$script"
bash -n "$fake_bin/gh"

new_case existing
printf 'octo/demo\tPUBLIC\thttps://github.com/octo/demo\n' \
  >"$case_dir/state/repo.tsv"
printf '4\tAlpha\thttps://github.com/users/octo/projects/4\n' \
  >"$case_dir/state/projects.tsv"
output="$(
  run_helper \
    --repository octo/demo \
    --project-owner octo \
    --project-number 4 \
    --project-title Alpha
)"
assert_contains "$output" "Repository exists: octo/demo"
assert_contains "$output" "Project exists: octo #4 (Alpha)"
assert_contains "$output" '"visibility":"PUBLIC"'
if grep -Fq 'repo create' "$case_dir/gh.log"; then
  fail "Existing repository path attempted a create"
fi
if grep -Fq 'project create' "$case_dir/gh.log"; then
  fail "Existing Project path attempted a create"
fi

new_case plan
output="$(
  run_helper \
    --repository octo/new-demo \
    --create-repository \
    --visibility public \
    --description "Demo repository" \
    --project-owner octo \
    --project-title "New Project" \
    --create-project
)"
assert_contains "$output" "Create repository octo/new-demo"
assert_contains "$output" "Create Project 'New Project' for octo"
assert_contains "$output" "No GitHub resource was created"
[ ! -e "$case_dir/state/repo.tsv" ] || fail "Plan mode created a repository"
[ ! -e "$case_dir/state/projects.tsv" ] || fail "Plan mode created a Project"
if grep -Fq 'repo create' "$case_dir/gh.log"; then
  fail "Plan mode invoked repository creation"
fi
if grep -Fq 'project create' "$case_dir/gh.log"; then
  fail "Plan mode invoked Project creation"
fi

new_case apply
output="$(
  run_helper \
    --repository octo/new-demo \
    --create-repository \
    --visibility private \
    --description "Demo repository" \
    --project-owner octo \
    --project-title "New Project" \
    --create-project \
    --apply
)"
assert_contains "$output" "Repository create request completed: octo/new-demo"
assert_contains "$output" "Project create request completed: octo #7"
assert_contains "$output" '"visibility":"PRIVATE"'
grep -Fq 'repo create' "$case_dir/gh.log" || fail "Apply mode did not create repository"
grep -Fq 'project create' "$case_dir/gh.log" || fail "Apply mode did not create Project"

new_case visibility
printf 'octo/demo\tPUBLIC\thttps://github.com/octo/demo\n' \
  >"$case_dir/state/repo.tsv"
if run_helper \
  --repository octo/demo \
  --create-repository \
  --visibility private \
  >"$case_dir/output" 2>&1; then
  fail "Visibility mismatch was accepted"
fi
grep -Fq 'exists with visibility public, not private' "$case_dir/output" ||
  fail "Visibility mismatch did not explain the conflict"

new_case duplicate
printf '4\tAlpha\thttps://github.com/users/octo/projects/4\n5\tAlpha\thttps://github.com/users/octo/projects/5\n' \
  >"$case_dir/state/projects.tsv"
if run_helper \
  --project-owner octo \
  --project-title Alpha \
  >"$case_dir/output" 2>&1; then
  fail "Duplicate exact Project titles were accepted"
fi
grep -Fq 'supply --project-number' "$case_dir/output" ||
  fail "Duplicate Project error did not request a number"

for required_file in \
  "$skill_root/references/github.md" \
  "$skill_root/references/drive-and-registry.md" \
  "$skill_root/references/chatgpt-project.md" \
  "$skill_root/references/verification.md"; do
  [ -s "$required_file" ] || fail "Required skill reference is missing: $required_file"
done

printf 'All project-bootstrap tests passed.\n'
