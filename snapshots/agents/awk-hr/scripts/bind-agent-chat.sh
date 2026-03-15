#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-}"
CHAT_ID="${2:-}"
if [[ -z "$NAME" || -z "$CHAT_ID" ]]; then
  echo "Usage: $0 <AgentName> <chat_id>" >&2
  exit 1
fi
if [[ "$CHAT_ID" != oc_* ]]; then
  echo "ERROR: invalid chat_id format: $CHAT_ID" >&2
  exit 2
fi

HR_ROOT="/home/administrator/.openclaw/agents/awk-hr"
AGENTS_ROOT="/home/administrator/.openclaw/agents"
REG="$HR_ROOT/REGISTRY.md"
LOG="$HR_ROOT/logs/bind-log.md"
TARGET="$AGENTS_ROOT/$NAME"
NOW="$(date '+%F %T')"

if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: agent workspace not found: $TARGET" >&2
  exit 3
fi

node - <<'NODE' "$REG" "$NAME" "$TARGET" "$CHAT_ID" "$NOW"
const fs=require('fs');
const [reg,name,target,chat,now]=process.argv.slice(2);
const lines=fs.readFileSync(reg,'utf8').split(/\r?\n/);
let found=false;
const out=lines.map(line=>{
  if(!line.startsWith('|') || line.startsWith('|---')) return line;
  const m=line.match(/^\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$/);
  if(!m) return line;
  const [_,agent,workspace,group,chatId,router,status,created,updated]=m;
  if(agent!==name) return line;
  found=true;
  return `| ${agent} | ${target} | ${group} | ${chat} | chat-isolation | ${status || 'active'} | ${created || now} | ${now} |`;
});
if(!found){
  out.push(`| ${name} | ${target} | - | ${chat} | chat-isolation | active | ${now} | ${now} |`);
}
fs.writeFileSync(reg, out.join('\n'));
NODE

{
  echo "\n## [$NOW] Bind chat"
  echo "- Agent: $NAME"
  echo "- ChatID: $CHAT_ID"
  echo "- Mode: chat-isolation"
  echo "- Result: UPDATED"
} >> "$LOG"

echo "OK: bound $NAME -> $CHAT_ID"
