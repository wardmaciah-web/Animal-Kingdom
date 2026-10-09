---
name: Command Center task
about: A bounded, explicitly dispatched task for the local Codex worker
title: "Command Center: "
labels: ak-command-center
---

Describe the problem and expected behavior. Reuse the existing Notion task.
Replace the sample below with the exact scope. The installed worker's local
allowlist is authoritative; this form grants no additional permission.

```ak-task
{
  "task_id": "replace-with-stable-id",
  "revision": 1,
  "source": "chatgpt",
  "priority": 10,
  "approval_class": "safe-edit",
  "allowed_paths": ["documentations/command-center-tasks/example.txt"],
  "notion_page": "3f4d6658-7369-8105-8222-ca8aa367a6f7",
  "instructions": "Replace with a specific bounded task.",
  "acceptance": [{"path": "documentations/command-center-tasks/example.txt", "contains": "Replace with the required result"}],
  "tests": ["text-contract", "git-diff-check"],
  "requires_studio": false
}
```

An allowlisted issuer must comment `ak-dispatch <SHA256 of this entire issue body>`
after the final body is saved. Changed instructions require a higher revision and
a new dispatch hash. Purchases, publication, destructive changes and security
changes require separate human review. Never include credentials or shell commands.
