#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
launcher_source="$script_dir/pj"
skill_update_source="$script_dir/update-managed-skills.sh"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_home/pj"
default_backend_file="$config_dir/default-backend"
install_bin_dir_file="$config_dir/install-bin-dir"
workspace="${PJ_WORKSPACE:-$HOME/planning}"

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
      printf '%s/%s\n' "$HOME" "${1:2}"
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
skill_update_target="$launcher_dir/pj-update-skills"
legacy_copilot_target="$launcher_dir/pjc"

mkdir -p "$launcher_dir" "$config_dir" "$workspace" || exit 1

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
  previous_skill_update="$previous_dir/pj-update-skills"
  previous_pjc="$previous_dir/pjc"

  # Only treat the directory as installer-managed when all three current
  # shorthand symlinks point at its pj launcher. This avoids deleting unrelated
  # user files while still allowing safe migration away from an older install.
  if managed_aliases_point_to "$previous_target" \
      "$previous_pja" "$previous_pjcp" "$previous_pjcd"; then
    rm -f "$previous_pja" "$previous_pjcp" "$previous_pjcd" || exit 1
    rm -f "$previous_skill_update" || exit 1
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
install -m 0755 "$skill_update_source" "$skill_update_target" || exit 1
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

update_managed_context() {
  target="$1"
  target_dir="$(dirname "$target")"
  mkdir -p "$target_dir" || return 1
  touch "$target" || return 1

  tmp_context="$(mktemp)" || return 1
  awk -v start="$start_marker" -v end="$end_marker" '
    $0 == start { in_block = 1; next }
    $0 == end { in_block = 0; next }
    !in_block { print }
  ' "$target" > "$tmp_context" || {
    rm -f "$tmp_context"
    return 1
  }

  cat >> "$tmp_context" || {
    rm -f "$tmp_context"
    return 1
  }
  mv "$tmp_context" "$target" || return 1
}

home_context="$HOME/AGENTS.md"
update_managed_context "$home_context" <<'EOF'

<!-- pj-managed-projects:start -->
## Local `pj` operator maintenance

The shared local planning workspace is `${PJ_WORKSPACE:-~/planning}`. When the
operator explicitly asks to update or refresh the installed
`github-project-admin` skill across the managed repositories in that workspace,
run `pj-update-skills` rather than constructing an ad hoc repository loop.

`pj-update-skills` temporarily stashes pre-existing local work, fetches and
merges upstream changes with an explicit merge commit when needed, updates the
installed `github-project-admin` skill non-interactively, commits only the skill
refresh, pushes the branch and restores the operator's previous local work. It
skips the installed-skill refresh in the canonical `projects` source repository.
If a repository fails to merge, update, push or restore its stash, report the
exact repository and error rather than claiming the whole update succeeded.

For ordinary GitHub task and Project administration, continue into the planning
workspace and follow its `AGENTS.md`, then the resolved repository's own
`AGENTS.md` and `.projects` contract. This home-level block is operator routing,
not a replacement for repository-specific guidance.
<!-- pj-managed-projects:end -->
EOF

workspace_context="$workspace/AGENTS.md"
update_managed_context "$workspace_context" <<'EOF'

<!-- pj-managed-projects:start -->
## Shared `pj` planning workspace

This directory is the shared local operator workspace used by `pj`. Natural-language
requests to add, update, close or organise GitHub issues, change GitHub Project
fields or membership, or process Chat implementation queue items are GitHub task
and Project-administration requests unless the operator explicitly asks for
repository code changes.

For each such request:

1. resolve the target only from the managed repositories and `.projects`
   contracts available in this workspace;
2. read and follow the target repository's root `AGENTS.md`;
3. read `.projects/project.md` plus the one Project contract it resolves and use
   the shared `github-project-admin` skill named by the repository guidance;
4. interpret ordinary phrases such as "add an issue to X", "set this to P3" or
   "process the implementation issues for X" through those checked contracts
   rather than inventing provider-specific task logic;
5. preserve unrelated state, stop on consequential ambiguity, and independently
   read back every completed GitHub mutation before reporting success.

If the operator explicitly asks to update or refresh `github-project-admin`
across the local managed repositories, use `pj-update-skills`. Do not recreate a
one-off loop unless that installed updater is unavailable. Treat this as local
operator maintenance rather than an issue or Project mutation.

For implementation-queue requests, follow `github-project-admin`'s
`references/local-implementation-queue.md`, including its trust and review rules.
A repository or Project name supplied by the operator narrows resolution to the
corresponding managed target; do not broaden to arbitrary accessible repositories.

This workspace-level guidance is only a dispatcher. A target repository's own
`AGENTS.md`, `.projects` contract and current GitHub state remain authoritative
for that target.
<!-- pj-managed-projects:end -->
EOF

gemini_context="$HOME/.gemini/GEMINI.md"
update_managed_context "$gemini_context" <<'EOF'

<!-- pj-managed-projects:start -->
## GitHub Project administration from `pj`

When `pja` or `pj --backend antigravity` launches Antigravity in the shared
planning workspace, read and follow the workspace `AGENTS.md` first. For a
resolved GitHub target, then follow that repository's own `AGENTS.md`, `.projects`
contract and shared `github-project-admin` guidance. Do not define a separate
Antigravity task or Project model.
<!-- pj-managed-projects:end -->
EOF

copilot_context="$HOME/.copilot/copilot-instructions.md"
update_managed_context "$copilot_context" <<'EOF'

<!-- pj-managed-projects:start -->
## GitHub Project administration from `pj`

When `pjcp` or `pj --backend copilot` launches GitHub Copilot CLI in the shared
planning workspace, read and follow the workspace `AGENTS.md` first. For a
resolved GitHub target, then follow that repository's own `AGENTS.md`, `.projects`
contract and shared `github-project-admin` guidance. Do not define a separate
Copilot task or Project model.
<!-- pj-managed-projects:end -->
EOF

printf 'Installed pj at %s\n' "$launcher_target"
printf 'Installed pja -> pj at %s\n' "$antigravity_target"
printf 'Installed pjcp -> pj at %s\n' "$copilot_target"
printf 'Installed pjcd -> pj at %s\n' "$codex_target"
printf 'Installed pj-update-skills at %s\n' "$skill_update_target"
printf 'Recorded pj install directory in %s\n' "$install_bin_dir_file"
printf 'Configured pj default backend in %s\n' "$default_backend_file"
printf 'Updated home agent guidance at %s\n' "$home_context"
printf 'Updated shared workspace guidance at %s\n' "$workspace_context"
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
