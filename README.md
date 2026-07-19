# skills

Personal ZCode skills.

## Skills

| Skill | What it does |
| --- | --- |
| [afk-pushover](./afk-pushover/) | Pages you on your phone (via Pushover) when an agent session needs your input. Two-keyword state machine: "AFK" arms the pager, "BTK" disarms. Pages on Blocked moments only. |

## Installing a skill

Skills here are sources; install them into ZCode's discovery path so the agent can find them. Default discovery location is `~/.agents/skills/` (cross-tool, user-level).

Symlink (recommended — `git pull` updates the installed skill automatically):

```sh
mkdir -p ~/.agents/skills
ln -sfn ~/workspace/skills/<skill-name> ~/.agents/skills/<skill-name>
```

Or copy (re-copy after updates):

```sh
mkdir -p ~/.agents/skills
cp -r ~/workspace/skills/<skill-name> ~/.agents/skills/<skill-name>
```

Each skill may have additional setup steps (credentials, dependencies). See the skill's own `README.md`.

## License

MIT — see [LICENSE](./LICENSE).
