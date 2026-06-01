---
name: scc-cocomo
description: Use when estimating the COCOMO development cost or hours saved for code committed by a specific author across multiple git repos, using scc at a given hourly rate.
---

# SCC COCOMO Value Estimate

## Overview

Uses `scc` (Sloc Cloc and Code) to estimate what committed code would cost to produce conventionally, using the COCOMO organic model. Useful for quantifying AI-assisted productivity in reports.

## Prerequisites

Check for `scc` before running — install if missing:

```bash
if ! which scc &>/dev/null; then
  if which brew &>/dev/null; then
    brew install scc
  elif which go &>/dev/null; then
    go install github.com/boyter/scc/v3@latest
  else
    # Linux direct binary — install to ~/.local/bin (user-writable)
    mkdir -p ~/.local/bin
    curl -L "https://github.com/boyter/scc/releases/latest/download/scc_Linux_x86_64.tar.gz" \
      | tar xz -C ~/.local/bin scc
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi
```

## Key Parameters

| Input | How to get it |
|-------|---------------|
| Hourly rate | Ask the user |
| Annual wage | `hourly × 2080` |
| Author handle | Git author name (e.g. `jeremypng`) |
| Date range | Since/until dates |
| Repo root | Directory containing the git repos |

## Methodology

`scc` requires real files — it cannot operate on raw diff output. The practical approach is to collect every file **added or modified** by the author in the date range, then run `scc` on those files at HEAD.

**Tradeoff:** This measures the full current state of touched files, not strictly the committed delta. For COCOMO purposes this is acceptable — COCOMO estimates the value of the work product, not the incremental diff.

### Per-Repo Script

```bash
AUTHOR="jeremypng"
SINCE="2026-04-13"
UNTIL="2026-05-19"
ANNUAL_WAGE=291200   # $140/hr × 2080

TMPDIR=$(mktemp -d)

git log --since="$SINCE" --until="$UNTIL" \
  --author="$AUTHOR" --diff-filter=AM \
  --name-only --format="" | sort -u | while read f; do
    mkdir -p "$TMPDIR/$(dirname "$f")"
    git show HEAD:"$f" > "$TMPDIR/$f" 2>/dev/null || true
done

scc --avg-wage "$ANNUAL_WAGE" --cocomo-project-type organic "$TMPDIR"
rm -rf "$TMPDIR"
```

### Combined Run Across Many Repos

```bash
COMBINED=$(mktemp -d)

for repo in /path/to/repos/*/; do
  [ -d "$repo/.git" ] || continue
  git -C "$repo" log --since="$SINCE" --until="$UNTIL" \
    --author="$AUTHOR" --diff-filter=AM \
    --name-only --format="" | sort -u | while read f; do
      mkdir -p "$COMBINED/$repo/$(dirname "$f")"
      git -C "$repo" show HEAD:"$f" > "$COMBINED/$repo/$f" 2>/dev/null || true
  done
done

scc --avg-wage "$ANNUAL_WAGE" --cocomo-project-type organic "$COMBINED"
rm -rf "$COMBINED"
```

> **Note:** The combined run produces a higher estimate than the sum of per-repo runs because COCOMO scales nonlinearly with total project size. Use the combined number as the headline figure.

## Key Output Fields

From `scc` output, extract:
- **Estimated Cost** — COCOMO dollar value
- **Estimated Schedule Effort** — months
- **Estimated People Required**
- **SLOC** — source lines of code (excludes blanks/comments)

## Derived Metrics

```
Hours saved  = Estimated Cost ÷ hourly rate
ROI ratio    = Estimated Cost ÷ actual AI spend
```

## Reporting

| Metric | Value |
|--------|-------|
| Total SLOC | X |
| COCOMO Estimated Cost | $X |
| Estimated Hours | X hrs |
| Actual AI Cost | $X |
| Cost Ratio | ~Nx ROI |
| Schedule Effort | X months |
| People Required | X |

## Pitfalls

- **Skip worktrees:** Dirs with suffixes like `.arc`, `.fw`, `.eks-sg-rfc1918` are git worktrees — `[ -d "$repo/.git" ]` will return false for them if `.git` is a file pointer, so they'll be skipped automatically. Verify with `git -C "$repo" rev-parse --is-inside-work-tree`.
- **Generated/JSON files:** scc counts JSON/YAML as 0 SLOC. Large fixture repos will look smaller than raw line counts suggest — this is correct behavior.
- **Overlapping repos:** If two repos share files (e.g. dev/prod crossplane mirrors), per-repo totals double-count. The combined run de-duplicates by path within the merged temp dir.
- **Annual wage:** scc's `--avg-wage` takes **annual** salary, not hourly. Always multiply: `hourly × 2080`.
