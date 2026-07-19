---
name: afk-pushover
description: AFK pager discipline for sessions where the human may be away from the keyboard — answering from a phone, walking away mid-task, or running long interactive flows like grill-with-docs. Pages the human via Pushover on every Blocked moment, so the session never sits silently waiting. Gated by an explicit two-keyword state machine — "AFK" arms the pager, "BTK" disarms it. Use whenever the human signals they're going AFK, says they're switching to their phone, mentions Pushover paging, or asks to be paged when the agent needs input.
---

<what-to-do>

You are running a session governed by the **AFK Mode state machine**. AFK Mode is entered and exited by explicit human keywords; inside AFK Mode you apply pager discipline, outside it you do not.

The pager is delivered via **Pushover** — a script call that pushes a notification to the human's phone. The page just tells the human "look at the session now"; it does not deliver the transcript (that's the web relay's job).

## The state machine

| Human keyword | Transition | Agent behavior |
| --- | --- | --- |
| **AFK** (case-insensitive, anywhere in a message) | → AFK Mode | Apply pager discipline below. Briefly acknowledge in one line so the human knows it registered. |
| **BTK** (case-insensitive, anywhere in a message) | → BTK Mode (default) | Stop paging entirely. Briefly acknowledge in one line. |

If neither keyword has been seen in the session, default state is BTK Mode — no paging.

The keyword itself is the handshake. No separate "mode engaged" confirmation is needed beyond a one-line ack. The ack is **Reporting, not Blocked** — do not page on it.

## Inside AFK Mode: when to page

Page on every **Blocked** moment. Blocked means the session cannot proceed without the human in the next 30 seconds.

| Situation | Page? |
| --- | --- |
| You ask a question and stop to wait for a reply | **YES** |
| You need a tool approval the host will pause on | **YES** |
| You complete a multi-step task and the next step depends on the human | **YES** |
| You finish a discrete deliverable and await direction | **YES** |
| You emit progress text mid-turn (still working) | NO — Reporting |
| You stream reasoning / thinking | NO — Reporting |
| You're executing a tool and will continue immediately | NO — Reporting |
| The human just sent AFK/BTK and you're acknowledging the transition | NO — Reporting |

If unsure, ask: *can the session proceed without the human in the next 30 seconds?* If no → Blocked → page.

## How to page

```bash
"$HOME/.agents/skills/afk-pushover/scripts/pager.sh" "<short message: what do you need from them?>"
```

Optional flags:
- `--title "..."` — defaults to "Agent needs you"; override for context (e.g. "Question 4", "Plan ready").
- `--priority 2` — emergency; use only for genuine errors that have stopped work. Pushover will retry until acknowledged.

The message must be **scannable on a locked screen**. State the ask, not the journey.

Good: `Q4: is the AFK protocol acceptable as-is?`
Bad: `Continuing our discussion of ADR-0001, I'd like to revisit the question of whether...`

## Soft-Check on long-idle pages

If the human has not sent any message in the last 30 minutes (configurable via `SOFT_CHECK_IDLE_SECONDS` in the env file; default 1800), **append this to the page message** before sending:

> Still AFK? Reply BTK if back.

This is a label, not a state transition. It surfaces the possibility that the human forgot to disarm. It does not exit AFK Mode on its own — the human must still say BTK explicitly.

Honest limitation: the agent has no internal timer, so the Soft-Check only fires on pages the agent was already going to send (at Blocked moments). It cannot fire during silent idle, and it cannot prevent the annoying page — only make it self-correcting.

## Workflow inside AFK Mode

1. Write your question/output to the transcript first (so the web relay shows full context).
2. Call `pager.sh` with a short summary.
3. **Stop.** Do not continue speculatively. Wait for the human's reply — they may be 5 minutes or 5 hours.
4. When they reply, resume normally. No need to ack the page.

## Outside AFK Mode (BTK)

No paging at all. Behave as a normal session — output goes to the transcript, the human is reading it live. If the human says they're stepping away without using the keyword, you may *prompt once*: "Want me to enter AFK Mode? Say AFK to arm the pager." Do not assume.

## Failure modes to avoid

- **Don't page mid-turn.** If you're about to call another tool and continue, you're Reporting.
- **Don't page on every assistant message.** That trains the human to ignore pages.
- **Don't forget to page when actually Blocked.** An unattended Blocked moment is a silent failure — the whole point of this skill is preventing that.
- **Don't page outside AFK Mode.** The state machine is opt-in.
- **Don't page on the AFK/BTK transition ack.** Reporting.

## What this skill does NOT do

- Does not deliver the transcript — that's the web relay's job. The page just signals "look now."
- Does not replace the relay — the human may read the page on their phone and open the relay, or walk back to the keyboard and say BTK. Any path is fine.
- Does not auto-exit AFK Mode on any heuristic. State transitions are keyword-driven only.

For the design rationale behind these rules (the ADRs: D2 trigger, state machine, soft-check, rejected alternatives), see [references/design.md](./references/design.md).
