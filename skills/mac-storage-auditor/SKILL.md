---
name: mac-storage-auditor
description: Perform evidence-based, read-only macOS storage audits and rank cleanup candidates as strongly recommended, optional, or protected. Use when Codex needs to inspect disk pressure, caches, rarely used apps, stale projects and dependencies, duplicate media, package stores, Docker data, oversized AI session logs, APFS clones, application leftovers, or other abnormal large files without deleting anything automatically.
---

# Mac Storage Auditor

Audit first. Explain second. Delete only in a separate, explicitly authorized step.

## Non-negotiable safety contract

- Treat every scheduled or first-pass run as read-only.
- Never delete, move, uninstall, empty Trash, quit apps, prune package stores, or mutate projects during an audit.
- Never infer that a large file is disposable from its name, age, or size alone.
- Protect current projects, unique media, dirty Git worktrees, account databases, browser profiles, chat databases, active processes, and system-managed storage.
- Require explicit user authorization for exact deletion targets. A broad request to “clean everything” still requires resolving concrete paths and effects.
- Re-measure current state on every run. Historical sizes are context, not current evidence.
- Report logical size separately from expected physical recovery when APFS clones, hard links, sparse files, or shared package stores may be involved.

## Run the audit

1. Create one scratch output outside maintained project folders, preferably under `/tmp`.
2. Run:

```bash
bash scripts/scan_macos_storage.sh --output /tmp/mac-storage-audit.md
```

3. Read the generated report.
4. Follow [references/evidence-guide.md](references/evidence-guide.md) for targeted follow-up checks.
5. Apply [references/decision-policy.md](references/decision-policy.md) to classify every meaningful candidate.
6. Present the result using [references/report-template.md](references/report-template.md).

Use `--quick` for a lighter triage that skips several deep scans; it can still take about a minute when large top-level directories must be sized. Use the default full scan for the monthly audit. The script is evidence collection, not the final decision-maker.

## Establish current intent and boundaries

Before classifying candidates, infer or verify:

- Which projects were active in the last 30–60 days.
- Which apps are currently running or regularly used.
- Which folders contain unique source media or only exported/duplicated copies.
- Which repositories have uncommitted or unpushed changes.
- Whether the user needs offline package/model availability.
- Whether a backup is the only copy or a redundant snapshot.

If a material ambiguity remains, ask one high-value question. Continue safe read-only discovery while waiting.

## Classify candidates

Use exactly these user-facing tiers:

### 特别推荐删除

Use only when evidence shows low data-loss risk and high rebuildability, for example:

- Stale update installers and `ShipIt`/`Sparkle` packages.
- Confirmed byte-identical duplicate media when the protected copy is verified.
- Inactive Chrome code-sign clones after open-file checks.
- Uninstalled-app residue after confirming the app is absent.
- Rebuildable caches, logs, crash reports, and temporary files.
- Abnormally recursive AI session files whose useful conversation is tiny and whose size comes from self-ingested Base64/tool output.

### 可以删除

Use when deletion is reasonable but loses convenience, history, or reproducibility, for example:

- Old `node_modules`, `.venv`, `.next`, package stores, and local models.
- Old AI sessions that are valid but no longer valuable.
- Docker images, containers, volumes, and virtual disks after identifying the projects they served.
- Old projects, exports, downloads, and installed apps after user confirmation.
- Browser Service Worker caches or offline resources that will be rebuilt but may affect offline use.

### 不能碰

Use when deletion could damage current work, identity, unique data, or system stability, for example:

- Current project source, dirty Git repositories, or unpushed work.
- Unique recordings, camera originals, editing drafts, and current deliverables.
- Browser profiles, Cookies, IndexedDB, passwords, bookmarks, or account state.
- WeChat/Feishu/chat databases and app support data not proven to be cache.
- Active code-sign clones or files held open by a process.
- System swap, VM files, OS snapshots, Spotlight databases, or protected system directories.

Do not classify a parent directory when only a child is safe. Name the narrowest safe target.

## Explain every recommendation

For each item include:

- Exact path or app name.
- Logical size.
- Last modified/last used evidence.
- What created it.
- Whether it is cache, state, source, backup, dependency, model, or media.
- What the user loses after deletion.
- Whether it can be regenerated or downloaded again.
- Whether the app must be quit first.
- Confidence level and unresolved uncertainty.
- Expected physical recovery when different from logical size.

Do not sum overlapping parent and child paths. Mark estimates that share APFS blocks.

## Detect high-value anomalies

Always check these patterns when present:

- Chrome `*.code_sign_clone`: count clones, inspect versions, and use `lsof` before calling any clone inactive.
- Codex/AI JSONL sessions: compare bytes, line count, `data:image`, `base64`, and references to their own session directory. A multi-GB file with few lines and thousands of embedded images is suspicious.
- CleanShot and screen recorders: distinguish the app’s internal media library from exported Desktop/Movies copies; verify duplicates with SHA-256 or `cmp`.
- Editing apps: separate projects/drafts from waveforms, speech-recognition PCM, render cache, logs, and updater packages.
- Docker: distinguish the app from images, containers, volumes, build cache, and the sparse virtual disk.
- Package managers: distinguish executable/tool installations from npm, pnpm, Yarn, pip, uv, Homebrew, and browser download caches.
- Uninstalled-app residue: confirm no matching `.app`, process, login item, LaunchAgent, or active CLI remains.
- Old repositories: inspect remotes, dirty status, untracked files, backups, and formal deliverables before recommending deletion.

## Separate audit from cleanup

If the user later authorizes cleanup:

1. Resolve exact paths and validate they still match the report.
2. Record protected-file hashes when duplicates or source media are involved.
3. Check running processes and open file handles.
4. Measure free space before deletion.
5. Prefer recoverable Trash for the first move.
6. Inspect Trash before emptying it; never empty unrelated user items silently.
7. Verify protected files, processes, and app state afterward.
8. Measure free space again and report actual recovery, not the sum of displayed sizes.
9. State whether deletion is recoverable.

## Monthly automation behavior

For scheduled runs:

- Start a new standalone task each month.
- Run the full audit read-only.
- Compare against current free space, not an old threshold.
- Rank the best opportunities, but perform no cleanup.
- Call out newly abnormal growth since the previous month when evidence is available.
- End with a short decision list for the user.
