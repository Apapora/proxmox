# 1. Record architecture decisions

Date: 2026-05-21
Status: Accepted

## Context

This homelab is a learning project that will evolve over months/years. Decisions
made early (k8s distro, storage backend, secrets approach) have long-lasting
consequences. Without a written record, future-me forgets *why* a choice was
made and either reverses it pointlessly or perpetuates it without understanding.

## Decision

Use lightweight ADRs (Architecture Decision Records) inspired by Michael
Nygard's template. Each significant decision gets its own markdown file in
`docs/decisions/`, numbered sequentially, never edited after acceptance.

Template:

```markdown
# N. Short title

Date: YYYY-MM-DD
Status: Proposed | Accepted | Deprecated | Superseded by ADR-X

## Context
What forces are at play. Why are we choosing now.

## Decision
What we decided.

## Consequences
What becomes easier, what becomes harder, what risks we accept.
```

Status `Superseded by ADR-X` is preferred over editing — preserves history.

## Consequences

- One more thing to write when making decisions
- Trivial decisions don't need ADRs — judgment call, lean toward writing one
  when in doubt
- New contributors (or future-me) can read `docs/decisions/` chronologically
  to understand how the system became what it is
