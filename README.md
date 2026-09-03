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

It installs three launcher names into `~/bin`:

- `pj` uses Codex by default;
- `pja` selects Google Antigravity;
- `pjc` selects GitHub Copilot CLI.

The installer also adds bounded operator pointers to `~/.gemini/GEMINI.md` and
`~/.copilot/copilot-instructions.md`. The workspace defaults to `~/planning`
and can be changed with `PJ_WORKSPACE`.

The same prompt-parsing rule applies to every backend. When the first argument
is ordinary text, all remaining arguments are combined into prompt text, so
later dash-prefixed fragments stay part of the request. A leading literal `--`
forces all following arguments to be prompt text. If the first argument is an
agent option, a later `--` separates agent options from one combined prompt.

Codex remains the default backend:

```bash
pj "Create the issue - keep this dash as ordinary prompt text"
```

Google Antigravity is available through `pja` after `agy` is installed and
authenticated:

```bash
pja "Create the issue - keep this dash as text"
pja --effort medium -- "Review issue #12 - do not edit it"
```

For one-shot Antigravity requests the launcher uses headless `agy -p`, high
reasoning effort by default, the terminal sandbox and automatic tool approval.
The latter is deliberately broad because headless mode cannot stop for tool
approval, so use this operator launcher only for requests you intend the agent
to execute.

GitHub Copilot CLI is available through `pjc` after `copilot` is installed and
authenticated:

```bash
pjc "Create the issue - keep this dash as text"
pjc --model auto -- "Review issue #12 - do not edit it"
```

For one-shot Copilot requests the launcher uses the official programmatic
`copilot -p` interface and grants all tool, path and URL permissions with
`--allow-all`, matching the unattended operator model used by the other
backends. Set `PJ_COPILOT_MODEL` if a persistent model override is wanted.

The long forms remain available when useful:

```bash
PJ_BACKEND=antigravity pj "Review the current project"
pj --backend copilot "Review the current project"
```

Repository `AGENTS.md` and `.projects` contracts remain the source of
Project-administration behaviour for every backend rather than provider-specific
copies of the task model.

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
| `operator/` | One-time local `pj`/`pja`/`pjc` operator launcher and installer. |
| `templates/drive-readme.md` | Minimal native Google Doc README shape. |
| `templates/repository-resources.md` | Bounded repository README section. |

No credentials, private Drive identifiers, contact details or project-specific
URLs belong in this public repository.
