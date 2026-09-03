# Project bootstrap

This repository is Miguel's public, end-to-end project bootstrap procedure. It
coordinates four systems without merging their responsibilities:

- Google Drive holds the canonical project description and LLM-oriented source
  material.
- GitHub holds the repository, Project and authoritative work items.
- `MiguelRodo/projects` supplies the reusable `github-project-admin` workflow.
- A private ChatGPT Project provides the conversational workspace.

The bootstrapper creates resources directly when its current environment has
the required authenticated capability. When it cannot make a GitHub change, it
returns the smallest executable `gh` command block and verifies the result after
the user runs it. ChatGPT Project creation remains a verified manual checklist
in version 1.

## Install the skill

With a current GitHub CLI:

```bash
gh skill install MiguelRodo/project-bootstrap project-bootstrap \
  --agent universal --scope user
```

Then ask, for example:

```text
Use $project-bootstrap to set up a new research project called Foobar.
```

The same skill can resume or audit a partial setup:

```text
Use $project-bootstrap to finish setting up Foobar and verify the result.
```

If skill installation is unavailable, point a capable ChatGPT or Codex chat to
this repository and ask it to follow [`PROJECT_BOOTSTRAP.md`](PROJECT_BOOTSTRAP.md).

## One-time local operator launcher

Operator bootstrap is separate from creating an individual project. Run the
installer once per machine from a checkout of this repository:

```bash
bash operator/install.sh
```

It installs `~/bin/pj` and adds a bounded Antigravity pointer to
`~/.gemini/GEMINI.md`. The workspace defaults to `~/planning` and can be changed
with `PJ_WORKSPACE`.

Codex remains the default backend:

```bash
pj "Create the issue - keep this dash as ordinary prompt text"
```

The launcher treats every argument as prompt text when the first argument is
ordinary text. A leading literal `--` also forces all following arguments to be
prompt text. If the first argument is an option, a later `--` separates agent
options from one combined prompt.

Google Antigravity is available through the same launcher after `agy` is
installed and authenticated:

```bash
pj --backend antigravity "Create the issue - keep this dash as text"
PJ_BACKEND=antigravity pj "Review the current project"
pj --backend antigravity --effort medium -- "Review issue #12 - do not edit it"
```

For one-shot Antigravity requests the launcher uses headless `agy -p`, high
reasoning effort by default, the terminal sandbox and automatic tool approval.
The latter is deliberately broad because headless mode cannot stop for tool
approval, so use this operator launcher only for requests you intend the agent
to execute. Repository `AGENTS.md` and `.projects` contracts remain the source
of Project-administration behaviour rather than Antigravity-specific rules.

Run the offline launcher checks with:

```bash
bash operator/tests/run.sh
```

## What a completed setup contains

- `work/projects/<year>/<research|lecturing>/<project-slug>/` in Google Drive;
- a native Google Doc named `README` and a `references/llm/` folder;
- an optional, verified GitHub repository and GitHub Project;
- repository onboarding through `MiguelRodo/projects` when both a repository
  and Project are used;
- a bounded project-resources section in the repository README;
- one verified row in the task system's Projects registry; and
- exact manual steps for creating and checking the private ChatGPT Project.

The full human-readable contract is in
[`PROJECT_BOOTSTRAP.md`](PROJECT_BOOTSTRAP.md). Operational agent instructions
live in [`skills/project-bootstrap/SKILL.md`](skills/project-bootstrap/SKILL.md).

## Repository layout

| Path | Purpose |
| --- | --- |
| `PROJECT_BOOTSTRAP.md` | Human-readable workflow and postconditions. |
| `skills/project-bootstrap/` | Installable Agent Skill. |
| `operator/` | One-time local `pj` operator launcher and installer. |
| `templates/drive-readme.md` | Minimal native Google Doc README shape. |
| `templates/repository-resources.md` | Bounded repository README section. |

No credentials, private Drive identifiers, contact details or project-specific
URLs belong in this public repository.
