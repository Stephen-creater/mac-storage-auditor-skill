# mac-storage-auditor-skill

An evidence-first Codex Skill for finding reclaimable disk space on macOS without blindly deleting user data.

It audits:

- Application and package caches
- Rarely used applications
- Old projects and rebuildable dependencies
- Large and abnormal files
- Duplicate screen recordings and editing media
- Docker storage
- Browser code-sign clones and profile boundaries
- Oversized Codex/AI session logs
- Uninstalled-application residue

It ranks findings as:

- **特别推荐删除** — high-confidence, low-loss cleanup
- **可以删除** — reasonable cleanup with an explicit tradeoff
- **不能碰** — current, unique, active, account-related, or system-managed data

## Safety model

The Skill is read-only by default and scheduled audits never delete anything. Cleanup requires a separate user decision with exact targets.

It also distinguishes logical size from real recoverable space. APFS clones, hard links, sparse files, and shared package stores can make Finder or `du` totals much larger than the physical space a deletion will release.

## Install

Clone the repository and link or copy the Skill folder into a Codex Skill directory:

```bash
git clone https://github.com/Stephen-creater/mac-storage-auditor-skill.git
ln -s "$PWD/mac-storage-auditor-skill/skills/mac-storage-auditor" \
  "$HOME/.codex/skills/mac-storage-auditor"
```

## Use

Invoke it in Codex:

```text
Use $mac-storage-auditor to run a read-only storage audit and rank cleanup candidates.
```

The bundled scanner can also run directly:

```bash
bash skills/mac-storage-auditor/scripts/scan_macos_storage.sh \
  --output /tmp/mac-storage-audit.md
```

## Scope

The scanner targets macOS and uses standard system tools such as `du`, `df`, `find`, `stat`, `mdls`, `lsof`, and `PlistBuddy`. Some protected paths may be unavailable unless the terminal host has Full Disk Access; missing protected paths are skipped rather than treated as empty.

## License

MIT
