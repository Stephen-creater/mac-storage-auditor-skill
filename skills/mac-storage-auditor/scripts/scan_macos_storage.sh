#!/bin/bash
set -u

audit_home="${HOME}"
output=""
top_n=20
old_days=120
large_mib=1024
quick=0

usage() {
  cat <<'EOF'
Usage: scan_macos_storage.sh [options]

Read-only macOS storage evidence collector.

Options:
  --home PATH       Home directory to audit (default: $HOME)
  --output FILE     Write Markdown report to FILE (default: stdout)
  --top N           Rows per ranked section (default: 20)
  --old-days N      Age threshold for old work folders (default: 120)
  --large-mib N     Large-file threshold in MiB (default: 1024)
  --quick           Skip deep large-file, old-folder, app, and session scans
  -h, --help        Show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --home) audit_home="$2"; shift 2 ;;
    --output) output="$2"; shift 2 ;;
    --top) top_n="$2"; shift 2 ;;
    --old-days) old_days="$2"; shift 2 ;;
    --large-mib) large_mib="$2"; shift 2 ;;
    --quick) quick=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ ! -d "$audit_home" ]; then
  echo "Home directory does not exist: $audit_home" >&2
  exit 2
fi

case "$top_n:$old_days:$large_mib" in
  *[!0-9:]*|:*|*::*|*:) echo "Numeric options must be positive integers" >&2; exit 2 ;;
esac

if [ -n "$output" ]; then
  mkdir -p "$(dirname "$output")"
  exec >"$output"
fi

size_mib() {
  awk -v kb="$1" 'BEGIN { printf "%.1f MiB", kb / 1024 }'
}

size_gib() {
  awk -v kb="$1" 'BEGIN { printf "%.2f GiB", kb / 1048576 }'
}

mtime() {
  stat -f '%Sm' -t '%Y-%m-%d' "$1" 2>/dev/null || printf 'unknown'
}

print_du_ranked() {
  title="$1"
  shift
  echo "## $title"
  echo
  echo '| Size | Modified | Path |'
  echo '|---:|---|---|'
  for target in "$@"; do
    [ -e "$target" ] || continue
    du -sk "$target" 2>/dev/null
  done | sort -nr | head -n "$top_n" | while read -r kb path; do
    printf '| %s | %s | `%s` |\n' "$(size_gib "$kb")" "$(mtime "$path")" "$path"
  done
  echo
}

echo '# macOS Storage Audit Evidence'
echo
echo "- Generated: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "- Host: $(scutil --get ComputerName 2>/dev/null || hostname)"
echo "- Home: \`$audit_home\`"
echo "- Mode: $([ "$quick" -eq 1 ] && echo quick || echo full)"
echo '- Mutation policy: read-only; no files were deleted or moved.'
echo

echo '## Disk baseline'
echo
echo '```text'
if [ -d /System/Volumes/Data ]; then
  df -h /System/Volumes/Data 2>/dev/null || true
else
  df -h "$audit_home" 2>/dev/null || true
fi
echo '```'
echo
echo '- On APFS systems, the Data volume is used so the displayed used space includes user data; free space is shared across the APFS container.'
echo

home_targets=()
for p in "$audit_home"/* "$audit_home"/.[!.]*; do
  [ -e "$p" ] || continue
  home_targets+=("$p")
done
print_du_ranked 'Home top level' "${home_targets[@]}"

library_targets=()
if [ -d "$audit_home/Library" ]; then
  for p in "$audit_home/Library"/*; do
    [ -e "$p" ] && library_targets+=("$p")
  done
fi
print_du_ranked 'Library top level' "${library_targets[@]}"

cache_targets=()
if [ -d "$audit_home/Library/Caches" ]; then
  for p in "$audit_home/Library/Caches"/*; do
    [ -e "$p" ] && cache_targets+=("$p")
  done
fi
print_du_ranked 'Application caches' "${cache_targets[@]}"

support_targets=()
if [ -d "$audit_home/Library/Application Support" ]; then
  for p in "$audit_home/Library/Application Support"/*; do
    [ -e "$p" ] && support_targets+=("$p")
  done
fi
print_du_ranked 'Application Support' "${support_targets[@]}"

package_paths=(
  "$audit_home/.npm"
  "$audit_home/.cache"
  "$audit_home/Library/pnpm"
  "$audit_home/Library/Caches/pnpm"
  "$audit_home/Library/Caches/Yarn"
  "$audit_home/Library/Caches/Homebrew"
  "$audit_home/.yarn"
  "$audit_home/.bun"
  "$audit_home/.rustup"
  "$audit_home/.nvm"
)
print_du_ranked 'Package, model, and developer stores' "${package_paths[@]}"

special_paths=(
  "$audit_home/.codex/sessions"
  "$audit_home/.codex/.tmp"
  "$audit_home/Library/Application Support/CleanShot"
  "$audit_home/Movies/JianyingPro"
  "$audit_home/Library/Application Support/Google/Chrome"
  "$audit_home/Library/Containers/com.docker.docker"
  "$audit_home/Library/Group Containers/group.com.docker"
  "$audit_home/.Trash"
)
print_du_ranked 'Known high-value audit targets' "${special_paths[@]}"

roots=()
for root in "$audit_home/Desktop" "$audit_home/Documents" "$audit_home/Downloads" "$audit_home/Developer" "$audit_home/Movies"; do
  [ -d "$root" ] && roots+=("$root")
done

echo '## Rebuildable project directories'
echo
echo '| Size | Modified | Path |'
echo '|---:|---|---|'
if [ "${#roots[@]}" -gt 0 ]; then
  find "${roots[@]}" -maxdepth 7 -type d \( -name node_modules -o -name .venv -o -name 'venv' -o -name '.venv-*' -o -name .next -o -name dist -o -name .uv-cache -o -name .pytest_cache \) -print0 2>/dev/null |
    while IFS= read -r -d '' p; do
      kb=$(du -sk "$p" 2>/dev/null | awk '{print $1}')
      [ -n "$kb" ] && printf '%s\t%s\n' "$kb" "$p"
    done | sort -nr | head -n "$top_n" | while IFS=$'\t' read -r kb p; do
      printf '| %s | %s | `%s` |\n' "$(size_gib "$kb")" "$(mtime "$p")" "$p"
    done
fi
echo

if [ "$quick" -eq 0 ] && [ "${#roots[@]}" -gt 0 ]; then
  echo "## Files larger than ${large_mib} MiB"
  echo
  echo '| Bytes | Modified | Path |'
  echo '|---:|---|---|'
  find "${roots[@]}" -maxdepth 9 -type f -size +"${large_mib}"M -print0 2>/dev/null |
    while IFS= read -r -d '' p; do stat -f '%z\t%Sm\t%N' -t '%Y-%m-%d' "$p" 2>/dev/null; done |
    sort -nr | head -n "$top_n" | while IFS=$'\t' read -r bytes modified p; do
      printf '| %s | %s | `%s` |\n' "$bytes" "$modified" "$p"
    done
  echo

  echo "## Work folders older than ${old_days} days"
  echo
  echo '| Size | Modified | Path |'
  echo '|---:|---|---|'
  find "${roots[@]}" -mindepth 1 -maxdepth 2 -type d -mtime +"$old_days" -print0 2>/dev/null |
    while IFS= read -r -d '' p; do
      kb=$(du -sk "$p" 2>/dev/null | awk '{print $1}')
      [ -n "$kb" ] && [ "$kb" -ge 102400 ] && printf '%s\t%s\n' "$kb" "$p"
    done | sort -nr | head -n "$top_n" | while IFS=$'\t' read -r kb p; do
      printf '| %s | %s | `%s` |\n' "$(size_gib "$kb")" "$(mtime "$p")" "$p"
    done
  echo
fi

if [ "$quick" -eq 0 ]; then
  app_rows=()
  shopt -s nullglob
  apps=(/Applications/*.app "$audit_home"/Applications/*.app)
  for app in "${apps[@]}"; do
    kb=$(du -sk "$app" 2>/dev/null | awk '{print $1}')
    [ -n "$kb" ] || continue
    last=$(mdls -raw -name kMDItemLastUsedDate "$app" 2>/dev/null | sed 's/ +0000$//' || true)
    app_rows+=("$kb"$'\t'"$last"$'\t'"$app")
  done

  echo '## Installed applications by size'
  echo
  echo '| Size | Last used | Application |'
  echo '|---:|---|---|'
  printf '%s\n' "${app_rows[@]}" | sort -t $'\t' -k1,1nr | head -n "$top_n" | while IFS=$'\t' read -r kb last app; do
    printf '| %s | %s | `%s` |\n' "$(size_gib "$kb")" "$last" "$app"
  done
  echo

  echo '## Least recently used applications'
  echo
  echo '| Last used | Size | Application |'
  echo '|---|---:|---|'
  printf '%s\n' "${app_rows[@]}" | sort -t $'\t' -k2,2 | head -n "$top_n" | while IFS=$'\t' read -r kb last app; do
    printf '| %s | %s | `%s` |\n' "$last" "$(size_gib "$kb")" "$app"
  done
  echo
fi

echo '## Application code-sign clones'
echo
echo '| Size | Version | Open handles | Path |'
echo '|---:|---|---:|---|'
find /private/var/folders -type d -path '*/X/*.code_sign_clone/code_sign_clone.*' -prune -print0 2>/dev/null |
  while IFS= read -r -d '' p; do
    kb=$(du -sk "$p" 2>/dev/null | awk '{print $1}')
    plist=$(find "$p" -path '*.app.bundle/Contents/Info.plist' -print -quit 2>/dev/null)
    version='unknown'
    if [ -n "$plist" ]; then
      version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null || echo unknown)
    fi
    open_count=$(lsof +D "$p" 2>/dev/null | awk 'NR>1 {count++} END {print count+0}')
    printf '| %s | %s | %s | `%s` |\n' "$(size_gib "${kb:-0}")" "$version" "$open_count" "$p"
  done
echo

if [ "$quick" -eq 0 ] && [ -d "$audit_home/.codex/sessions" ]; then
  echo '## Oversized Codex sessions'
  echo
  echo '| Size | Lines | data:image | base64 | Self refs | Path |'
  echo '|---:|---:|---:|---:|---:|---|'
  find "$audit_home/.codex/sessions" -type f -name '*.jsonl' -size +100M -print0 2>/dev/null |
    while IFS= read -r -d '' p; do
      bytes=$(stat -f %z "$p" 2>/dev/null || echo 0)
      lines=$(wc -l < "$p" | tr -d ' ')
      images=$(LC_ALL=C grep -ao 'data:image' "$p" 2>/dev/null | wc -l | tr -d ' ')
      b64=$(LC_ALL=C grep -ao 'base64' "$p" 2>/dev/null | wc -l | tr -d ' ')
      refs=$(LC_ALL=C grep -ao '\.codex/sessions' "$p" 2>/dev/null | wc -l | tr -d ' ')
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$bytes" "$lines" "$images" "$b64" "$refs" "$p"
    done | sort -nr | head -n "$top_n" | while IFS=$'\t' read -r bytes lines images b64 refs p; do
      printf '| %s | %s | %s | %s | %s | `%s` |\n' "$bytes" "$lines" "$images" "$b64" "$refs" "$p"
    done
  echo
fi

echo '## Interpretation notes'
echo
echo '- Sizes above are logical directory/file estimates and may overlap.'
echo '- APFS clones, hard links, sparse files, and package stores can make displayed size differ from physical recovery.'
echo '- Application Support is not automatically cache.'
echo '- Old and large does not mean disposable.'
echo '- This script performed no deletion, move, uninstall, app quit, package prune, or Trash operation.'
