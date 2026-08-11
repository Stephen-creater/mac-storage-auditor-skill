# Report Template

## Outcome first

State:

- Current total/free space.
- Whether cleanup is urgent.
- Conservative recoverable range.
- That the audit made no changes.

## 特别推荐删除

| Target | Logical size | Evidence | Impact | Expected recovery |
|---|---:|---|---|---:|

Include only high-confidence, low-loss targets.

## 可以删除

| Target | Logical size | Tradeoff | What must be confirmed |
|---|---:|---|---|

Make the decision easy for a non-specialist.

## 不能碰

| Protected target | Why protected |
|---|---|

Name active projects, unique media, dirty repositories, account databases, active files, and system-managed storage encountered during the audit.

## Abnormal findings

Explain unusual growth separately. Include the causal mechanism, not only the path name.

Examples:

- APFS clones inflate logical size.
- A JSONL search ingested its own live session.
- A sparse Docker disk has a large maximum but lower allocated size.
- A screen recorder retained internal originals after export.

## Recommended decision order

Order by:

1. Lowest loss and highest confidence.
2. Largest expected physical recovery.
3. Least disruption to frequently used tools.
4. Items requiring user judgment last.

## Deletion boundary

End with:

> This was a read-only audit. No file, app, cache, project, session, or Trash item was deleted. Reply with the exact targets you authorize, and they will be re-verified immediately before cleanup.
