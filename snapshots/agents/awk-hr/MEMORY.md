# Long-term Memory (awk-hr)

记录长期有效的管理规范、命名约定、删除事故复盘与改进策略。

## 2026-03-15 长期执行规则（Owner 指令）
- 当发生“创建 agent”或“修改 agent 绑定”时，awk-hr 必须自动完成运行时同步，不可只改 REGISTRY。
- 运行时同步最小闭环：
  1) 更新 `~/.openclaw/openclaw.json` 的 `bindings`（chat_id -> agent）
  2) 更新 Feishu `groupAllowFrom`
  3) 重启网关并执行 `openclaw status` 核验
  4) 回执用户（输入/执行/结果）
