#!/usr/bin/env bash

set -euo pipefail

repository=""
create_repository=0
visibility=""
description=""
project_owner=""
project_number=""
project_title=""
create_project=0
apply=0

usage() {
  cat <<'USAGE'
Usage: github-resources.sh [options]

Resolve existing resources:
  --repository OWNER/REPO
  --project-owner OWNER
  --project-number NUMBER
  --project-title TITLE       Optional exact title assertion with --project-number

Create missing resources:
  --create-repository         Create --repository when it is absent
  --visibility VALUE          public, private or internal; required for creation
  --description TEXT          Optional new-repository description
  --create-project            Create an exact --project-title when it is absent
  --apply                     Authorise the requested creates

Without --apply, missing resources requested with --create-* are reported as a
plan and no mutation is made. Existing resources are always read back.
USAGE
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

note() {
  printf '[OK] %s\n' "$*"
}

plan() {
  printf '[PLAN] %s\n' "$*"
}

need_value() {
  [ "$#" -ge 2 ] || die "Missing value for $1"
  [ -n "$2" ] || die "Empty value for $1"
}

clean_single_line() {
  local label="$1" value="$2"
  case "$value" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "$label must be a single line" ;;
  esac
}

print_command() {
  local arg first=1
  for arg in "$@"; do
    if [ "$first" -eq 0 ]; then
      printf ' '
    fi
    printf '%q' "$arg"
    first=0
  done
  printf '\n'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repository)
      need_value "$@"
      repository="$2"
      shift 2
      ;;
    --create-repository)
      create_repository=1
      shift
      ;;
    --visibility)
      need_value "$@"
      visibility="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
      shift 2
      ;;
    --description)
      need_value "$@"
      description="$2"
      shift 2
      ;;
    --project-owner)
      need_value "$@"
      project_owner="$2"
      shift 2
      ;;
    --project-number)
      need_value "$@"
      project_number="$2"
      shift 2
      ;;
    --project-title)
      need_value "$@"
      project_title="$2"
      shift 2
      ;;
    --create-project)
      create_project=1
      shift
      ;;
    --apply)
      apply=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[ -n "$repository" ] || [ -n "$project_owner" ] ||
  die "Specify a repository, a Project owner, or both"

if [ -n "$repository" ]; then
  clean_single_line "Repository" "$repository"
  case "$repository" in
    */*) ;;
    *) die "Repository must use OWNER/REPO form" ;;
  esac
fi

if [ "$create_repository" -eq 1 ]; then
  [ -n "$repository" ] || die "--create-repository requires --repository"
  case "$visibility" in
    public|private|internal) ;;
    *) die "--create-repository requires --visibility public, private or internal" ;;
  esac
fi

if [ -n "$visibility" ]; then
  case "$visibility" in
    public|private|internal) ;;
    *) die "Visibility must be public, private or internal" ;;
  esac
fi

clean_single_line "Description" "$description"
clean_single_line "Project owner" "$project_owner"
clean_single_line "Project title" "$project_title"

if [ -n "$project_number" ]; then
  case "$project_number" in
    *[!0-9]*|'') die "Project number must be a positive integer" ;;
  esac
  [ "$project_number" -gt 0 ] || die "Project number must be a positive integer"
fi

if [ "$create_project" -eq 1 ]; then
  [ -n "$project_owner" ] || die "--create-project requires --project-owner"
  [ -n "$project_title" ] || die "--create-project requires --project-title"
  [ -z "$project_number" ] || die "Do not combine --create-project with --project-number"
fi

if [ -n "$project_owner" ]; then
  [ -n "$project_number" ] || [ -n "$project_title" ] ||
    die "Project resolution requires --project-number or --project-title"
fi

command -v gh >/dev/null 2>&1 || {
  printf '%s\n' "[ERROR] GitHub CLI (gh) is not installed." >&2
  printf '%s\n' "Install it from https://cli.github.com/ and rerun this command." >&2
  exit 2
}

if ! gh auth status >/dev/null 2>&1; then
  printf '%s\n' "[ERROR] GitHub CLI is not authenticated." >&2
  printf '%s\n' 'Run: gh auth login --web --scopes "project,read:org"' >&2
  exit 2
fi

repo_pending=0
project_pending=0

if [ -n "$repository" ]; then
  if gh repo view "$repository" --json nameWithOwner,url,visibility >/dev/null 2>&1; then
    observed_visibility="$(
      gh repo view "$repository" --json visibility --jq .visibility |
        tr '[:upper:]' '[:lower:]'
    )"
    if [ -n "$visibility" ] && [ "$observed_visibility" != "$visibility" ]; then
      die "Repository $repository exists with visibility $observed_visibility, not $visibility"
    fi
    note "Repository exists: $repository"
  elif [ "$create_repository" -eq 0 ]; then
    die "Repository not found: $repository"
  elif [ "$apply" -eq 0 ]; then
    repo_pending=1
    plan "Create repository $repository with visibility $visibility"
  else
    repo_create_args=(repo create "$repository" "--$visibility" --add-readme)
    if [ -n "$description" ]; then
      repo_create_args+=(--description "$description")
    fi

    if gh "${repo_create_args[@]}" >/dev/null; then
      note "Repository create request completed: $repository"
    elif gh repo view "$repository" --json nameWithOwner >/dev/null 2>&1; then
      note "Repository exists after an uncertain create response: $repository"
    else
      die "Repository creation failed and readback did not find $repository"
    fi

    observed_visibility="$(
      gh repo view "$repository" --json visibility --jq .visibility |
        tr '[:upper:]' '[:lower:]'
    )"
    [ "$observed_visibility" = "$visibility" ] ||
      die "Repository readback returned visibility $observed_visibility, not $visibility"
  fi
fi

find_project_numbers_by_title() {
  local rows number title
  rows="$(
    gh project list \
      --owner "$project_owner" \
      --closed \
      --limit 1000 \
      --format json \
      --jq '.projects[] | [.number, .title] | @tsv'
  )"

  while IFS=$'\t' read -r number title; do
    [ -n "$number" ] || continue
    if [ "$title" = "$project_title" ]; then
      printf '%s\n' "$number"
    fi
  done <<EOF
$rows
EOF
}

if [ -n "$project_owner" ]; then
  if [ -n "$project_number" ]; then
    if ! gh project view "$project_number" --owner "$project_owner" --format json >/dev/null 2>&1; then
      die "Project not found: $project_owner #$project_number"
    fi
    observed_title="$(
      gh project view "$project_number" \
        --owner "$project_owner" \
        --format json \
        --jq .title
    )"
    if [ -n "$project_title" ] && [ "$observed_title" != "$project_title" ]; then
      die "Project $project_owner #$project_number is titled '$observed_title', not '$project_title'"
    fi
    project_title="$observed_title"
    note "Project exists: $project_owner #$project_number ($project_title)"
  else
    matches="$(find_project_numbers_by_title)"
    match_count=0
    matched_number=""
    while IFS= read -r number; do
      [ -n "$number" ] || continue
      match_count=$((match_count + 1))
      matched_number="$number"
    done <<EOF
$matches
EOF

    if [ "$match_count" -gt 1 ]; then
      die "More than one Project owned by $project_owner is titled '$project_title'; supply --project-number"
    elif [ "$match_count" -eq 1 ]; then
      project_number="$matched_number"
      note "Project exists: $project_owner #$project_number ($project_title)"
    elif [ "$create_project" -eq 0 ]; then
      die "Project not found for $project_owner with title '$project_title'"
    elif [ "$apply" -eq 0 ]; then
      project_pending=1
      plan "Create Project '$project_title' for $project_owner"
    else
      if project_number="$(
        gh project create \
          --owner "$project_owner" \
          --title "$project_title" \
          --format json \
          --jq .number
      )"; then
        note "Project create request completed: $project_owner #$project_number"
      else
        matches="$(find_project_numbers_by_title)"
        match_count=0
        matched_number=""
        while IFS= read -r number; do
          [ -n "$number" ] || continue
          match_count=$((match_count + 1))
          matched_number="$number"
        done <<EOF
$matches
EOF
        if [ "$match_count" -eq 1 ]; then
          project_number="$matched_number"
          note "Project exists after an uncertain create response: $project_owner #$project_number"
        else
          die "Project creation failed and exact-title readback was not unique"
        fi
      fi

      observed_title="$(
        gh project view "$project_number" \
          --owner "$project_owner" \
          --format json \
          --jq .title
      )"
      [ "$observed_title" = "$project_title" ] ||
        die "Project readback returned '$observed_title', not '$project_title'"
    fi
  fi
fi

if [ "$repo_pending" -eq 1 ] || [ "$project_pending" -eq 1 ]; then
  printf '\nCommands that would be run after authorisation:\n'
  if [ "$repo_pending" -eq 1 ]; then
    repo_plan_args=(gh repo create "$repository" "--$visibility" --add-readme)
    if [ -n "$description" ]; then
      repo_plan_args+=(--description "$description")
    fi
    print_command "${repo_plan_args[@]}"
    print_command gh repo view "$repository" --json nameWithOwner,url,visibility,defaultBranchRef
  fi
  if [ "$project_pending" -eq 1 ]; then
    print_command gh project create --owner "$project_owner" --title "$project_title" --format json
    print_command gh project list --owner "$project_owner" --closed --limit 1000 --format json
  fi
  printf '\nNo GitHub resource was created. Rerun with --apply after authorisation.\n'
  exit 0
fi

printf '\nVerified GitHub readback:\n'
if [ -n "$repository" ]; then
  gh repo view "$repository" \
    --json nameWithOwner,url,visibility,defaultBranchRef
fi
if [ -n "$project_number" ]; then
  gh project view "$project_number" \
    --owner "$project_owner" \
    --format json
fi
