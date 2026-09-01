# Drive and registry workflow

Use this reference after any requested GitHub resources have verified identities.

## Canonical source path

Create or resume:

```text
work/projects/<year>/<research|lecturing>/<project-slug>/
```

Folder names are lowercase. Propose a deterministic readable slug, but show it
before creating the folder. Do not confuse this user-owned source tree with the
task-system mirror under `projects/work/...`.

Walk the path from `work` and inspect each level. Create only a missing exact
folder. Stop if the proposed project path has multiple matches or is occupied
by a different project.

## Project contents

The completed folder contains:

```text
<project-slug>/
├── README                 native Google Doc
└── references/
    └── llm/
```

Create a native Google Doc named `README`, not a Markdown upload. Use this
minimal structure:

```text
README

Purpose
<short purpose supplied by the user>

Contacts
<name and email for each explicitly supplied contact, or "No contacts listed yet.">

Directory structure
references/llm/: LLM-oriented project reference material.

Links
Project folder: <verified canonical folder URL>
GitHub repository: <verified URL, when applicable>
GitHub Project: <verified URL, when applicable>

Details
```

Leave `Details` empty. Do not add `Tasks`, `Task Notes` or a ChatGPT Project
link. Do not infer contacts. Add optional source/data links only when the user
supplied them.

Read the folder metadata, README content and `references/llm` metadata back
after creation. Keep the exact returned URLs.

## Repository README block

When a GitHub repository exists, add this bounded section using verified URLs:

```markdown
<!-- project-bootstrap:resources:start -->
## Project resources

- [Canonical Drive project folder](<folder URL>)
- [Project README](<README URL>)
- [LLM reference material](<references/llm URL>)
- [GitHub Project](<Project URL, when applicable>)
<!-- project-bootstrap:resources:end -->
```

Omit an inapplicable list item. If the markers already exist, replace only the
content between them. If they do not, append one section at a natural boundary.
Preserve every unrelated byte where practical. Follow the repository's
`AGENTS.md` and contribution rules, then fetch the remote README to verify one
marker pair and the exact links.

## Projects registry

Find the task system's exact `Global tasks` spreadsheet. Inspect the live
Projects sheet headers and existing rows before writing. Do not hard-code a
private spreadsheet ID or a stale column layout into this public skill.

Match an existing project conservatively using stable evidence such as the
exact Drive folder ID/link and repository identity. Stop on zero-confidence or
multiple-row matches. Add or update exactly one row with the columns currently
used for:

- project identity and display name;
- year and research/lecturing classification when the live schema records them;
- exact canonical Drive source-folder link;
- GitHub repository identity and URL when applicable;
- GitHub Project owner, number and URL when applicable; and
- current sync or migration mode required by the live schema.

Preserve unrelated cells and do not edit the GitHub-derived cache tabs as a
write path. If the spreadsheet contains a Change log, append one material
change row using its current headers and the public bootstrap repository as the
procedure source.

Read the exact Projects row back after writing. Registration is incomplete
until one and only one row contains the verified identities.
