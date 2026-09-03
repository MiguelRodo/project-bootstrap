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

It installs four launcher names into `~/bin`:

- `pj` uses the configured default backend;
- `pja` always selects Google Antigravity;
- `pjcp` always selects GitHub Copilot CLI;
- `pjcd` always selects Codex.

A new install starts with Codex as the `pj` default. Change or inspect that saved
default with:

```bash
pj --set-default antigravity
pj --set-default copilot
pj --set-default codex
pj --show-default
```

The saved choice lives at `${XDG_CONFIG_HOME:-~/.config}/pj/default-backend` and
is preserved when the installer is rerun. `PJ_DEFAULT_BACKEND` can override the
saved default for the current environment, while `PJ_BACKEND` remains the
one-run generic `pj` override. An explicit `--backend` flag has the highest
precedence and can also override a shorthand launcher.

### Per-backend model defaults

`pj` also keeps model selection separate for each backend. The built-in model
defaults are:

- Codex: `gpt-5.6-luna`, with the existing `xhigh` reasoning effort;
- GitHub Copilot CLI: `mai-code-1.1-flash` (MAI-Code-1.1-Flash);
- Google Antigravity: no `pj` model pin, so Antigravity follows its own current
  or configured default model instead of freezing the launcher to one Flash
  release.

Inspect all effective model defaults or one backend with:

```bash
pj --show-models
pj --show-model copilot
```

Save a different default for a backend with:

```bash
pj --set-model copilot gpt-5.6-terra
pj --set-model codex gpt-5.6-luna
pj --set-model antigravity gemini-3.8-flash-high
```

Saved model choices live under `${XDG_CONFIG_HOME:-~/.config}/pj/models/` and
are preserved across installer reruns. Reset one backend to the built-in `pj`
default with:

```bash
pj --reset-model copilot
pj --reset-model codex
pj --reset-model antigravity
```

Resetting Antigravity removes the launcher-level model pin and returns it to the
provider's own current/default model. This is intentional: when the desired
behaviour is simply "use the current Flash default", leaving Antigravity
unpinned allows provider updates to advance that choice without editing `pj`.

The per-backend environment variables `PJ_CODEX_MODEL`,
`PJ_ANTIGRAVITY_MODEL`, and `PJ_COPILOT_MODEL` override saved model choices for
the current environment. Backend-native model flags also remain available for
one run by placing options before a literal `--`, for example:

```bash
pja --model gemini-3.8-flash-medium -- "Review issue #12"
pjcp --model gpt-5.6-terra -- "Review issue #12"
pjcd -m gpt-5.6-sol -- "Review issue #12"
```

The installer also adds bounded operator pointers to `~/.gemini/GEMINI.md` and
`~/.copilot/copilot-instructions.md`. The workspace defaults to `~/planning`
and can be changed with `PJ_WORKSPACE`.

The same prompt-parsing rule applies to every backend. When the first argument
is ordinary text, all remaining arguments are combined into prompt text, so
later dash-prefixed fragments stay part of the request. A leading literal `--`
forces all following arguments to be prompt text. If the first argument is an
agent option, a later `--` separates agent options from one combined prompt.

For example, whatever backend `pj` currently defaults to receives this whole
request as prompt text:

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
reasoning effort by default and automatic tool approval. Ordinary `pja` runs do
not force the terminal sandbox because Project administration needs live `gh`
and provider API access; request `--sandbox` explicitly when that restriction is
wanted. Headless runs use a 15-minute response timeout by default, configurable
with `PJ_ANTIGRAVITY_TIMEOUT` or a one-run `--print-timeout` option. Automatic
tool approval is deliberately broad because headless mode cannot stop for tool
approval, so use this operator launcher only for requests you intend the agent
to execute.

GitHub Copilot CLI is available through `pjcp` after `copilot` is installed and
authenticated:

```bash
pjcp "Create the issue - keep this dash as text"
pjcp --model auto -- "Review issue #12 - do not edit it"
```

For one-shot Copilot requests the launcher uses the official programmatic
`copilot -p` interface and grants all tool, path and URL permissions with
`--allow-all`, matching the unattended operator model used by the other
backends.

Codex remains directly available through `pjcd` regardless of the saved `pj`
default:

```bash
pjcd "Review the current project"
```

The long forms remain available when useful:

```bash
PJ_DEFAULT_BACKEND=antigravity pj "Review the current project"
PJ_BACKEND=copilot pj "Review the current project"
pj --backend codex "Review the current project"
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
| `operator/` | One-time local `pj`/`pja`/`pjcp`/`pjcd` operator launcher and installer. |
| `templates/drive-readme.md` | Minimal native Google Doc README shape. |
| `templates/repository-resources.md` | Bounded repository README section. |

No credentials, private Drive identifiers, contact details or project-specific
URLs belong in this public repository.
