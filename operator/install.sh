#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
launcher_source="$script_dir/pj"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_home/pj"
default_backend_file="$config_dir/default-backend"
install_bin_dir_file="$config_dir/install-bin-dir"

path_contains_dir() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *) return 1 ;;
  esac
}

expand_home_path() {
  case "$1" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${1#~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

choose_launcher_dir() {
  if [ -n "${PJ_BIN_DIR:-}" ]; then
    explicit_dir="$(expand_home_path "$PJ_BIN_DIR")" || return 1
    case "$explicit_dir" in
      /*) ;;
      *)
        printf 'pj installer: PJ_BIN_DIR must resolve to an absolute path: %s\n' "$PJ_BIN_DIR" >&2
        return 2
        ;;
    esac
    printf '%s\n' "$explicit_dir"
    return
  fi

  # Prefer standard per-user executable directories that already work in the
  # current shell. ~/.local/bin is the conventional first choice; ~/bin stays
  # supported for environments that already use it.
  for candidate in "$HOME/.local/bin" "$HOME/bin"; do
    if path_contains_dir "$candidate"; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  # If neither is currently on PATH, prefer an existing standard directory.
  for candidate in "$HOME/.local/bin" "$HOME/bin"; do
    if [ -d "$candidate" ]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  # New environments default to the freedesktop-style user-local location.
  printf '%s\n' "$HOME/.local/bin"
}

launcher_dir="$(choose_launcher_dir)" || exit $?
launcher_target="$launcher_dir/pj"
antigravity_target="$launcher_dir/pja"
copilot_target="$launcher_dir/pjcp"
codex_target="$launcher_dir/pjcd"
legacy_copilot_target="$launcher_dir/pjc"

mkdir -p "$launcher_dir" "$config_dir" || exit 1

managed_aliases_point_to() {
  target="$1"
  shift
  for alias_path in "$@"; do
    [ -L "$alias_path" ] || return 1
    [ "$(readlink "$alias_path")" = "$target" ] || return 1
  done
}

remove_previous_managed_install() {
  previous_dir="$1"
  [ -n "$previous_dir" ] || return 0
  [ "$previous_dir" != "$launcher_dir" ] || return 0

  previous_target="$previous_dir/pj"
  previous_pja="$previous_dir/pja"
  previous_pjcp="$previous_dir/pjcp"
  previous_pjcd="$previous_dir/pjcd"
  previous_pjc="$previous_dir/pjc"

  # Only treat the directory as installer-managed when all three current
  # shorthand symlinks point at its pj launcher. This avoids deleting unrelated
  # user files while still allowing safe migration away from an older install.
  if managed_aliases_point_to "$previous_target" \
      "$previous_pja" "$previous_pjcp" "$previous_pjcd"; then
    rm -f "$previous_pja" "$previous_pjcp" "$previous_pjcd" || exit 1
    if [ -L "$previous_pjc" ] && [ "$(readlink "$previous_pjc")" = "$previous_target" ]; then
      rm -f "$previous_pjc" || exit 1
    fi
    rm -f "$previous_target" || exit 1
    printf 'Removed previous managed pj install from %s\n' "$previous_dir"
  fi
}

if [ -f "$install_bin_dir_file" ]; then
  previous_launcher_dir=""
  IFS= read -r previous_launcher_dir < "$install_bin_dir_file" || true
  remove_previous_managed_install "$previous_launcher_dir"
elif [ "$launcher_dir" != "$HOME/bin" ]; then
  # Migrate the historical pre-tracking installer layout when its managed
  # symlink pattern proves that ~/bin contains the old pj installation.
  remove_previous_managed_install "$HOME/bin"
fi

install -m 0755 "$launcher_source" "$launcher_target" || exit 1
ln -sfn "$launcher_target" "$antigravity_target" || exit 1
ln -sfn "$launcher_target" "$copilot_target" || exit 1
ln -sfn "$launcher_target" "$codex_target" || exit 1

# Remove the previously managed `pjc` Copilot shorthand only when it is still
# the symlink created by this installer. Never remove an unrelated user file.
if [ -L "$legacy_copilot_target" ] && [ "$(readlink "$legacy_copilot_target")" = "$launcher_target" ]; then
  rm -f "$legacy_copilot_target" || exit 1
fi

printf '%s\n' "$launcher_dir" > "$install_bin_dir_file" || exit 1

# Preserve an existing configured default across reinstalls. New installs start
# with Codex until the operator selects another backend.
if [ ! -f "$default_backend_file" ]; then
  printf 'codex\n' > "$default_backend_file" || exit 1
fi

start_marker='<!-- pj-managed-projects:start -->'
end_marker='<!-- pj-managed-projects:end -->'

gemini_dir="$HOME/.gemini"
gemini_context="$gemini_dir/GEMINI.md"
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

When `pja` or `pj --backend antigravity` launches Antigravity from the shared
planning workspace for a GitHub issue or Project-administration request, first
resolve the target repository and read and follow that repository's `AGENTS.md`.
Let its instructions route you to the repository's `.projects` contract and
shared `github-project-admin` skill. Do not define a separate Project model for
Antigravity.
<!-- pj-managed-projects:end -->
EOF

mv "$tmp_context" "$gemini_context" || exit 1

copilot_dir="$HOME/.copilot"
copilot_context="$copilot_dir/copilot-instructions.md"
mkdir -p "$copilot_dir" || exit 1
touch "$copilot_context" || exit 1

tmp_context="$(mktemp)" || exit 1
awk -v start="$start_marker" -v end="$end_marker" '
  $0 == start { in_block = 1; next }
  $0 == end { in_block = 0; next }
  !in_block { print }
' "$copilot_context" > "$tmp_context" || {
  rm -f "$tmp_context"
  exit 1
}

cat >> "$tmp_context" <<'EOF'

<!-- pj-managed-projects:start -->
## GitHub Project administration from `pj`

When `pjcp` or `pj --backend copilot` launches GitHub Copilot CLI from the shared
planning workspace for a GitHub issue or Project-administration request, first
resolve the target repository and read and follow that repository's `AGENTS.md`.
Let its instructions route you to the repository's `.projects` contract and
shared `github-project-admin` skill. Do not define a separate Project model for
Copilot.
<!-- pj-managed-projects:end -->
EOF

mv "$tmp_context" "$copilot_context" || exit 1

printf 'Installed pj at %s\n' "$launcher_target"
printf 'Installed pja -> pj at %s\n' "$antigravity_target"
printf 'Installed pjcp -> pj at %s\n' "$copilot_target"
printf 'Installed pjcd -> pj at %s\n' "$codex_target"
printf 'Recorded pj install directory in %s\n' "$install_bin_dir_file"
printf 'Configured pj default backend in %s\n' "$default_backend_file"
printf 'Updated Antigravity global context at %s\n' "$gemini_context"
printf 'Updated Copilot global context at %s\n' "$copilot_context"

if ! command -v codex >/dev/null 2>&1; then
  printf 'Note: codex is not currently on PATH.\n' >&2
fi

if ! command -v agy >/dev/null 2>&1; then
  printf 'Note: agy is not currently on PATH. Install and authenticate Google Antigravity CLI before using pja.\n' >&2
fi

if ! command -v copilot >/dev/null 2>&1; then
  printf 'Note: copilot is not currently on PATH. Install and authenticate GitHub Copilot CLI before using pjcp.\n' >&2
fi

if ! path_contains_dir "$launcher_dir"; then
  printf 'Note: %s is not currently on PATH. Add it in your shell startup file or rerun with PJ_BIN_DIR set to a suitable user bin directory.\n' "$launcher_dir" >&2
fi
