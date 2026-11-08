# skills

Personal ZCode skills.

## Skills

| Skill | What it does |
| --- | --- |
| [afk-pushover](./afk-pushover/) | Pages you on your phone (via Pushover) when an agent session needs your input. Two-keyword state machine: "AFK" arms the pager, "BTK" disarms. Pages on Blocked moments only. |
| [grilling](./grilling/) | The interview every grill skill runs: numbered rounds over a decision tree, with each question carrying its context, its terms glossed, and a reasoned recommendation. Forked from [mattpocock/skills](https://github.com/mattpocock/skills) so the question contract survives pack updates. |
| [batch-grill-me](./batch-grill-me/) | The same interview with the whole frontier asked in one round. Delegates to `/grilling`. |

### Forks

`grilling` and `batch-grill-me` are installed by symlink from here rather than from the upstream pack, because the upstream question contract did not carry context, term explanations, or the reasoning behind a recommendation, and a pack update would overwrite a local edit. They keep the upstream name and path, so `/grill-me`, `/grill-with-docs`, `/triage`, `/wayfinder` and every other delegate keep working unchanged. Both came from [mattpocock/skills](https://github.com/mattpocock/skills), installed on 2026-08-11. Update a fork by diffing it against upstream by hand.

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
