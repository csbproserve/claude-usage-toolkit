---
name: claude-usage-exec-summary
description: Use when the user needs to turn a Claude usage report (or their month's work) into an executive-ready summary for a named leader — quantifies hours saved credibly, discovers each workstream and its business value, and produces a prose write-up plus a one-page summary.
---

# Claude Usage Executive Summary

## Overview

Transforms a detailed `claude-usage-report` into an **executive-ready** summary for a *named* leader (CEO, CFO, CTO, board). The detailed report answers "what did I do and what did it cost." This skill answers the only question an executive asks: **"what business value did this create, and was it worth it?"**

The value of this skill is the *process*, not the prose. Executives gut-check numbers in seconds and know the real status of projects. A single overclaim or an unbelievable metric discredits the entire submission. This skill enforces a discovery-and-verification flow that produces a summary that survives the room.

**Chains after:** `claude-usage-report` (use its dated markdown as input). Can also run standalone from the user's knowledge.

## The Cardinal Rules

Bake these in. They are non-negotiable and they override any instinct to impress.

1. **Believable beats impressive.** A modest number that is bulletproof is worth more than a huge one that invites "really?" One unbelievable figure poisons trust in every other number on the page.
2. **Never lead with COCOMO dollars or vanity ROI multiples** (e.g. "$200M of value", "8,000× ROI") to an executive. They read as not credible. COCOMO is a code-valuation ceiling, not hours saved. Keep it out of executive output unless the user explicitly insists, and warn them if they do.
3. **Spend is a cost, not an accomplishment.** Never present "I'm the top user" or "I spent $X" as a credential. In a governance review the spend is the thing being justified — the value must dwarf it, quietly.
4. **Never assert a status you cannot verify.** "Production," "launched," "deployed," "in use" are claims an executive can falsify from the room. Default to softer verbs until the user confirms (see the status taxonomy in `references/framing-guide.md`).
5. **No jargon.** "XRD compositions," "Auth0 JIT," "Kafka pipeline" mean nothing to a CEO. Translate every item to capability, outcome, and beneficiary.

## Process

Run these steps in order. Steps 1 and 2 are interviews and feed everything downstream. Do not skip ahead to writing.

### Step 1 — Role discovery (and remember it)

The summary's narrative spine is *who the person is and how Claude changes what their role can produce.* This is also the most reusable input, so persist it.

1. **Check memory first.** Look for a saved role profile (a memory of `type: user` describing the operator's role). If found, summarize it back and ask: "Still accurate? Anything changed — team size, title, scope?" Update rather than re-ask.
2. **If absent, interview** (one question at a time):
   - Title and team — do they lead people? How many?
   - What are they responsible for (delivery, architecture, mentoring, strategy)?
   - **The key question:** *How does Claude change what your role produces?* Listen for the framing:
     - **Leadership leverage** — a manager/director who can now also deliver team-level technical output *without* stepping back from leading. (Strongest exec narrative.)
     - **Force multiplier** — an IC delivering well beyond a single person's normal output.
     - **Capability expansion** — doing work that previously required a specialist they didn't have.
   - How do they actually work with Claude (e.g. directing multiple agents in parallel)? This explains the output volume and pre-empts "how is that possible?"
3. **Save the role profile to memory** so future monthly runs start warm. Keep it generic to the operator (this plugin ships to many users). Include: title, team size, leverage framing, how they work, and any standing executive audience (e.g. "reports up to CEO 'Suzy'").

### Step 2 — Audience interview

- **Who** is the named reader? (CEO / CFO / CTO / board / cross-functional.) Vocabulary and framing follow from this.
- **What decision** does this support? (Justify spend / expand the program / showcase output / status update.)
- **What do they already have?** Critical: if Finance already owns the spend figures, **omit dollars entirely** and supply only the value side. Ask before assuming.
- **Format and length** expected (prose, one-pager, slide, or all).

### Step 3 — Workstream discovery walk-through (the core)

Do **not** auto-summarize from commits. Walk the user through their work; they hold the context the data cannot show (real status, business value, invisible work).

1. **Enumerate candidates** from the report data — group by repo/project/initiative. Cluster related repos into one *workstream* (e.g. several repos that make up one platform).
2. **For each workstream, ask** (move briskly, batch where natural):
   - What is this, in **business terms**? (Not the repo name — the capability.)
   - **Real status?** Use the taxonomy: *prototype / POC → MVP → in pilot → production / in use → launching <date> → foundational (enabling other work)*. Pick the honest one.
   - **Business value** — what does it enable, unblock, or improve? Who benefits (customer / a specific internal team / NOC / the whole org)?
   - Is it part of a larger arc (a through-line across the year, or feeding a future launch)? Through-lines make the strongest narrative.
3. **Probe for invisible workstreams.** Commit data systematically under-represents high-impact work. Explicitly ask about:
   - Identity / SSO / access (e.g. Entra ID, SAML, IAM integrations)
   - Developer platform / CI-CD (runners, image building, source-control rollouts)
   - Security & governance (security policies, compliance log shipping to SIEM/SOC)
   - Infrastructure foundations, migrations, rollouts
   These rarely show as large commit counts but are exactly what executives weight heavily.
4. **Produce a workstream → business-value map.** This is the deliverable of this step. Each entry: workstream, verified status, one-line business outcome, beneficiary.

This map does double duty: the **count of concurrent workstreams** anchors the hours estimate (Step 4), and the **value lines** become the results bullets (Step 6) — already verified, so there is nothing left to overclaim.

### Step 4 — Quantify hours saved (team-equivalent method)

This is the sanctioned method. Do not use COCOMO for the headline.

- **Formula:** `team-equivalent × ~160 hours` per engineer-month (40 hrs/wk × 4; or 2,080/yr ÷ ~13).
- **The multiplier is the number of concurrent workstreams from Step 3**, sense-checked against the user's judgment — each workstream is normally a 1–2 person effort. **Defend it by naming the workstreams, never by spend or token counts.**
- **Per-month is precise; YTD is blended.** A focus month (e.g. "an 8-person team × 160 = ~1,280 hrs") is directly defensible. For YTD, use a blended average across the months (e.g. "~5.5-person-equivalent × N months × 160") and **say openly that the month is precise and the YTD is a reasonable blended estimate** — don't defend YTD to the decimal.
- **Confirm the multiplier with the user.** Recommend a defensible number; let them push up only if they can name the workstreams to back it. Past ~8–10× believability drops regardless of how hard they pushed Claude.
- **Auto-generate a methodology footnote** (see template in `references/framing-guide.md`) and place it directly under the hours table so the basis travels with the number.
- **Pre-empt "too high":** the estimate is conservative because the invisible workstreams (Step 3.3) barely register in any code-based measure.

### Step 5 — Guardrail pass

Before writing, re-check the draft against the Cardinal Rules: no dollars unless requested, no COCOMO/vanity multiples in the headline, spend never framed as achievement, every status verified in Step 3, zero jargon.

### Step 6 — Produce two outputs

Write to a dated file (e.g. `~/Documents/claude-exec-summary-<period>.md`) containing both:

**A. Prose write-up** — addressed to the named executive, as if speaking directly to them. ~4–6 tight paragraphs:
1. Role + the leverage framing (the spine, from Step 1).
2. Hours saved — focus month and YTD, with the "grounded in named workstreams, not raw activity" caveat.
3. What the focus month delivered (business outcomes from the value map).
4. The year's through-line(s) and the invisible/foundational work.
5. A one-line bottom line.

**B. One-page structured summary** — skimmable:
- Header: name · role · team.
- A one-line "how I use it" framing.
- Hours-saved table (focus month + YTD) with the **methodology footnote** beneath it.
- "<Month> — what it delivered" bullets and "Year to date — what it delivered" bullets, drawn from the verified value map.
- A one-line takeaway.

Keep the two versions consistent. Offer to tighten the one-pager or convert to PDF/docx/slide.

## Pitfalls

- **Auto-drafting from commits.** The discovery walk-through exists *because* the data lies about status and misses invisible work. Don't shortcut it.
- **Repeating focus-month items in the YTD section.** YTD should be the year's distinct arc, not a re-list of the focus month. Drop anything already covered above.
- **Letting the big COCOMO number leak in "just for context."** It anchors skepticism and undercuts the solid number beside it. Leave it in the detailed report, not the exec summary.
- **Precision theater on YTD hours.** State the blend honestly; over-defending it is where credibility cracks.
- **Skipping the memory save.** The role profile is the most reusable artifact — saving it is what makes next month's run fast.

## See Also

- `references/framing-guide.md` — status taxonomy, technical→business reframing examples, anti-pattern catalog, and the methodology-footnote template.
- `claude-usage-report` — produces the detailed input this skill consumes.
