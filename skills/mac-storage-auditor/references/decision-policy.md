# Decision Policy

## Purpose

Turn raw disk usage into safe decisions. Optimize for recoverable space without damaging recent projects or frequently used tools.

## Evidence hierarchy

Prefer evidence in this order:

1. Open file handles, running processes, live project paths, and dirty Git state.
2. Exact file identity through hashes, inode/link inspection, or byte comparison.
3. Application metadata, bundle presence, LaunchAgents, CLI links, and database activity.
4. Modification and last-used timestamps.
5. Path names and age alone.

Never promote a candidate to “特别推荐删除” using only path name or age.

## Tier rules

### 特别推荐删除

Require all applicable conditions:

- The target is not the only copy of user-created data.
- No running process uses it.
- It is reproducible, downloadable, redundant, or abandoned residue.
- The exact target is narrower than the surrounding valuable directory.
- The expected effect is understood.
- Confidence is high.

Typical examples:

| Pattern | Required proof | Expected impact |
|---|---|---|
| Update cache | App data lives elsewhere; package is an installer | App may redownload an update |
| Duplicate video | Protected copy exists and matches byte-for-byte | One duplicate disappears |
| Old code-sign clone | No open handle; version is inactive | No profile/account impact |
| Uninstalled residue | App, process, CLI and LaunchAgent are absent | Old settings/cache disappear |
| Recursive session log | Useful topic identified; size caused by self-ingestion | Historical task disappears |
| Crash/log cache | Not a database or project output | Diagnostics disappear |

### 可以删除

Use when there is a real tradeoff requiring a user decision:

| Pattern | What is lost | How it returns |
|---|---|---|
| Package store | Offline reuse and faster installs | Re-download packages |
| `node_modules` / `.venv` | Immediate runnable environment | Reinstall from manifests |
| Local AI model | Offline inference and download time | Download model again |
| Valid old session | Searchable conversation history | Usually cannot reconstruct exactly |
| Docker data | Images, containers, volumes and DB state | Rebuild images; volumes may be unique |
| Old project | Source, local changes, artifacts | Only from remote/backup if present |
| Service Worker cache | Offline website resources | Website reload/reinstall |
| Installed unused app | App and perhaps local state | Reinstall app; state may not return |

### 不能碰

Use whenever any of these apply:

- Unique personal media or business deliverable.
- Recent or current project source.
- Dirty/untracked/unpushed repository content.
- Account, credential, cookie, chat, or application database.
- Active process dependency or open file.
- System-managed VM, swap, snapshot, or protected database.
- Unknown folder whose purpose and source have not been established.
- Parent directory containing a mixture of safe cache and valuable state.

## User-specific operating principles that generalize

- Protect recent projects and frequently used apps before maximizing recovery.
- For an unknown folder, first answer what it contains, where it came from, and whether it still has value.
- Re-downloadable dependencies are lower value than source code, but are not automatically deleted.
- A backup can be deleted only after establishing that another complete copy exists.
- App binaries and app-generated data are separate decisions.
- Cloud sync does not prove that local source media can be deleted; verify downloadability and completeness.
- “Cache” is a behavioral category, not a trustworthy folder name. Some apps misuse cache-looking locations for durable state.
- The user decides tradeoffs; the auditor supplies evidence and a ranked recommendation.

## APFS and recovery estimates

Distinguish:

- **Logical size**: how much content paths appear to contain.
- **Allocated size**: blocks currently charged to a file or directory.
- **Exclusive recoverable size**: blocks that become free only when this target is removed.

APFS clones can make many 2 GB app bundles look like 40 GB while sharing most blocks. Hard-linked package stores and project dependencies can behave similarly. Never promise that deleting logical size `X` will recover `X`.

Use free-space delta as truth:

```text
actual recovery = free space after - free space before
```

Mention concurrent downloads, snapshots, purgeable space, and background cache recreation when they can move the measurement.

## Deletion authority

An audit never grants deletion authority. Valid authorization names a target or an unambiguous class after the user understands the effect. If a new discovery changes the effect materially, stop and explain it before deletion.

Examples:

- “Delete all CleanShot internal MP4 files but protect Desktop lesson videos” is sufficient after path verification.
- “Clean everything” is insufficient for browser profiles, Docker volumes, chat databases, or dirty repositories.
- “Delete the backup if it was never used” is conditional; if it was used, report that fact and request a new decision.
