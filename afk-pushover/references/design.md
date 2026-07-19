# afk-pushover — Design rationale

This skill is the product of a real design session. The rules in `SKILL.md` aren't arbitrary — each resolves a specific question that came up while building the workflow. This document records the *why*, condensed from the project's original ADRs. Read it when you want to understand a rule's motivation or are considering changing one.

## The five core decisions

### 1. Trigger rule: page on Blocked, not Reporting

The session has two moment-to-moment states:

- **Reporting** — the agent is producing progress mid-turn. Streaming reasoning, executing tools, narrating steps. The human may be watching but isn't required to act.
- **Blocked** — the agent cannot proceed without the human. An unanswered question, an unapproved tool call, a completed deliverable awaiting direction.

The pager fires **only** on Blocked. Pages on Reporting would train the human to ignore them (alert fatigue), and worse — would make it impossible to tell a correct page from a noisy one.

The broad interpretation of Blocked (any moment the human is needed, not just literal questions) trades a small amount of noise for coverage of moments the agent doesn't classify as a question. Rejected: question-only (too narrow), self-classification (inconsistent in practice).

### 2. The agent decides to page (not a heuristic)

The trigger isn't "fire on every turn-end" or "fire when a tool pauses for approval." The agent itself decides it's Blocked and calls the pager. The decision *is* the signal.

This is the only trigger design that's faithful to the Blocked/Reporting distinction. Heuristic triggers either over-fire (turn-boundary → D1 degradation) or under-fire (approval-only → misses grill-style questions). The agent's own judgment is the source of truth.

Honest cost: depends on the agent being disciplined about calling the pager. The skill's job is to make that discipline easy, not to enforce it.

### 3. Channel: Pushover, not the native bridges

Three alternatives were tried and failed before settling on Pushover:

- **Native Lark/Feishu bridge** — *Reactive-Only*. Responds to inbound messages, never proactively pushes. Tested: even after binding the conversation from Lark, a desktop-originated Blocked moment produced no push. The bridge is built for inbound steering, not paging.
- **Native Telegram bridge** — same architecture as Lark, same limitation.
- **`telegram@claude-plugins-official` plugin** — would have solved it (its `reply` tool can push proactively), but zcode's plugin loader doesn't spawn channel-style MCP servers into agent sessions. The plugin is registered but inert.
- **ntfy** — message delivery works, but iOS push is unreliable because Apple throttles background processing. Tested: "delivered inside the app" but no lock-screen push.

Pushover wins because its APNs pipeline is the entire product. The integration is one curl. Verified end-to-end: script → API → APNs → locked iPhone, sub-second.

### 4. State machine: AFK arms, BTK disarms

Pager discipline is gated by explicit keywords:

- **AFK** — arms the pager.
- **BTK** — disarms.

No inference about the human's attention state. The keyword itself is the handshake — no separate "mode engaged" confirmation needed.

Rejected alternatives:
- *Always-on paging* — annoying when the human is at the keyboard.
- *Infer from context* — unreliable, makes the contract non-auditable.
- *Per-message carve-outs* ("don't page if the human just replied") — re-introduces the inference problem the state machine exists to remove.

The keywords are case-insensitive and can appear anywhere in a message. Small leak risk: "I'm going AFK tomorrow" would arm. Acceptable — false-arming is one word to fix; false-silence is a silent stall.

### 5. Soft-Check on long-idle pages

If the human forgets to BTK, the agent eventually hits a Blocked moment and pages annoyingly. The Soft-Check appends:

> Still AFK? Reply BTK if back.

…to any page sent after 30 min of human silence. This turns recurring annoying pages into a single self-correcting one.

**Honest limitation:** the agent has no internal timer, so the Soft-Check only fires on pages the agent was already going to send. It cannot fire during silent idle, and it cannot *prevent* the first annoying page — only label it. A real timer-driven check would require external infrastructure (cron), which is out of scope.

## Glossary

| Term | Meaning |
| --- | --- |
| **AFK Mode** | Session state where pager discipline is active. Entered via "AFK", exited via "BTK". |
| **Blocked** | Agent cannot proceed without the human. The pager trigger. |
| **Reporting** | Agent is working mid-turn. Not the pager trigger. |
| **Pager** | The Pushover script (`scripts/pager.sh`) that delivers a page. |
| **Soft-Check** | The "Still AFK?" label appended to long-idle pages. |

## What's deliberately not in this skill

- **Transcript delivery.** That's the web relay's job (Session Mirror). The page just signals "look now."
- **Inbound reply handling.** The human replies via the web relay, by walking back to the keyboard, or by any other channel they already use. The skill doesn't try to receive replies.
- **Auto-exit heuristics.** State transitions are keyword-driven only. If forget-to-disarm becomes painful in practice, a cron-based reminder is the next step — but that's future work, not part of this skill.
