# claude-usage-toolkit

A Claude Code plugin with three skills for generating weekly usage reports that correlate Claude spend with actual work output — git commits, session history, COCOMO development value, and hours saved.

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

## Prerequisites

- [`ccusage`](https://github.com/ryoppippi/ccusage) — `npm install -g ccusage` (required for usage-report)
- [`scc`](https://github.com/boyter/scc) — `brew install scc` or `go install github.com/boyter/scc/v3@latest` (required for scc-cocomo only)
- `jq` — `brew install jq`

Both skills check for missing tools and print install instructions automatically before running.

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
claude-usage-collect  (optional, multi-machine)
        ↓
claude-usage-report   (main report)
        ↓
scc-cocomo            (optional, COCOMO value estimate)
```

## License

MIT
