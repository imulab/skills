# afk-pushover

A [ZCode](https://z.ai) skill that pages you on your phone (via [Pushover](https://pushover.net)) when an agent session needs your input — so you can step away from the keyboard and not silently stall.

## What it does

When you tell the agent **"AFK"**, the agent arms the pager. From then until you say **"BTK"**, every time the agent reaches a moment where it can't proceed without you — a question, an approval gate, a completed task awaiting direction — it pushes a notification to your phone. You glance, decide, reply (or walk back to the keyboard). The session never sits silently waiting.

- **Push delivery that actually wakes a locked iPhone.** Pushover uses APNs as its core product, unlike ntfy-on-iOS which is background-throttled.
- **Two-keyword state machine.** `AFK` arms, `BTK` disarms. No inference, no heuristics, no per-message carve-outs.
- **Pages on Blocked, not Reporting.** Mid-turn progress never pages; only moments that genuinely need you.
- **Soft-Check on long-idle pages.** If you forget to BTK and the agent pages hours later, the page says "Still AFK? Reply BTK if back." Self-correcting, not recurring.

## Requirements

- **ZCode** (this is a ZCode skill — won't work in Claude Code or other agents as-is).
- **A Pushover account** + the iOS/Android app installed and logged in. ([pushover.net](https://pushover.net); $5 one-time per platform after a 30-day trial.)
- **Two keys** from Pushover: your **User Key** and an **Application/API Token** (create one named e.g. `zcode-pager`).
- **macOS or Linux** (the pager is a bash script). Windows would need WSL or equivalent.
- `curl` (preinstalled on macOS and most Linux distros).

## Install

### 1. Install the skill

This repo lives at `~/workspace/skills` (or wherever you cloned it). ZCode discovers skills under `~/.agents/skills/`. Link it:

```sh
mkdir -p ~/.agents/skills
ln -s ~/workspace/skills/afk-pushover ~/.agents/skills/afk-pushover
```

The symlink means `git pull` in the repo updates the installed skill automatically.

**Alternative (copy instead of link):**

```sh
mkdir -p ~/.agents/skills
cp -r ~/workspace/skills/afk-pushover ~/.agents/skills/afk-pushover
```

You'll need to re-copy after updates.

### 2. Make the pager executable

```sh
chmod +x ~/workspace/skills/afk-pushover/scripts/pager.sh
```

### 3. Configure Pushover credentials

Create the env file (user-level, works in every project):

```sh
mkdir -p ~/.config/afk-pushover
cp ~/workspace/skills/afk-pushover/assets/env.local.example ~/.config/afk-pushover/.env
chmod 600 ~/.config/afk-pushover/.env
```

Edit `~/.config/afk-pushover/.env` and fill in the two values:

```sh
PUSHOVER_USER=...     # your user key from pushover.net dashboard
PUSHOVER_TOKEN=...    # an application token you created
```

**Env file lookup order** (first match wins) — useful if you need to override per-project:

1. `$AFK_PUSHOVER_ENV` (explicit path)
2. `~/.config/afk-pushover/.env` (default, recommended)
3. `<skill dir>/.env.local` (skill-local fallback)

### 4. Test the pager standalone

Verify delivery before relying on it in a session:

```sh
~/workspace/skills/afk-pushover/scripts/pager.sh "Pager test — if you can read this on a locked phone, the channel works."
```

You should see `paged: Agent needs you` in the terminal and get a lock-screen notification within a second or two.

If nothing arrives:
- Confirm the Pushover app is installed, logged in, and notifications are allowed.
- Send a test from the Pushover dashboard ("Send a test notification"). If that also fails, the issue is on the Pushover/app side, not the script.
- Check the script's stderr for HTTP errors (e.g. `HTTP 400` with `invalid user/key` means a typo in the env file).

## Use

Once installed, just talk to your agent normally. When you're about to step away:

> **AFK**

The agent will acknowledge ("AFK Mode engaged — I'll page you on Blocked moments") and from then on will page you whenever it hits a moment that needs you. When you're back:

> **BTK**

The agent acknowledges ("BTK — paging off") and stops paging.

You can include the keyword anywhere in a message — "I'm heading out, **AFK** for a bit" works.

## How it works

- `SKILL.md` — the agent-facing instructions. When the skill triggers, the agent reads this and follows the state machine + trigger rules.
- `scripts/pager.sh` — the bash script that sends a Pushover page. Reads secrets from the env file, never echoes them.
- `assets/env.local.example` — template for the env file.
- `references/design.md` — the *why* behind the rules. Read this if you want to change a rule or understand its motivation.

## Design at a glance

| Rule | Why |
| --- | --- |
| Page on Blocked only | Reporting pages cause alert fatigue; can't tell signal from noise |
| Agent decides to page (not a heuristic) | The decision itself is the Blocked signal — heuristics over- or under-fire |
| Two-keyword state machine | No inference; the keyword is the handshake |
| Soft-Check after 30 min idle | Catches forget-to-BTK; bounded failure mode (one annoying page, then self-corrects) |

See [references/design.md](./references/design.md) for the full rationale and the alternatives that were rejected.

## Limitations (honest)

- **Agent discipline required.** The trigger is skill-guided, not machine-enforced. The agent has to *decide* to call the pager at Blocked moments. If it gets absorbed in a task and asks itself internal questions without reaching a clean Blocked boundary, no page fires.
- **No transcript delivery.** The page tells you "look now"; it doesn't show you what to look at. Pair with ZCode's web remote control (Mobile remote control) for the full transcript on your phone.
- **Soft-Check is a label, not a timer.** The agent has no internal scheduler, so the Soft-Check only fires on pages the agent was already going to send. A real timer would need external infrastructure (cron).
- **Pushover costs $5/platform.** One-time, but not free. ntfy is free but unreliable on iOS — that's the trade.

## License

MIT — see [LICENSE](../LICENSE) in the repo root.
