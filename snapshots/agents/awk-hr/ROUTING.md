# ROUTING.md - Main 路由固化规范（chat-isolation）

## 目标
在仅有一个 Feishu 机器人的情况下，实现多 Agent 稳定分工、上下文隔离、可审计。

## 路由原则
1. 群聊按 `chat_id` 硬匹配到唯一 Agent（不做关键词猜测）。
2. 命中后由对应 Agent 处理；main 仅做分发与回传。
3. 未命中 `chat_id` 时，返回“未绑定”，引导用 awk-hr 完成绑定。
4. 绑定与改绑以 `REGISTRY.md` 为唯一真相源。

## 数据来源
`/home/administrator/.openclaw/agents/awk-hr/REGISTRY.md`

使用字段：
- AgentName
- ChatID
- RouterMode（要求 `chat-isolation`）
- Status（要求 `active`）

## 主流程
1. main 收到消息（含 `chat_id`）
2. 查询 REGISTRY：`ChatID == 当前chat_id && Status == active`
3. 若命中：路由到对应 Agent
4. 若未命中：返回“此群未绑定 Agent，请联系 awk-hr 绑定”

## 生命周期联动
- 创建 Agent：先建目录与模板，再绑定 chat_id，最后置为 active
- 变更绑定：仅允许 awk-hr 执行，更新 REGISTRY 与 bind-log
- 删除 Agent：执行二次确认后，状态改为 deleted/inactive，并清理工作区

## 安全要求
- 同一 chat_id 不允许绑定多个 active Agent
- 删除必须二次确认：申请单 + 确认口令
- 全部操作写日志（create/bind/delete）

## 日常操作口令（建议）
- 绑定Agent awk-pop chat_id=oc_xxx
- 变更绑定 awk-pop chat_id=oc_yyy
- 查看注册表（REGISTRY）
- 删除Agent awk-pop（会进入二次确认）

## 当前已绑定
- awk-pop -> oc_b34019cc0cfae6d86efe0600b0803409
