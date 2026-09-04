# Local `pj` operator

`pj` runs the configured local agent against `${PJ_WORKSPACE:-~/planning}`. The backend shorthands are `pja` for Antigravity, `pjcp` for GitHub Copilot CLI and `pjcd` for Codex.

`pj` is not an alias for the optional `projects` Go CLI. The launcher chooses an
agent and keeps its conversation open; `projects` handles supported deterministic
GitHub Project operations. An agent started by `pj` may use that binary when it
is installed, then follow the repository scripts or direct GitHub path when it
is not. See the
[`projects` CLI guide](https://github.com/MiguelRodo/projects/blob/main/docs/cli.md)
for installation and read-only update checks.

The installer maintains bounded `pj` blocks in `~/AGENTS.md` and `${PJ_WORKSPACE:-~/planning}/AGENTS.md`. The home-level file is the canonical cross-agent user guidance: it tells agents about local operator maintenance, including the shared skill updater, and contains user-level rules that should apply regardless of backend. The workspace-level file gives every backend the same natural-language GitHub task and Project vocabulary for conversational follow-ups. It tells the agent to resolve the target managed repository, read that repository's own `AGENTS.md` and `.projects` contract, follow `github-project-admin`, and independently verify mutations. Content outside the managed blocks is preserved on reinstall.

Where it is safe to do so, the installer links each backend's documented user-level instruction entrypoint back to the same canonical `~/AGENTS.md`:

```text
~/.codex/AGENTS.md                  -> ~/AGENTS.md
~/.copilot/copilot-instructions.md -> ~/AGENTS.md
~/.gemini/GEMINI.md                -> ~/AGENTS.md
```

The installer chooses the least surprising migration for each backend entrypoint:

- an absent, empty or installer-owned file becomes a symlink to `~/AGENTS.md`;
- a regular file with genuine backend-specific content remains a regular file,
  keeps that content and its mode, and receives one hard-updated copy of the
  canonical managed block at the existing block position; and
- an unrelated symlink or non-file path is preserved unchanged and reported.

Known older installer-managed blocks are removed during either migration. A
reinstall refreshes, rather than duplicates, the managed block. This lets a
straightforward installation use one physical file while respecting an existing
backend-specific arrangement.

`~/AGENTS.md`, the workspace `AGENTS.md` and the Codex rules file may themselves
be symlinks into a dotfiles checkout. The installer writes through those links,
keeps them in place and preserves each target file's mode. It stops on a broken
managed-file or backend instruction symlink, because success would otherwise be
misleading.

## Optional `agy` delegation

The canonical home guidance advertises `agy` as an opt-in external subagent to Codex and GitHub Copilot CLI only. Antigravity itself must not invoke `agy` recursively under this facility. Codex or Copilot may delegate bounded mechanical or investigative work only after the operator explicitly authorises `agy` for the current task or conversation. Conversation-level authorisation covers repeated useful calls without repeated prompts. The default delegated model is `gemini-3.8-flash-high`; the primary agent remains responsible for design, consequential decisions, verification and integration.

Delegated repository inspection should pass the repository explicitly, for
example:

```bash
agy -p "<self-contained delegated task>" \
  --model gemini-3.8-flash-high \
  --add-dir "/absolute/repository/root"
```

`--add-dir` registers the repository as an Antigravity workspace instead of
requiring a broad global file-read permission.

The installer also maintains a bounded Codex exec-policy rule in `~/.codex/rules/default.rules` allowing the `agy` executable. The natural-language opt-in rule in `~/AGENTS.md` still controls when Codex may choose to use it.

GitHub Copilot CLI does not currently expose an equivalent documented machine-wide user shell-command allow-list. Direct Copilot sessions may therefore ask for approval the first time they invoke `agy` in a repository or directory; that approval can be persisted for the current location by Copilot. `pjcp` already runs with its own explicit broad tool approval, so no additional launcher permission is needed there.

Antigravity headless runs deliberately keep their own normal permission policy. Workspace file reads and writes are available under Antigravity's normal rules, while shell commands or other gated tools may be soft-denied in headless mode. Once delegation is authorised, the primary agent may satisfy an exact, narrowly scoped permission request on the operator's behalf when its harness permits, while preserving existing settings. It should report the requested rule only when it cannot grant it safely. Broad wildcard permissions and `--dangerously-skip-permissions` still require separate explicit operator authorisation.

That means that once you are already inside a `pj`-launched agent session, ordinary follow-ups such as these should be enough:

```text
Add an issue to work that I need to do X, P3.
Process the implementation issues for MIMOSA-STAN.
Set the issue we just created to P2 instead.
```

The workspace file is only a dispatcher. Repository-level `AGENTS.md`, `.projects` contracts and live GitHub state remain authoritative for target-specific behaviour.

Prompt-launched terminal sessions are conversational by default. Use `-o` (or `--oneshot`) before agent-specific options or prompt text to force a single-turn run:

```bash
pj -o "Update the issue and verify it"
pjcp -o -- "Check this Project state once"
```

## Update the shared Project skill everywhere

The installer also provides:

```bash
pj-update-skills
```

Run it when you want to refresh `github-project-admin` across the managed repositories under `${PJ_WORKSPACE:-~/planning}`. The updater:

1. temporarily stashes existing local work in each repository;
2. fetches upstream changes and uses an explicit non-fast-forward merge when the upstream is not already contained locally;
3. runs `gh skill update github-project-admin --all` in repositories with the installed skill;
4. commits only the resulting skill refresh as `Update github-project-admin skill`;
5. pushes the current branch; and
6. restores the local work it temporarily stashed.

The canonical `projects` repository is synced but is not asked to update an installed copy of its own skill. A repository that cannot merge, update, push or restore its stash is reported as a failure rather than silently treated as successful.

Agents launched under the home or planning `AGENTS.md` guidance are told to use `pj-update-skills` when the operator explicitly asks them to update the shared skill across local repositories, instead of building another one-off shell loop.

## Chat implementation queue

These are equivalent:

```bash
pj -i
pj --implement-issues
pj --implement-chat
```

They ask the selected backend to process trusted `pj:implement-chat` handoff issues using `github-project-admin` and the managed repositories discovered from local `.projects` contracts.

Pass one optional repository selector with `-r` or `--repo` to restrict queue discovery:

```bash
pj -i -r projects
pj -i --repo issues
pj -i --repo MiguelRodo/projects
```

A bare selector value such as `issues` matches every managed issue repository with that repository name regardless of owner. Therefore it can intentionally match both `MiguelRodo/issues` and `SATVILab/issues`. An `owner/repo` selector matches that exact managed repository. Matching never broadens beyond repositories already declared by the local managed-project contracts.

Use `-o` before queue mode when a terminal run should exit after the queue-processing turn:

```bash
pj -o -i -r projects
```

The launcher does not implement GitHub queue discovery itself. It validates and passes the optional selector to the agent, while the canonical matching, trust, mutation and readback rules remain in `github-project-admin`.
