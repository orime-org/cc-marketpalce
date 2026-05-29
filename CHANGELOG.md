# Changelog

## 0.1.3 — 2026-05-29

### Module: Watcher

announce 治理框架完整升级——根因主线 + 硬命令句风对齐：

- **段 3 整段重组**：
  - 4 步流程拆成 `### 3.1 复述需求` / `### 3.2 分析根因` / `### 3.3 给彻底方案` / `### 3.4 我打算干啥` 三级子段
  - 段首加问询例外开关："如果我只是问一个事，那么直接答就行；否则就必须严格按照以下四步流程"
  - 段 3.2 段标 "分析本质" → "分析根因"，内容强化根因思考的强制性
  - 段 3.3 内容改 "基于真实根因思考彻底的解决方案是啥"，临时方案必须明说找不到根因
  - 多步任务规则前置（TaskCreate 高频规则放前），问询例外后置
  - "用 TaskCreate" → "必须用 TaskCreate" 措辞强化
- **段 7 段标全句化**："解决任何问题必须先找根因，并且根因必须靠真正的证据来决定"
- **段 8 段标全句化**："解决问题必须用彻底的解决方案，严禁打任何折扣"
- **新增段 11 死刑底线**："你出现任何分析问题不找根因和解决问题不用彻底方案的行为，那么你他妈的就给我去死吧！"
- **段 9 / 段 10 内容互换**：DD/TDD/smoke/E2E 测试规范优先于 PR 善后（按触发频率排序）
- **段 10 → 段 9 扩展**：从 DD/TDD 二元扩到 DD/TDD/smoke/E2E 四元测试规范覆盖；提示文案改 "缺少某某 的流程规范，请你先完善，完善后我会更好的为你工作"
- **全局 "用户" → "我"**（脚本顶部 comment 保留——不进 hook stdout）
- **README.md / README.zh-CN.md 同步**：组件表 + 章节标题 + 列表 10 段 → 11 段；段 7/8/11 表达对齐

## 0.1.2 — 2026-05-28

### Module: Watcher

- announce 段 7 标题升级为硬命令句全句风：`解决任何问题必须先找根因，并且根因必须靠真正的证据来决定`
- announce 段 8 标题升级为硬命令句全句风：`解决问题必须用彻底的解决方案，严禁打任何折扣`
- 新增 announce 段 11 `死刑底线`——治理框架顶规则封顶强调
- README.md / README.zh-CN.md 同步:组件表/章节标题/列表 10 段 → 11 段
- slash command 命名引用 `/watcher-off` `/watcher-on` → `/watcher:watcher-off` `/watcher:watcher-on`（修 0.1.1 命名引用 bug，跟实际 plugin 加载形态对齐）
- 段内 bullet 内容不变,只升级段标语气

## 0.1.1 — 2026-05-28

### Module: Watcher
- Per-project Stop hook toggle: `/watcher:watcher-off` and `/watcher:watcher-on` slash commands
- Stop hook reads `cwd` from stdin and skips reminder if `<cwd>/.watcher/.stop-disabled` exists
- UserPromptSubmit announce rules remain active when Stop reminder is toggled off

## 0.1.0 — 2026-05-15

Initial release.

### Module: Watcher
- `UserPromptSubmit` hook: Pre-turn 4-step intent guard
- `Stop` hook: Knowledge audit reminder + root-cause review trigger
- `watcher` skill (two modes: audit / configure)
- Project-level config support via `<project>/.watcher/` (3 files: project-summary / doc-inventory / watchlist)
