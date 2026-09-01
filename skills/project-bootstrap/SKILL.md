---
name: project-bootstrap
description: Create, resume or audit Miguel's end-to-end research and lecturing project setup across Google Drive, GitHub, the task-system registry and a ChatGPT Project handoff. Use when Miguel asks to set up, finish setting up or check a project. Do not use for ordinary task administration inside an already bootstrapped project.
---

# Project bootstrap

Treat the user's request as the desired outcome. Compare existing state with the
postconditions below and perform only missing or explicitly corrected work.

## Preserve the system boundaries

- Google Drive holds project definition and source material.
- GitHub issues and Projects hold live work and state.
- `MiguelRodo/projects` owns reusable GitHub issue and Project administration.
- This skill coordinates those systems and supplies the manual ChatGPT Project
  handoff.

Never create a descriptive GitHub issue merely to represent the project. Never
put task lists in the Drive README. Never copy credentials, private source
content or personal identifiers into this public skill repository.

## Resolve the intended identity

Inspect current state before asking questions. Search for exact existing Drive,
GitHub and registry identities so a partial setup can be resumed.

Ask only for missing choices that materially change the result, in small groups:

1. project display name, year, `research` or `lecturing`, and a proposed
   lowercase folder slug;
2. GitHub repository choice: existing, new or none; for a new repository,
   resolve owner, exact name, visibility and a short description;
3. GitHub Project choice: existing, new or none; resolve owner and an existing
   number or new exact title;
4. a short purpose and explicit contact names and email addresses, or an
   explicit choice to list no contacts yet.

Default the year to the current year only when that is clearly appropriate.
Propose the folder slug, but show it before creation. Never infer that Miguel or
anyone else is a contact. Do not ask for methods, timeline, software or other
`Details` content during initial setup unless the user volunteers it.

Stop on duplicate exact matches, conflicting owners, an occupied Drive path or
an existing resource whose visibility disagrees with the requested setup.

## Obtain mutation authority

After resolving the missing choices, show one concise mutation summary covering
the exact GitHub identities, Drive path, repository files and registry row that
will be affected. Obtain authorisation immediately before the first create or
update. One confirmation may cover that clearly enumerated bootstrap, but do
not silently add an unrelated mutation later.

## Run the bootstrap

### 1. Resolve GitHub resources

Put GitHub first so its verified URLs can be written to Drive once. Read
[the GitHub workflow](references/github.md) whenever a repository or Project is
requested.

Use the first authenticated surface that can both perform the operation and
read it back. In a shell with `gh`, prefer the deterministic
`scripts/github-resources.sh` helper. An equivalent provider connector is fine
when it supports create and independent readback.

If the surface cannot create a requested resource, inspect everything it can
and return the smallest concrete `gh` command block with readback. Do not claim
the commands ran. Continue dependent setup only after the resulting URL and
identity have been verified.

### 2. Create the Drive source and register it

After GitHub resolution, read
[the Drive and registry workflow](references/drive-and-registry.md). Create only
missing resources at:

```text
work/projects/<year>/<research|lecturing>/<project-slug>/
```

The task-system mirror `projects/work/...` is a different path and is never the
source-project creation target.

Create a native Google Doc named `README`, plus `references/llm/`. Populate only
the minimal README sections in the reference. Use URLs returned by provider
readback rather than constructing them.

Add or update exactly one row in the live Projects registry by its current
schema, then record the material change in the existing Change log. Never write
to the pull-only GitHub cache tabs.

### 3. Connect the repository

When a repository exists, follow its `AGENTS.md` and contribution rules. Add or
update the bounded project-resources block described in the Drive reference,
preserving the rest of the README.

When both a repository and a GitHub Project are used, install and invoke the
current `github-project-admin` skill from `MiguelRodo/projects`. Do not reproduce
its Project field, priority, routing or mutation logic here. Add the verified
Drive README and `references/llm` links as source requirements in the one
resolved `.projects/` contract, validate the contract, commit the onboarding
files and verify them remotely.

### 4. Give the ChatGPT Project handoff

Read [the ChatGPT Project checklist](references/chatgpt-project.md). Version 1
does not create a ChatGPT Project automatically. Give the exact manual steps,
the verified Drive links and the short project instructions. Do not add a
ChatGPT Project link to the Drive README.

## Verify and report

Read [the verification checklist](references/verification.md) before claiming
completion. A mutation response is not readback. Re-fetch each resource through
the provider and compare the observed identity and content with the requested
state.

Report separately:

- verified resources that already existed;
- resources created or updated and their independent readback;
- registry readback;
- the manual ChatGPT Project checklist; and
- anything incomplete, with the exact reason and next action.

Do not call the project fully bootstrapped while any required manual checklist
item remains unconfirmed.
