# Framing Guide — Executive Summary

Supporting reference for `claude-usage-exec-summary`. Status taxonomy, reframing examples, anti-patterns, and the methodology footnote template.

## Status Taxonomy

Use the honest label. An executive can falsify an inflated one from the room, and one overclaim discredits the whole submission. Match the verb to reality.

| Status | Honest verb | Do NOT say |
|--------|-------------|------------|
| Idea / spike | "explored," "prototyped" | "built," "delivered" |
| Prototype / POC | "prototyped," "proved out" | "launched," "shipped" |
| MVP (early, limited) | "launched in MVP," "early release" | "production," "fully rolled out" |
| In pilot | "in pilot with <who>" | "in use across the org" |
| Onboarding / rolling out | "now onboarding teams," "moving toward self-service" | "production," "teams now self-serve" |
| Production / in use | "in production," "in use by <who>" | (fine — if true) |
| Launching on a date | "launching <month>" | "launched" (if it hasn't) |
| Foundational | "built the foundation that <X> was built on" | overstating it as the finished thing |

When unsure, **ask the user** and default to the softer verb.

## Technical → Business Reframing

Translate the artifact into capability + outcome + beneficiary. Examples:

| Technical (from the report) | Executive framing |
|---|---|
| "XRD compositions / platform-apis to production maturity" | "Advanced our internal infrastructure platform — moving teams toward governed self-service provisioning" |
| "alarm correlation / enrichment / dedup in the SA pipeline" | "Matured our service-assurance platform — richer, deduplicated alarms behind customer outage notifications" |
| "Auth0 JIT provisioning, RBAC" | "Built secure, automated user onboarding for the platform" |
| "Entra ID SSO integration for GHE + AWS" | "Brought our developer tools and cloud access under one secure corporate identity" |
| "ARC runners on AKS" | "Stood up self-hosted CI/CD and image building on our own infrastructure" |
| "compliance-logs service to SIEM" | "Built a compliance-logging service feeding our security operations center" |
| "consolidated agent-api + demo + widget backends" | "Merged three prototypes into one production support experience across Webex, Contact Center, and Outlook" |

Rule of thumb: if a peer outside engineering wouldn't understand it, it isn't framed yet.

## Anti-Pattern Catalog

- **The vanity multiple.** "8,000× ROI," "$200M of value." Triggers disbelief; discredits everything else. Keep COCOMO in the detailed report only.
- **Spend as a badge.** "I'm the #1 user / I spent $20K." In a governance review that is the cost under scrutiny — never a credential. Let value dwarf it silently.
- **Hours as clock time.** The team-equivalent number is *output-based*, not time-and-motion. Say so, or someone divides it by 160 and calls it impossible.
- **Status inflation.** "Production" for a prototype. The fastest way to lose the room.
- **Jargon.** Repo names, framework names, internal acronyms. Translate or cut.
- **YTD padding.** Re-listing the focus month's wins in the year-to-date section. Keep YTD to the distinct annual arc.
- **Precision theater.** Defending a blended YTD estimate to the decimal. Concede it's a blend.

## Methodology Footnote Template

Place directly beneath the hours-saved table. Fill the brackets:

> **Basis / methodology:** Estimated as team-equivalent output × a standard engineer-month (~160 hrs). **<Focus month>:** ~<N>-person team × 160 hrs ≈ ~<N×160> hrs, where "<N>" is the number of distinct production workstreams carried in parallel that month, each normally a 1–2 person effort. **YTD:** a blended ~<avg>-person-equivalent sustained across <M> months (× 160 hrs ≈ <total> hrs), peaking at <N> in <focus month>. This is an *output-based* estimate — not hours on the clock, and not a COCOMO/code-valuation figure. If anything it is conservative: infrastructure, identity, and security work (<list the invisible workstreams>) is high-impact but barely registers in code-based measurement.

## Role Memory Template

Save after Step 1 as a `type: user` memory so future runs start warm:

```markdown
---
name: <operator>-role
description: <operator>'s role, team, and how Claude leverages it — for exec usage summaries
metadata:
  type: user
---

<Name> is <title>, leading <N> engineers (<player-coach? IC? specialist?>).
Claude leverage framing: <leadership leverage | force multiplier | capability expansion>.
How they work: <e.g. directs multiple Claude agents in parallel>.
Standing executive audience: <e.g. reports to CEO "Suzy"; QGR review>.
Defensible team-equivalent: <e.g. ~8× in peak months, ~5–6× blended>.
```
