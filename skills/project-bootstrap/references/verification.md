# Verification checklist

Use current provider reads, not mutation responses or reconstructed URLs.

## Drive

- One exact project folder exists at the approved source path.
- Its returned parent chain is `work/projects/<year>/<category>/`.
- It contains one native Google Doc named `README` and one `references/llm`
  folder chain.
- README purpose and contacts equal the user's supplied values.
- README contains the exact folder, repository and Project links that apply.
- README has no task sections and no ChatGPT Project link.

## GitHub

- Repository owner/name, URL and visibility match.
- Project owner, number, title, URL and open state match.
- The remote repository README contains exactly one bounded resources block
  with the exact Drive and Project links.
- When onboarding applies, remote `AGENTS.md` routes to
  `github-project-admin`, the resolved `.projects/` contract contains the Drive
  source rule, and the current validator succeeds.
- No Project fields, labels, issues or live values changed merely because the
  bootstrap ran.

## Registry

- Exactly one Projects row contains the canonical Drive folder identity.
- Its GitHub repository and Project values match current readback.
- A material registry change has a corresponding Change log row when that log
  exists.
- No derived GitHub cache tab was used as a write surface.

## ChatGPT handoff

- The user received links for the README and `references/llm` sources.
- The user received the exact short Project instructions.
- Creation remains labelled manual and pending until confirmed.

## Completion report

Report observed state under four headings: Drive, GitHub, registry and ChatGPT
Project. For each, distinguish already present, changed, independently verified
and still manual. Include exact URLs only when they came from readback.
