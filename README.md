# Orime — Plugin Marketplace

Collection of Claude Code plugins for self-monitoring and knowledge curation.

## Plugins in this marketplace

### `watcher` (0.1.0)

Pre-turn intent guard + Stop-time knowledge audit—keeps Claude accountable and the knowledge base in sync.

- **`UserPromptSubmit` hook**: 4-step reminder before every turn (复述需求 → 分析本质 → 给彻底方案 → 告知意图) + 4 action-type branches with explicit tool/skill pre-announcement
- **`Stop` hook**: Block + remind to invoke `watcher` skill for root-cause review + knowledge persistence
- **`watcher` skill** (two modes: audit / configure): Run a 5-step knowledge audit or configure project-level `.watcher/`

## Installation

```bash
/plugin marketplace add github:<user>/orime
/plugin install watcher@orime
```

Or for local development:

```bash
/plugin marketplace add <path-to-orime>
/plugin install watcher@orime
```

## License

MIT
