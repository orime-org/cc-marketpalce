#!/bin/bash
# Stop hook: 每轮结束建议调 watcher（不再按 token 阶梯，每轮都触发）
#
# 设计哲学（2026-05-13 重构）：
#   - 旧版（check-tokens-stairs.sh）按 token 阶梯强制触发，每跨档 1 次（共 ~6-10 次/会话）
#   - 新版：每轮都建议，让 Claude 自主判断本轮是否有新事实需要固化
#   - 副作用：每轮 block 1 次 → 每个用户消息会产生 2 个 LLM turn
#       turn 1: Claude 答 → Stop hook block → 注入 reason
#       turn 2: Claude 看到 reason，决定调 watcher 或忽略 → Stop hook 第二次触发（active=true）→ skip → 真正结束
#
# 跟 CC 设计的对齐：
#   - Stop hook 不支持 additionalContext（utils/hooks.ts schema 不列）
#   - 想让 Claude 看到提醒，只能走 block + reason 路径
#   - reason 会包装成 "Stop hook feedback:\n<reason>" 进 transcript user message

set -u

LOG=/tmp/cc-token-watch.log
TS=$(date '+%Y-%m-%d %H:%M:%S')

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# 防递归：第二次 Stop hook 调用（block 后 CC 自动启动的 turn 结束时）skip
if [ "$ACTIVE" = "true" ]; then
  printf '[%s] session=%s status=skip-stop-hook-active\n' "$TS" "${SESSION:-?}" >> "$LOG"
  exit 0
fi

printf '[%s] session=%s status=remind\n' "$TS" "${SESSION:-?}" >> "$LOG"

cat <<'EOF'
{
  "decision": "block",
  "reason": "📋 Per-turn Reminder — 调用 Skill 工具 `skill='watcher'`（默认 audit，不传 args）跑本轮收尾。\n\n按 SKILL.md 走完整 5 步流程 + 摘要（详见 SKILL.md / common-checks.md）。\n\n关键边界：\n- 自检根因：本轮方案是真解决根本 vs workaround？workaround 必须明示\n- Claude 不应自作主张转 configure 模式\n- 如 .watcher/ 缺失，提示用户手动 /watcher configure"
}
EOF
