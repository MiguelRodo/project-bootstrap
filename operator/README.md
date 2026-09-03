# Local `pj` operator

`pj` runs the configured local agent against `${PJ_WORKSPACE:-~/planning}`. The backend shorthands are `pja` for Antigravity, `pjcp` for GitHub Copilot CLI and `pjcd` for Codex.

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

Pass one optional repository selector to restrict queue discovery:

```bash
pj -i projects
pj -i issues
pj -i MiguelRodo/projects
```

A bare name such as `issues` matches every managed issue repository with that repository name regardless of owner. Therefore it can intentionally match both `MiguelRodo/issues` and `SATVILab/issues`. An `owner/repo` selector matches that exact managed repository. Matching never broadens beyond repositories already declared by the local managed-project contracts.

Use `-o` before queue mode when a terminal run should exit after the queue-processing turn:

```bash
pj -o -i projects
```

The launcher does not implement GitHub queue discovery itself. It passes the optional selector to the agent, while the canonical matching, trust, mutation and readback rules remain in `github-project-admin`.
