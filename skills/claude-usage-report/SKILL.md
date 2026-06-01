---
name: claude-usage-report
description: Use when the user wants a report correlating Claude Code spend with actual work output — git commits, session work, lines of code, and business value — broken down week over week.
---

# Claude Usage Report

## Overview

Correlates three data sources — `ccusage` spend, `git log` commit history, and `~/.claude/projects/` session history — into a weekly markdown report showing what was built, what it cost, and what business value it delivered.

## Multi-Machine Setup

If sessions are spread across multiple workstations (AVD, Linux jump host, local Mac), collect and merge first:

**REQUIRED PRE-SKILL:** `claude-usage-collect`

Then substitute `CLAUDE_CONFIG_DIR=~/.claude-merged` in all ccusage commands and scan `~/.claude-merged/projects/` for session history instead of `~/.claude/projects/`.

## Prerequisites

Check for `ccusage` before running — install if missing:

```bash
if ! which ccusage &>/dev/null; then
  npm install -g ccusage
fi
```

## Data Sources

### 1. Spend data
```bash
ccusage weekly --json
# or, with merged data:
CLAUDE_CONFIG_DIR=~/.claude-merged ccusage weekly --json
```
Extract the last N weeks. Each entry has `week`, `totalCost`, and `modelBreakdowns`.

### 2. Git commits
Ask the user for:
- Which folder contains their repos (e.g. `~/Documents/git-repos/cspire-launchdeck/`)
- Their git author name/handle (e.g. `jeremypng`)

For each subdirectory that is a git repo, pull main and run:
```bash
git log --oneline --since="YYYY-MM-DD" --until="YYYY-MM-DD" \
  --author="<handle>" --stat
```

Use a subagent to parallelize across many repos. Skip worktree variants (`.arc`, `.fw`, etc.).

### 3. Session history

**Preferred:** If a `sessions-summary.json` was produced by `summarize-sessions.sh`, read that file directly. Each entry contains: `date`, `project`, `first_message`, `last_message`, `human_messages` (all, truncated), `tool_calls`, `message_count`, and `needs_investigation`.

For sessions where `needs_investigation: true`, read the raw JSONL file to determine content and value. The path is `~/.claude/projects/<encoded-project-path>/<session_id>*.jsonl` — match on `session_id` prefix. Only do this for flagged sessions; for all others use the summary.

**Fallback (no summary file):** Session files live at `~/.claude/projects/<encoded-path>/*.jsonl`. Use file mtime to filter by date range, then read only the first few lines of each file to infer the topic. Skip `/clear`-only sessions.

## Report Structure

One `## Week N — MMM DD–DD | $X,XXX.XX` section per week containing:

1. **Lines-of-code table** — per-repo `+Lines` / `-Lines`, bold totals row
2. **Commits per repo** — `### repo-name (N commits)` with each commit message in a code span
3. **Other session work** — bullet list of non-commit session topics under `### Other session work (no commits)`

Then a **Business Value** section at the bottom, followed by a **Summary table**:

| Week | Dates | Claude Cost | Commits | Lines Added | Lines Removed | Highlights |

## Business Value

For each week, write 2–4 bullet points framed as outcomes, not activity. Ask the user before writing value for anything ambiguous:

- Internal tools vs customer-facing products
- Demo context (who was the audience, how many attended)
- Project status (active dev / POC / handed off / stalled)
- Intended business outcome of architecture/design work

**Do not guess.** Use `AskUserQuestion` for anything where the framing would materially differ based on the answer.

## Key Pitfalls

- **Wrong folder**: Confirm the repo root before scanning. Repos may be nested (e.g. `cspire-launchdeck/launchdeck-base`).
- **Worktrees**: Skip directories with suffixes like `.arc`, `.fw`, `.eks-sg-rfc1918` — these are git worktrees, not separate repos.
- **Commit attribution**: Always filter by `--author`. Without it you'll include teammates' commits.
- **Session mtime vs content date**: File mtime is approximate. For precise dating, parse the `timestamp` field in the JSONL.
- **Lines of code for bootcamp/docs weeks**: Large line counts from content (slides, runbooks, diagrams) are real output — call them out explicitly rather than treating them as noise.
- **Low commits ≠ low value**: High spend with few commits often means design, debugging, or architecture sessions. Surface the session work to explain the spend.

## COCOMO Value Estimate (optional)

After completing the report, offer to append a COCOMO section using the `scc-cocomo` skill. Ask the user for their hourly rate. This adds:
- Per-repo SLOC and estimated cost table
- Combined total with hours saved and ROI ratio vs actual Claude spend

**OPTIONAL SUB-SKILL:** `scc-cocomo`

## Output File

Write to a dated markdown file, e.g.:
```
~/Documents/claude-usage-report-YYYY.md
```

Add `[toc]` after the title for navigation in markdown viewers that support it.
