# ChatGPT Project checklist

Version 1 uses a manual checklist. Do not claim to create or verify a ChatGPT
Project through an interface that cannot inspect it.

Give the user the verified Drive and GitHub links beside these steps:

1. Create or open a private ChatGPT Project with the intended project name.
2. In Project sources, add the native Google Drive `README` link.
3. Add the Google Drive `references/llm` folder link as a second source.
4. Make the GitHub repository available to the Project when one is used.
5. Open Project settings and paste the instructions below.
6. Check that both Drive sources appear, the intended repository is available
   and the instructions were saved.

Google Drive file and folder links are current supported Project sources, but
availability still depends on the user's connected app and workspace settings.
If the current UI differs, check current official OpenAI documentation and
describe the exact remaining manual action rather than guessing.

Use these Project instructions:

```text
For project definition and background, use the attached Google Drive README as
the authoritative starting point, then consult only relevant material in the
attached references/llm folder. Do not treat generated summaries or prior chat
as more authoritative than those sources.

For work concerning the GitHub repository, especially reading or updating
GitHub issues or Projects, first retrieve and follow the target repository's
AGENTS.md. Follow the skill and configuration files it references. If the
repository or AGENTS.md is unavailable, say so rather than guessing.

Treat my prompt as the desired outcome. If this chat cannot make an authorised
GitHub issue or Project mutation, follow the resolved repository contract and
the github-project-admin handoff. When its local Chat implementation queue is
enabled, create the small labelled handoff issue and separate unedited authority
comment it requires so I can later run `pj -i`; report that mutation as queued,
not completed. Only fall back to the smallest executable gh command plus an
independent result check when the queue is disabled or cannot be created safely.
```

Do not put these instructions into the Drive README. Do not add a ChatGPT
Project URL to the README by default.

Record this handoff as pending until the user confirms all six steps or a
capable surface independently inspects them.
