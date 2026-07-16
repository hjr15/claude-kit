# claude-kit

A library of **agents** and **skills** for [Claude Code](https://claude.com/claude-code).
Clone it, run the installer, and they show up in your own Claude Code.

- **Agents** are specialists you can dispatch for a job — a backend architect, a security
  reviewer, a UX researcher, a performance engineer.
- **Skills** are procedures Claude follows when a situation matches — how to review a diff,
  how to run a team of agents, how to recover a bad merge.

## Install

```bash
git clone https://github.com/hjr15/claude-kit.git
cd claude-kit
bash install.sh
```

Then start (or restart) Claude Code. That's it.

The installer symlinks `skills/` and `agents/` into `~/.claude/`. It touches nothing else —
no settings are merged, no hooks are installed, nothing is overwritten. Because they're
symlinks, `git pull` updates everything with no reinstall.

```bash
bash install.sh --check   # report drift without changing anything
```

It's safe to re-run, and it will refuse rather than overwrite a skill or agent of your own
that happens to share a name.

To uninstall, delete the symlinks it made from `~/.claude/skills/` and `~/.claude/agents/`.

## What's inside

Teams of agents that work as a unit — `code-team`, `architect-team`, `testing-team`,
`marketing-team`, `mobile-team` — alongside standalone specialists and a set of workflow
skills covering code review, debugging, git recovery, and multi-agent orchestration.

Browse [`agents/`](agents/) and [`skills/`](skills/); every file is readable markdown, and
the frontmatter `description` is what Claude matches against to decide when to use it.

## Contributing

**Please open an issue** — for bugs, ideas, or a skill you'd like to see.

Pull requests can't be merged here, and that's structural rather than unfriendly: this repo
is generated automatically from a private one, so any commit made directly here is
overwritten by the next export. An issue is the way in, and it's genuinely welcome.

## Licence

MIT — see [LICENSE](LICENSE). Use it, fork it, adapt it.
