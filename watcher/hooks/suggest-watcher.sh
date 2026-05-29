#!/bin/bash
# Stop hook: 每轮结束建议调 watcher 跑收尾审查
#
# 设计：每轮 block 1 次 → 注入 reason → CC 自动启动新 turn 让 Claude 决定是否调 watcher
#       新 turn 结束时 stop_hook_active=true → skip → 真正结束
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
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
# CC 只在「最后一条 assistant 消息有纯文本」时才填 last_assistant_message（源码 utils/hooks.ts:3662-3668）；
# 字段缺失/null/空 = 本轮不是「给了最终收尾文本的正常 stop」（中途停 / 结尾是工具调用）→ 不该跑 audit
LAST_MSG=$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)

# 跳过计数：累计「距上次 audit 攒了多少轮没审计」，给最终 audit 放宽范围用。
# 文件放项目本地 .watcher/.skip-count（项目相关逻辑）；仅当 .watcher/ 已存在时计，不污染未配置项目。
# 计 2 类 skip：中途无收尾文本(skip-no-last-msg)、watcher 手动关闭期间(skip-project-disabled)。
# active=true（audit 自己那轮）不计。
SKIP_CNT=""
bump_skip_count() {
  [ -n "$CWD" ] && [ -d "$CWD/.watcher" ] || return 0
  local f="$CWD/.watcher/.skip-count" c
  c=$(cat "$f" 2>/dev/null || echo 0)
  case "$c" in ''|*[!0-9]*) c=0;; esac
  c=$((c + 1))
  echo "$c" > "$f"
  SKIP_CNT="$c"
}

# 防递归：第二次 Stop hook 调用（block 后 CC 自动启动的 turn 结束时）skip
# ★ active=true 是 CC 喂的「已 block 过一次」信号，跳过它是防死循环的唯一保险——绝不能动
if [ "$ACTIVE" = "true" ]; then
  printf '[%s] session=%s status=skip-stop-hook-active\n' "$TS" "${SESSION:-?}" >> "$LOG"
  exit 0
fi

# 项目级开关：当前项目存在 .watcher/.stop-disabled 文件 → skip 本轮提醒
# 用户用 /watcher-off 创建该文件，用 /watcher-on 删除
if [ -n "$CWD" ] && [ -f "$CWD/.watcher/.stop-disabled" ]; then
  bump_skip_count
  printf '[%s] session=%s cwd=%s status=skip-project-disabled skipcount=%s\n' "$TS" "${SESSION:-?}" "$CWD" "${SKIP_CNT:-NA}" >> "$LOG"
  exit 0
fi

# 只有「正常 stop」才进 watcher：CC 给了最终收尾文本（last_assistant_message 非空）才提醒跑 audit。
# 字段缺失 = CC 不是正常收尾（中途停 / 结尾工具调用 / 无最终文本）→ skip，不打扰 CC 干活
if [ -z "$LAST_MSG" ]; then
  bump_skip_count
  printf '[%s] session=%s status=skip-no-last-msg skipcount=%s\n' "$TS" "${SESSION:-?}" "${SKIP_CNT:-NA}" >> "$LOG"
  exit 0
fi

# 正常 stop，要提醒跑 audit：读跳过计数 → 拼进 reason（让 audit 把这 N 轮一起审）→ 清零
SKIPPED=0
if [ -n "$CWD" ] && [ -f "$CWD/.watcher/.skip-count" ]; then
  SKIPPED=$(cat "$CWD/.watcher/.skip-count" 2>/dev/null || echo 0)
  case "$SKIPPED" in ''|*[!0-9]*) SKIPPED=0;; esac
  rm -f "$CWD/.watcher/.skip-count"
fi
printf '[%s] session=%s status=remind skipped_since_last=%d\n' "$TS" "${SESSION:-?}" "$SKIPPED" >> "$LOG"

# reason 正文用单引号 heredoc 保留 backtick/引号原样；跳过提示按需前置；jq 负责 JSON 转义
STATIC_REASON=$(cat <<'EOF'
📋 Per-turn Reminder — 调用 Skill 工具 `skill='watcher'`（默认 audit，不传 args）跑本轮收尾。

按 SKILL.md 走完整 5 步流程 + 摘要（详见 SKILL.md）。

关键边界：
- 自检根因：本轮方案是真解决根本 vs workaround？workaround 必须明示
- Claude 不应自作主张转 configure 模式
- 如 .watcher/ 缺失，提示用户手动 /watcher configure
- 跑完 watcher audit 后，必须自己处理 audit 结果（按自检发现的问题做修正）；处理完如果原任务还没干完，继续把原任务干完，别停在 audit 这一步
EOF
)

SKIP_PREFIX=""
if [ "$SKIPPED" -gt 0 ]; then
  SKIP_PREFIX="⚠️ 距上次 audit 已累计 ${SKIPPED} 轮 stop 没审计（中途无收尾文本 / watcher 手动关闭期间）——这次 audit 范围要从「只本轮」放宽到「本轮 + 这 ${SKIPPED} 轮被跳过的工作」一起审，别只盯最后一轮。"$'\n\n'
fi

jq -n --arg reason "${SKIP_PREFIX}${STATIC_REASON}" '{decision:"block", reason:$reason}'
