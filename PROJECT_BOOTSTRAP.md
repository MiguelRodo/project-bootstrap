# Project bootstrap contract

## Purpose

This contract initialises, resumes or audits one of Miguel's research or
lecturing projects. It is deliberately a thin orchestration layer. It does not
reimplement GitHub Project administration, turn Google Drive into a task list,
or automate ChatGPT Project creation before a supported interface exists.

## Required choices

Ask only for information that is missing and cannot be discovered safely:

1. Project display name, year and whether it is research or lecturing.
2. The proposed lowercase folder slug.
3. Whether the GitHub repository is existing, new or not wanted. For a new
   repository, resolve its owner, exact name, visibility and short description.
4. Whether the GitHub Project is existing, new or not wanted. Resolve its owner
   and either its number or exact title.
5. A short statement of purpose.
6. Contact names and email addresses, or an explicit statement that no contacts
   should be listed yet.

Never infer a contact, including Miguel. Do not ask for methods, timelines,
software or other `Details` content during initial setup unless the user
volunteers it.

## Sequence

### 1. Inspect before creating

Search GitHub, Drive and the Projects registry for the proposed identities.
Treat an exact existing resource as resumable state. Stop on duplicates,
conflicting identities, an occupied Drive path, or an existing resource whose
visibility or ownership disagrees with the requested setup.

Before the first mutation, show one concise summary of the GitHub resources,
Drive path, repository files and registry row that will be affected, then obtain
authorisation for that enumerated bootstrap.

### 2. Resolve GitHub first

Resolve or create the requested baseline repository and GitHub Project before
creating the Drive README, so their verified links can be written once.

Use an authenticated execution surface when available. Immediately before a
create, use the exact repository owner/name/visibility and Project owner/title
from the authorised bootstrap summary. Independently read back each created
resource.

If the current surface cannot create a required GitHub resource, return the
smallest concrete `gh` command block with readback. Do not claim that the block
ran. Continue dependent setup only after the resulting identity has been
verified.

### 3. Create the canonical Drive project

The source location is:

```text
work/projects/<year>/<research|lecturing>/<project-slug>/
```

This is not the task-system mirror path `projects/work/...`.

Create only missing folders and create this shape:

```text
<project-slug>/
├── README                 native Google Doc
└── references/
    └── llm/
```

Populate `README` from [`templates/drive-readme.md`](templates/drive-readme.md).
Its links use URLs returned by verified readback, never reconstructed URLs. Do
not add a ChatGPT Project link. Leave `Details` empty initially.

### 4. Connect the GitHub repository

When a repository exists, add or update only the bounded section represented by
[`templates/repository-resources.md`](templates/repository-resources.md). Keep
the rest of the README byte-for-byte unchanged where practical. Follow the
repository's own `AGENTS.md` and contribution rules.

When both a repository and GitHub Project are used, onboard the repository with
the public `github-project-admin` skill from `MiguelRodo/projects`. Store the
verified Drive README and `references/llm` links as source requirements in the
resolved `.projects/` contract. Do not reproduce field, priority, routing or
mutation logic in this repository.

### 5. Register the project

Find the task system's `Global tasks` spreadsheet and inspect the live Projects
sheet schema. Add or update exactly one project row using the verified canonical
Drive folder link and the GitHub repository and Project identities when
applicable. Preserve unrelated columns and rows. Record the material change in
the existing Change log using its live schema, then independently read back the
registry row.

Never write operational task state into the pull-only GitHub cache tabs.

### 6. Hand off ChatGPT Project creation

Version 1 ends with a manual checklist. The user creates or opens a private
ChatGPT Project, adds the native Drive README and the `references/llm` folder as
project sources, makes the GitHub repository available when applicable, and
installs the short routing instructions supplied by the skill.

Do not say the ChatGPT Project exists until it can be inspected directly or the
user confirms the completed checklist.

## Completed state

| Surface | Required postcondition |
| --- | --- |
| Drive | Exact canonical folder exists at the approved path. |
| Drive | Native Google Doc `README` exists with purpose, explicit contacts, directory description and verified links. |
| Drive | `references/llm/` exists and is empty unless the user supplied material. |
| GitHub | Requested repository and Project identities are independently verified. |
| GitHub | Repository README contains one bounded project-resources section. |
| GitHub | When applicable, `github-project-admin` is installed and its `.projects/` contract validates. |
| Registry | Exactly one Projects row contains the exact Drive and GitHub identities. |
| ChatGPT | Manual creation checklist and exact project instructions have been supplied. |
| Completion | Every claimed write has separate readback; all remaining work is listed explicitly. |

The procedure is idempotent. A request to finish or check a project starts from
the postconditions above and performs only missing or explicitly corrected
work.

## Boundaries

- GitHub issues remain concrete actions or outcomes, not duplicate project
  descriptions.
- Google Drive is project background, not a parallel task tracker.
- `MiguelRodo/projects` remains the general GitHub administration system.
- Its optional `projects` Go CLI may perform supported GitHub operations. It
  does not replace this cross-system bootstrap workflow or create a second
  project-bootstrap contract.
- This public repository contains no private identifiers, credentials or
  project-specific contact information.
- Tokens are never requested in chat, printed, committed or written to Drive.
