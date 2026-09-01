# GitHub workflow

Use this reference only when the project will use a GitHub repository, GitHub
Project, or both.

## Resolve before creating

For a repository, resolve its exact `OWNER/REPO`, URL, visibility and current
default branch. For a Project, resolve its owner, number, exact title, URL and
open/closed state. Project titles are not stable unique identifiers. If more
than one exact title matches, ask for the Project number.

An exact existing resource is resumable state, not an error. Stop when an
existing resource has a conflicting owner, visibility or title.

## Direct execution

In a shell with an authenticated GitHub CLI, use the bundled helper. It is
inspection-only unless `--apply` is supplied.

Resolve existing resources:

```bash
bash scripts/github-resources.sh \
  --repository OWNER/REPOSITORY \
  --project-owner OWNER \
  --project-number NUMBER \
  --project-title "EXACT TITLE"
```

Create missing resources after explicit authorisation:

```bash
bash scripts/github-resources.sh \
  --repository OWNER/REPOSITORY \
  --create-repository \
  --visibility public \
  --description "SHORT DESCRIPTION" \
  --project-owner OWNER \
  --project-title "EXACT TITLE" \
  --create-project \
  --apply
```

Use a provider connector instead only when it supports the same create,
inspection and independent readback operations. Never infer create capability
from read access.

## Command-returning surfaces

When direct creation is unavailable, return one terminal-ready block containing
only the required creates and readbacks. Substitute every discovered non-secret
value. Do not include a shebang or script boilerplate in a short block.

The underlying operations are:

```bash
gh repo create OWNER/REPOSITORY \
  --public \
  --description "SHORT DESCRIPTION" \
  --add-readme

gh repo view OWNER/REPOSITORY \
  --json nameWithOwner,url,visibility,defaultBranchRef

gh project create \
  --owner OWNER \
  --title "EXACT TITLE" \
  --format json

gh project list \
  --owner OWNER \
  --closed \
  --limit 1000 \
  --format json
```

Use `--private` or `--internal` only when that exact visibility was chosen.
Check `gh auth status` first. The user supplies credentials through the host
environment or `gh auth login`; never request or echo a token in chat.

If a create reports an uncertain failure, inspect again. Do not blindly retry a
create that might have succeeded.

## Onboard through `github-project-admin`

Do this only when both a repository and GitHub Project are used.

From a local checkout of the project repository:

```bash
gh skill install MiguelRodo/projects github-project-admin \
  --agent universal --scope project
bash .agents/skills/github-project-admin/scripts/init-project.sh
```

The initializer owns `.projects/project.md`, multi-Project dispatching and the
bounded `AGENTS.md` routing section. Supply the verified Project owner and
number when prompted. It must not change live issues, fields or Project values.

After it resolves one contract, add these repository-specific source rules to
that contract's Governance section using the verified URLs:

```markdown
- Before inventing or restructuring scope, read the canonical Drive README at
  <README URL>, then only relevant material in <references/llm URL>.
```

Run its validator and preserve all other contract content:

```bash
bash .agents/skills/github-project-admin/scripts/validate-contract.sh .
```

Follow the target repository's own contribution rules when committing. For a
new personal repository, the initializer may offer to commit and push its
bounded onboarding files. For an established or collaborative repository, use
the required pull-request flow.

Do not configure Class, Priority, Status, Workstream, views, labels or hierarchy
inside this bootstrap. That is subsequent `github-project-admin` work and needs
its own requested outcome and authority.
