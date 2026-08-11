# Evidence Guide

Use this guide only for follow-up checks relevant to candidates found by the scan.

## Baseline disk evidence

```bash
df -h /System/Volumes/Data
df -k /System/Volumes/Data
diskutil info /
```

Record `df -k` before and after cleanup for the least ambiguous delta.

## Directory and file sizing

```bash
du -sk PATH
du -sh PATH
stat -f '%z %Sm %N' -t '%Y-%m-%d %H:%M:%S' FILE
```

Do not add a parent directory to its children. Treat sparse files, clones, and hard links as estimates.

## Running and open-file checks

```bash
pgrep -afil 'APP_OR_PROCESS'
lsof +D 'EXACT_DIRECTORY'
lsof 'EXACT_FILE'
```

Run the open-file check immediately before cleanup. A stale check is not sufficient.

## Git project safety

```bash
git -C REPO status --short
git -C REPO remote -v
git -C REPO log -1 --date=iso --format='%h %ad %s'
```

Dirty, untracked, or unpushed work belongs in “不能碰” until the user explicitly accepts the loss.

## Duplicate proof

```bash
cmp -s FILE_A FILE_B
shasum -a 256 FILE_A FILE_B
stat -f '%i %l %b %z %N' FILE_A FILE_B
```

Record the protected copy’s hash before deletion and verify it afterward.

## Application presence and last use

```bash
find /Applications "$HOME/Applications" -maxdepth 2 -name '*.app' -print
mdls -raw -name kMDItemLastUsedDate '/Applications/Example.app'
```

Also inspect processes, LaunchAgents, login items, CLI links, and recent database writes before calling data “uninstalled residue.”

## Package managers

Common evidence paths:

```text
~/.npm
~/Library/pnpm/store
~/Library/Caches/pnpm
~/Library/Caches/Yarn
~/.cache/pip
~/.cache/uv
~/Library/Caches/Homebrew
```

Preferred conservative commands:

```bash
pnpm store prune
npm cache verify
brew cleanup -n -s
```

Explain loss of offline reuse and re-download time.

## Codex and AI session anomalies

For large JSONL files, compare size to structure:

```bash
stat -f '%z %N' SESSION.jsonl
wc -l SESSION.jsonl
LC_ALL=C grep -ao 'data:image' SESSION.jsonl | wc -l
LC_ALL=C grep -ao 'base64' SESSION.jsonl | wc -l
LC_ALL=C grep -ao '\.codex/sessions' SESSION.jsonl | wc -l
```

Strong anomaly pattern:

- Hundreds or fewer lines.
- Multi-GB file.
- Thousands of Base64/image markers.
- Tool command searched the entire home or live session directory.
- The useful user request was small.

This usually means a search ingested the live session file and wrote the result back into itself.

## Application code-sign clones

A generic clone search may include Chrome, Ego Lite, and other Chromium or Electron applications. Identify the owning bundle before classifying a clone.

Typical location:

```text
/private/var/folders/.../X/com.google.Chrome.code_sign_clone/code_sign_clone.*
```

For every clone:

1. Read the embedded app version from `Contents/Info.plist`.
2. Compare with `/Applications/Google Chrome.app`.
3. Run `lsof +D` immediately before any action.
4. Preserve every open clone.
5. Expect logical size to overstate physical recovery because Chrome uses APFS `clonefile` and hard links.

One active clone is normal. Many inactive clones indicate failed cleanup.

## Browser data boundaries

Usually rebuildable:

- HTTP cache
- GPU cache
- component download cache
- on-device downloadable models
- Service Worker `CacheStorage` and script cache, with offline-use caveats

Protect unless explicitly analyzed:

- Cookies
- Login Data
- Bookmarks
- History
- IndexedDB
- Local Storage
- WebStorage
- extension state
- browser profile directories

## Screen recording and editing apps

Separate:

- App binary
- Internal media/history library
- Exported recordings
- Editing projects/drafts
- Render, waveform, proxy, speech-recognition, and updater caches

Never assume an internal media library includes or merely references an exported folder. Prove file identity.

## Docker

Separate:

- Docker Desktop app
- Images
- Containers
- Volumes
- Build cache
- Sparse virtual disk

Inspect project labels, compose files, container history, and volume contents. Removing Docker data does not uninstall Docker Desktop, but deleting volumes may destroy unique databases.

## Trash

Measure total, age, and contents independently. A large Trash is not automatically safe to empty.

```bash
du -sh "$HOME/.Trash"
find "$HOME/.Trash" -mindepth 1 -maxdepth 1 -mtime +30 -print
```

If Trash was empty before moving approved targets, it is easier to prove that emptying it affects only the current cleanup.
