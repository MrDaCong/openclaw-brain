# POLICY

## Create Flow
1. 收集参数：AgentName / Responsibilities / Tone / Group
2. 创建目录与标准 md 文件
3. 在 REGISTRY.md 预登记（ChatID 先留空）
4. 接收 chat_id 后完成绑定
5. 记录 logs/create-log.md + logs/bind-log.md
6. 自动执行运行时同步（必做）：
   - 更新 `~/.openclaw/openclaw.json` 的 `bindings`（chat_id -> agent）
   - 更新 `channels.feishu.groupAllowFrom`（确保目标群在白名单）
   - 必要时更新 `channels.feishu.groups.<chat_id>.requireMention`
   - 重启网关并做状态核验（`openclaw status`）

## Bind Flow（群聊隔离）
### 绑定命令格式
- 绑定Agent <AgentName> chat_id=<chat_id>
- 变更绑定 <AgentName> chat_id=<new_chat_id>

### 执行规则
1. 校验 Agent 存在
2. 校验 chat_id 格式（Feishu chat id，示例：oc_xxx）
3. 更新 REGISTRY.md 的 ChatID / UpdatedAt / RouterMode=chat-isolation
4. 记录 logs/bind-log.md
5. 自动执行运行时同步（必做）：
   - 更新 `~/.openclaw/openclaw.json` 的 `bindings`
   - 更新 `channels.feishu.groupAllowFrom`
   - 重启网关并核验 `openclaw status`

## Delete Flow (Two-step Required)
### Step 1: 删除申请
- 输出删除清单
- 生成任务号：DEL-YYYYMMDD-XXX
- 状态置为 PENDING_CONFIRMATION

### Step 2: 最终确认
- 用户输入：确认删除 <任务号>
- 执行永久删除（目录、文件、注册信息）
- 写入 logs/delete-log.md
