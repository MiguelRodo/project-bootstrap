# Local `pj` operator

`pj` runs the configured local agent against `${PJ_WORKSPACE:-~/planning}`. The backend shorthands are `pja` for Antigravity, `pjcp` for GitHub Copilot CLI and `pjcd` for Codex.

The installer maintains a bounded `pj` block in `${PJ_WORKSPACE:-~/planning}/AGENTS.md`. That workspace-level file gives every backend the same natural-language GitHub task and Project vocabulary for conversational follow-ups. It tells the agent to resolve the target managed repository, read that repository's own `AGENTS.md` and `.projects` contract, follow `github-project-admin`, and independently verify mutations. Content outside the managed block is preserved on reinstall.

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
