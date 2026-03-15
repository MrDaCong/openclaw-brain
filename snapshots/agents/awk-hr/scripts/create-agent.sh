#!/usr/bin/env bash
set -euo pipefail

# Usage:
# create-agent.sh "AgentName" "职责" "语气" "群组(chat_id)"

NAME="${1:-}"
RESP="${2:-}"
TONE="${3:-}"
GROUP="${4:-}"

if [[ -z "$NAME" || -z "$RESP" || -z "$TONE" || -z "$GROUP" ]]; then
  echo "Usage: $0 <AgentName> <Responsibilities> <Tone> <Group(chat_id)>" >&2
  exit 1
fi

HR_ROOT="/home/administrator/.openclaw/agents/awk-hr"
AGENTS_ROOT="/home/administrator/.openclaw/agents"
TARGET="$AGENTS_ROOT/$NAME"
NOW="$(date '+%F %T')"
TODAY="$(date +%F)"
CREATE_LOG="$HR_ROOT/logs/create-log.md"
BIND_LOG="$HR_ROOT/logs/bind-log.md"
REGISTRY="$HR_ROOT/REGISTRY.md"
CFG="/home/administrator/.openclaw/openclaw.json"

if [[ -e "$TARGET" ]]; then
  echo "ERROR: agent workspace already exists: $TARGET" >&2
  exit 2
fi

mkdir -p "$TARGET/memory"

cat > "$TARGET/README.md" <<EOM
# $NAME

## Purpose
$RESP

## Tone
$TONE

## Boundaries
- 遵守系统与安全策略
- 高风险操作先确认
EOM

cat > "$TARGET/AGENTS.md" <<EOM
# AGENTS - $NAME

## Role
$RESP

## Constraints
- 按指令执行，记录关键决策
- 涉及删除/外发操作需明确确认
EOM

cat > "$TARGET/SOUL.md" <<EOM
# SOUL - $NAME

风格：$TONE
EOM

cat > "$TARGET/USER.md" <<EOM
# USER

- 服务对象：AWK
- 群组：$GROUP
EOM

cat > "$TARGET/TOOLS.md" <<'EOM'
# TOOLS

记录本 Agent 的工具、环境、资源映射。
EOM

cat > "$TARGET/MEMORY.md" <<'EOM'
# MEMORY

长期记忆（沉淀稳定规则与关键信息）。
EOM

cat > "$TARGET/memory/$TODAY.md" <<EOM
# $TODAY

- 初始化 Agent：$NAME
- 绑定群组(chat_id)：$GROUP
EOM

# Append registry row (new schema)
printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
  "$NAME" "$TARGET" "$GROUP" "$GROUP" "chat-isolation" "active" "$NOW" "$NOW" >> "$REGISTRY"

# Register runtime agent into openclaw.json
node - <<'NODE' "$CFG" "$NAME" "$TARGET"
const fs=require('fs');
const [p,id,workspace]=process.argv.slice(2);
const cfg=JSON.parse(fs.readFileSync(p,'utf8'));
cfg.agents ??= {};
let list=cfg.agents.list;
if(!Array.isArray(list)) list=[];
const idx=list.findIndex(a=>a&&a.id===id);
const base={id, workspace, model:{primary:'openai-codex/gpt-5.3-codex'}, tools:{profile:'full'}};
if(idx>=0) list[idx]={...base, ...list[idx], id, workspace}; else list.push(base);
cfg.agents.list=list;
fs.writeFileSync(p, JSON.stringify(cfg,null,2));
console.log('registered agent',id);
NODE

# Logs
{
  echo "\n## [$NOW] Created $NAME"
  echo "- Responsibilities: $RESP"
  echo "- Tone: $TONE"
  echo "- Workspace: $TARGET"
  echo "- Runtime: registered"
} >> "$CREATE_LOG"

{
  echo "\n## [$NOW] Bind $NAME"
  echo "- Group(chat_id): $GROUP"
  echo "- RouterMode: chat-isolation"
  echo "- Status: active"
} >> "$BIND_LOG"

# Restart gateway to load new runtime agent
echo "INFO: restarting gateway to activate runtime agent..."
openclaw gateway restart >/dev/null 2>&1 || true

echo "OK: created+registered+restarted '$NAME' at $TARGET"
