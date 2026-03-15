#!/usr/bin/env bash
set -euo pipefail

# Usage:
# request-delete.sh "AgentName" "reason"

NAME="${1:-}"
REASON="${2:-未提供}"
if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <AgentName> [Reason]" >&2
  exit 1
fi

HR_ROOT="/home/administrator/.openclaw/agents/awk-hr"
AGENTS_ROOT="/home/administrator/.openclaw/agents"
TARGET="$AGENTS_ROOT/$NAME"
STATE="$HR_ROOT/state/delete-requests.tsv"
NOW="$(date '+%F %T')"
DATE_TAG="$(date +%Y%m%d)"
SEQ="$(($(grep -c "^DEL-$DATE_TAG-" "$STATE" 2>/dev/null || echo 0)+1))"
TASK_ID="DEL-$DATE_TAG-$(printf '%03d' "$SEQ")"

if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: agent workspace not found: $TARGET" >&2
  exit 2
fi

mkdir -p "$(dirname "$STATE")"

echo -e "$TASK_ID\t$NAME\t$TARGET\tPENDING_CONFIRMATION\t$NOW\t$REASON" >> "$STATE"

cat <<EOM
DELETE REQUEST CREATED
TaskID: $TASK_ID
Agent: $NAME
Workspace: $TARGET
Reason: $REASON

待你确认后执行：
确认删除 $TASK_ID
EOM
