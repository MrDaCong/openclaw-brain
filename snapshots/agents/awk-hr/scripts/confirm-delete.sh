#!/usr/bin/env bash
set -euo pipefail

# Usage:
# confirm-delete.sh "DEL-YYYYMMDD-XXX"

TASK_ID="${1:-}"
if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <TaskID>" >&2
  exit 1
fi

HR_ROOT="/home/administrator/.openclaw/agents/awk-hr"
STATE="$HR_ROOT/state/delete-requests.tsv"
DELETE_LOG="$HR_ROOT/logs/delete-log.md"
REGISTRY="$HR_ROOT/REGISTRY.md"
CFG="/home/administrator/.openclaw/openclaw.json"
NOW="$(date '+%F %T')"

if [[ ! -f "$STATE" ]]; then
  echo "ERROR: no delete requests found" >&2
  exit 2
fi

LINE="$(awk -F '\t' -v id="$TASK_ID" '$1==id{print $0}' "$STATE" | tail -n1)"
if [[ -z "$LINE" ]]; then
  echo "ERROR: task id not found: $TASK_ID" >&2
  exit 3
fi

STATUS="$(echo "$LINE" | awk -F '\t' '{print $4}')"
NAME="$(echo "$LINE" | awk -F '\t' '{print $2}')"
TARGET="$(echo "$LINE" | awk -F '\t' '{print $3}')"
REASON="$(echo "$LINE" | awk -F '\t' '{print $6}')"

if [[ "$STATUS" != "PENDING_CONFIRMATION" ]]; then
  echo "ERROR: task not pending: $TASK_ID status=$STATUS" >&2
  exit 4
fi

if [[ -d "$TARGET" ]]; then
  rm -rf "$TARGET"
fi

# Mark completed in state (append immutable event)
echo -e "$TASK_ID\t$NAME\t$TARGET\tCOMPLETED\t$NOW\t$REASON" >> "$STATE"

# Update registry row status to deleted (append audit line for traceability)
printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
  "$NAME" "$TARGET" "-" "-" "chat-isolation" "deleted" "$NOW" "$NOW" >> "$REGISTRY"

# Unregister runtime agent from openclaw.json
node - <<'NODE' "$CFG" "$NAME"
const fs=require('fs');
const [p,id]=process.argv.slice(2);
const cfg=JSON.parse(fs.readFileSync(p,'utf8'));
if(cfg.agents && Array.isArray(cfg.agents.list)){
  cfg.agents.list = cfg.agents.list.filter(a => !(a && a.id===id));
}
fs.writeFileSync(p, JSON.stringify(cfg,null,2));
console.log('unregistered agent',id);
NODE

{
  echo "\n## [$NOW] Deleted $NAME"
  echo "- TaskID: $TASK_ID"
  echo "- Workspace: $TARGET"
  echo "- Reason: $REASON"
  echo "- Runtime: unregistered"
  echo "- Result: COMPLETED"
} >> "$DELETE_LOG"

# Restart gateway to apply unregister
echo "INFO: restarting gateway to unload runtime agent..."
openclaw gateway restart >/dev/null 2>&1 || true

echo "OK: deleted+unregistered+restarted '$NAME' (task $TASK_ID)"
