# claude-usage-toolkit

A Claude Code plugin with four skills for generating usage reports that correlate Claude spend with actual work output — git commits, session history, COCOMO development value, and hours saved — and turning that into a credible, executive-ready summary.

## Skills

### `claude-usage-collect`
Collects Claude session history from a workstation into a portable tarball. Use this on each machine (AVD, Linux jump host, local Mac) before running the report. Bundles are merged on the reporting workstation using `CLAUDE_CONFIG_DIR`.

### `claude-usage-report`
Builds the weekly report by correlating:
- **ccusage** spend data (weekly cost + model breakdown)
- **git log** commits by the user across all repos
- **~/.claude/projects/** session history (including non-commit work)
- **Business value** framing (asks you to clarify anything ambiguous)

Output: a dated markdown file with per-week sections, a summary table, and optional COCOMO value.

### `scc-cocomo`
Runs `scc` against files committed by a specific author across multiple repos to produce a COCOMO development cost estimate at a given hourly rate. Reports estimated cost, hours saved, and ROI ratio vs actual Claude spend.

### `claude-usage-exec-summary`
Turns the detailed report into an **executive-ready** summary for a *named* leader (CEO, CFO, CTO, board). Discovers and quantifies your role (and remembers it), walks you through each workstream and its real business value, estimates hours saved via a credible team-equivalent method, and produces both a prose write-up and a one-page summary. Bakes in the guardrails that keep the numbers believable — no COCOMO vanity multiples, no jargon, verified project status, spend never framed as a credential.

Output: a dated markdown file with a prose write-up addressed to the executive plus a skimmable one-page summary.

## Prerequisites

- [`ccusage`](https://github.com/ryoppippi/ccusage) — `npm install -g ccusage` (required for usage-report)
- [`scc`](https://github.com/boyter/scc) — `brew install scc` or `go install github.com/boyter/scc/v3@latest` (required for scc-cocomo only)
- `jq` — `brew install jq`

The skills that need these tools check for them and print install instructions automatically before running. `claude-usage-exec-summary` needs no extra tools — it consumes the report's output.

## Installation

```bash
# Add the marketplace (once)
claude plugin marketplace add https://github.com/csbproserve/claude-usage-toolkit

# Then install the plugin
claude plugin install claude-usage-toolkit
```

## Multi-Machine Workflow

```
Each workstation                    Reporting workstation
─────────────────                   ─────────────────────
claude-usage-collect  ──tarball──►  merge + ccusage + claude-usage-report
```

See the `claude-usage-collect` skill for the collect/merge scripts.

## Skill Chain

```
claude-usage-collect       (optional, multi-machine)
        ↓
claude-usage-report        (main report)
        ↓
scc-cocomo                 (optional, COCOMO value estimate)
        ↓
claude-usage-exec-summary  (optional, executive-ready write-up)
```

## License

MIT
