#!/usr/bin/env bash
set -euo pipefail
WS="/home/administrator/.openclaw/workspace"
SNAP="$WS/snapshots"
mkdir -p "$SNAP/agents" "$SNAP/runtime"
rm -rf "$SNAP/agents"/*
cp -a /home/administrator/.openclaw/agents/awk-hr "$SNAP/agents/"
cp -a /home/administrator/.openclaw/agents/awk-pop "$SNAP/agents/"
node - <<'NODE'
const fs=require('fs');
const src='/home/administrator/.openclaw/openclaw.json';
const dst='/home/administrator/.openclaw/workspace/snapshots/runtime/openclaw.runtime.redacted.json';
const c=JSON.parse(fs.readFileSync(src,'utf8'));
const out={
  meta:{generatedAt:new Date().toISOString(),source:'~/.openclaw/openclaw.json'},
  agents:{list:c.agents?.list||[],defaults:{model:c.agents?.defaults?.model||{},workspace:c.agents?.defaults?.workspace||null}},
  bindings:c.bindings||[],
  channels:{feishu:{enabled:c.channels?.feishu?.enabled,dmPolicy:c.channels?.feishu?.dmPolicy,groupPolicy:c.channels?.feishu?.groupPolicy,allowFrom:c.channels?.feishu?.allowFrom,groupAllowFrom:c.channels?.feishu?.groupAllowFrom,requireMention:c.channels?.feishu?.requireMention,groups:c.channels?.feishu?.groups||{}}}
};
fs.writeFileSync(dst, JSON.stringify(out,null,2));
console.log('updated',dst);
NODE
