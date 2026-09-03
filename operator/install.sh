#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
launcher_source="$script_dir/pj"
launcher_dir="$HOME/bin"
launcher_target="$launcher_dir/pj"

mkdir -p "$launcher_dir" || exit 1
install -m 0755 "$launcher_source" "$launcher_target" || exit 1

gemini_dir="$HOME/.gemini"
gemini_context="$gemini_dir/GEMINI.md"
start_marker='<!-- pj-managed-projects:start -->'
end_marker='<!-- pj-managed-projects:end -->'

mkdir -p "$gemini_dir" || exit 1
touch "$gemini_context" || exit 1

tmp_context="$(mktemp)" || exit 1
awk -v start="$start_marker" -v end="$end_marker" '
  $0 == start { in_block = 1; next }
  $0 == end { in_block = 0; next }
  !in_block { print }
' "$gemini_context" > "$tmp_context" || {
  rm -f "$tmp_context"
  exit 1
}

cat >> "$tmp_context" <<'EOF'

<!-- pj-managed-projects:start -->
## GitHub Project administration from `pj`

When `pj` launches Antigravity from the shared planning workspace for a GitHub
issue or Project-administration request, first resolve the target repository and
read and follow that repository's `AGENTS.md`. Let its instructions route you to
the repository's `.projects` contract and shared `github-project-admin` skill.
Do not define a separate Project model for Antigravity.
<!-- pj-managed-projects:end -->
EOF

mv "$tmp_context" "$gemini_context" || exit 1

printf 'Installed pj at %s\n' "$launcher_target"
printf 'Updated Antigravity global context at %s\n' "$gemini_context"

if ! command -v codex >/dev/null 2>&1; then
  printf 'Note: codex is not currently on PATH.\n' >&2
fi

if ! command -v agy >/dev/null 2>&1; then
  printf 'Note: agy is not currently on PATH. Install and authenticate Google Antigravity CLI before using the antigravity backend.\n' >&2
fi

case ":$PATH:" in
  *":$launcher_dir:"*)
    ;;
  *)
    printf 'Note: %s is not currently on PATH. Add it in your shell startup file.\n' "$launcher_dir" >&2
    ;;
esac
