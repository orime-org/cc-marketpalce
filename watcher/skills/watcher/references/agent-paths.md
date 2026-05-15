# Agent 记忆与配置路径速查

不同 agent 平台的记忆系统和项目配置文件位置不一样。执行第一步盘点时按你正在使用的平台查这张表。

## Claude Code

| 用途 | 路径 |
|---|---|
| 跨会话记忆（全局） | `~/.claude/projects/<encoded-project-path>/memory/` |
| 记忆索引文件 | `~/.claude/projects/<...>/memory/MEMORY.md` |
| 全局指令 | `~/.claude/CLAUDE.md` |
| 项目级指令 | 项目根 `CLAUDE.md`（可层级嵌套） |
| 项目本地指令（不入 git） | 项目根 `CLAUDE.local.md` |
| Skills 目录（全局） | `~/.claude/skills/<name>/SKILL.md` |
| Skills 目录（项目） | `<project>/.claude/skills/<name>/SKILL.md` |

记忆文件用 YAML frontmatter：`name` / `description` / `type`（user / feedback / project / reference）。

## OpenAI Codex

| 用途 | 路径 |
|---|---|
| 跨会话指令（全局） | `~/.codex/AGENTS.md` 或 `$CODEX_HOME/AGENTS.md` |
| 项目级指令 | 项目根 `AGENTS.md`（可层级嵌套） |
| 项目级 override | `AGENTS.override.md`（若存在，覆盖同目录 AGENTS.md） |
| Skills 目录 | `~/.codex/skills/<name>/SKILL.md` 或 `.codex/skills/<name>/` |

Codex 没有"记忆文件 + 索引"机制，所有跨会话信息直接写在 AGENTS.md。

fallback 文件名：`TEAM_GUIDE.md` 或 `.agents.md` 也要查。

## OpenClaw

| 用途 | 路径 |
|---|---|
| 用户级 skills | `~/.openclaw/skills/<name>/SKILL.md`（首次运行自动创建） |
| 项目级 skills | `.openclaw/skills/<name>/SKILL.md`（仓库根目录下） |
| Workspace skills | 当前 workspace 的 `skills/` 目录 |

加载优先级：workspace > project-agent > personal-agent > managed/local > bundled > extra dirs。

OpenClaw 无独立记忆机制——跨会话信息放项目根 markdown（CLAUDE.md / AGENTS.md / 等价文件），参照 Codex。

## OpenCode

| 用途 | 路径 |
|---|---|
| 全局配置 | `~/.config/opencode/` |
| 项目配置 | `.opencode/` |
| Skills 目录（项目） | `.opencode/skills/`、`.claude/skills/`、`.codex/skills/` 都会被扫描 |
| Skills 目录（全局） | `~/.config/opencode/skills/`、`~/.claude/skills/`、`~/.codex/skills/` |

OpenCode 同时读 Claude Code 和 Codex 的目录——watcher 装在 `~/.claude/skills/` 下三家都能识别。OpenClaw 走自己的 `~/.openclaw/skills/`，需要单独装一份（或符号链接）。

## Watcher 项目级 override 位置

每个 agent 平台通用 — `<project-root>/.watcher/`：

```
.watcher/
├── project-summary.md   # 一段话讲清"这是什么项目"
├── doc-inventory.md     # 应有的文档清单 + 改动 hint
└── watchlist.md         # 用户随时加的自定义关注点
```

## 如果当前 agent 没有独立记忆系统

跳过"记忆"那一层，把功夫全花在：

- 项目根 markdown（CLAUDE.md / AGENTS.md / 等价文件）
- README.md
- docs/

记忆是锦上添花，docs 才是项目知识的最低保障。

## 跨平台共存策略

如果一个项目同时被 Claude Code 用户和 Codex 用户使用：

- **项目根同时放 `CLAUDE.md` 和 `AGENTS.md`**，内容可以互相 symlink 或两边维护
- 或者一份内容主文件 + 另一份用一行 `See CLAUDE.md` 跳转
- docs/ 和 README 是平台中立的，不需要分两份
