---
name: claude-usage-collect
description: Use when gathering Claude usage data from multiple development workstations (AVD, Linux jump host, etc.) to consolidate into a single portable bundle for report generation on one machine.
---

# Claude Usage Collect

## Overview

Collects Claude session history and usage data from a workstation into a portable tarball. Multiple bundles from different machines are merged on a reporting workstation, then `ccusage` and `claude-usage-report` run against the combined dataset.

**Key insight:** `ccusage` reads from `~/.claude/projects/` and respects the `CLAUDE_CONFIG_DIR` env var — so a merged directory from multiple machines is a fully functional substitute.

## Workflow

```
Each workstation                    Reporting workstation
─────────────────                   ─────────────────────
collect-bundle.sh  ──tarball──►     merge-bundles.sh
                                         │
                                    CLAUDE_CONFIG_DIR=merged/ ccusage weekly --json
                                         │
                                    claude-usage-report skill
```

## Step 1: Collect on Each Workstation

Run `collect-bundle.sh` on every machine that has Claude Code sessions:

```bash
#!/usr/bin/env bash
# collect-bundle.sh
# Usage: ./collect-bundle.sh --since 2026-04-13 --until 2026-05-19

set -euo pipefail

SINCE="${2:-$(date -v-42d +%Y-%m-%d 2>/dev/null || date -d '42 days ago' +%Y-%m-%d)}"
UNTIL="${4:-$(date +%Y-%m-%d)}"
HOSTNAME="${HOSTNAME:-$(hostname -s)}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BUNDLE="claude-bundle-${HOSTNAME}-$(date +%Y%m%d).tar.gz"
TMPDIR=$(mktemp -d)

echo "Collecting from $CLAUDE_DIR (${SINCE} to ${UNTIL})..."

# Collect session JSONL files modified in the date range
mkdir -p "$TMPDIR/projects"
find "$CLAUDE_DIR/projects" -name "*.jsonl" -newer <(touch -t "$(echo $SINCE | tr -d '-')0000" /tmp/.since_marker && echo /tmp/.since_marker | xargs) 2>/dev/null | while read f; do
  rel="${f#$CLAUDE_DIR/projects/}"
  mkdir -p "$TMPDIR/projects/$(dirname "$rel")"
  cp "$f" "$TMPDIR/projects/$rel"
done

# Metadata
cat > "$TMPDIR/metadata.json" <<EOF
{
  "hostname": "$HOSTNAME",
  "since": "$SINCE",
  "until": "$UNTIL",
  "collected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "claude_dir": "$CLAUDE_DIR",
  "session_count": $(find "$TMPDIR/projects" -name "*.jsonl" | wc -l | tr -d ' ')
}
EOF

tar -czf "$BUNDLE" -C "$TMPDIR" .
rm -rf "$TMPDIR" /tmp/.since_marker 2>/dev/null || true

echo "Created: $BUNDLE"
echo "Sessions collected: $(find . -name "$BUNDLE" -exec tar -tzf {} \; | grep '\.jsonl$' | wc -l)"
echo "Transfer this file to your reporting workstation."
```

**Transfer the bundle** via scp, airdrop, shared drive, etc.:
```bash
scp claude-bundle-avd-20260519.tar.gz user@reporting-host:~/bundles/
```

## Step 2: Merge on Reporting Workstation

```bash
#!/usr/bin/env bash
# merge-bundles.sh
# Usage: ./merge-bundles.sh ~/bundles/*.tar.gz

set -euo pipefail

MERGED_DIR="$HOME/.claude-merged"
rm -rf "$MERGED_DIR"
mkdir -p "$MERGED_DIR/projects"

for bundle in "$@"; do
  echo "Merging: $bundle"
  TMPDIR=$(mktemp -d)
  tar -xzf "$bundle" -C "$TMPDIR"

  # Print metadata
  jq -r '"  hostname: \(.hostname)  sessions: \(.session_count)  range: \(.since) to \(.until)"' \
    "$TMPDIR/metadata.json" 2>/dev/null || true

  # Merge projects — later bundles win on conflict (same session file from two machines)
  cp -r "$TMPDIR/projects/." "$MERGED_DIR/projects/"
  rm -rf "$TMPDIR"
done

echo ""
echo "Merged into: $MERGED_DIR"
echo "Total sessions: $(find "$MERGED_DIR/projects" -name "*.jsonl" | wc -l)"
echo ""
echo "Run ccusage against merged data:"
echo "  CLAUDE_CONFIG_DIR=$MERGED_DIR ccusage weekly --json"
```

## Step 3: Run ccusage Against Merged Data

```bash
CLAUDE_CONFIG_DIR=~/.claude-merged ccusage weekly --json
CLAUDE_CONFIG_DIR=~/.claude-merged ccusage session --json
```

Also include local machine's own data if not already bundled:
```bash
# Merge local sessions too
cp -r ~/.claude/projects/. ~/.claude-merged/projects/ 2>/dev/null || true
```

## Step 4: Feed into claude-usage-report

When running the `claude-usage-report` skill, tell it to use the merged data dir:
- For ccusage: prefix commands with `CLAUDE_CONFIG_DIR=~/.claude-merged`
- For session history: scan `~/.claude-merged/projects/` instead of `~/.claude/projects/`

**REQUIRED SKILL:** `claude-usage-report`
**OPTIONAL SKILL:** `scc-cocomo` (for COCOMO value after report is built)

## Pitfalls

- **Date filtering in collect:** `find -newer` uses file mtime which approximates session date — it may include sessions slightly outside the range. The report skill does precise filtering via JSONL timestamps.
- **Duplicate sessions:** If the same Claude Code session was synced to multiple machines (e.g. via dotfiles), the same JSONL will appear in multiple bundles. `cp -r` with last-write-wins is fine — the file content is identical.
- **CLAUDE_CONFIG_DIR scope:** This env var changes where ccusage looks for *everything* including config. If you have a custom `~/.claude/settings.json` that ccusage reads, copy it too: `cp ~/.claude/settings.json ~/.claude-merged/`
- **Linux date syntax:** macOS uses `date -v-42d`, Linux uses `date -d '42 days ago'`. The collect script handles both.
- **Cleanup:** Delete `~/.claude-merged` after the report is done — it's a working directory, not a permanent store.

## Quick Reference

| Step | Command |
|------|---------|
| Collect (each machine) | `./collect-bundle.sh --since 2026-04-13 --until 2026-05-19` |
| Transfer | `scp bundle.tar.gz user@host:~/bundles/` |
| Merge | `./merge-bundles.sh ~/bundles/*.tar.gz` |
| Verify | `CLAUDE_CONFIG_DIR=~/.claude-merged ccusage weekly` |
| Report | Run `claude-usage-report` skill with merged dir |
| Cleanup | `rm -rf ~/.claude-merged` |
