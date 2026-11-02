<template>
  <div class="workflow-center">
    <el-tabs v-model="tab" class="tabs">
      <el-tab-pane name="todo">
        <template #label>
          <span>我的待办<el-badge v-if="todos.length" :value="todos.length" class="badge" /></span>
        </template>

        <div class="toolbar">
          <el-button size="small" :loading="loading" @click="loadAll">刷新</el-button>
          <span class="muted">共 {{ todos.length }} 条待办 · {{ overdueCount }} 条已超时</span>
        </div>

        <el-empty v-if="!loading && !todos.length" description="没有待办事项" />

        <el-card v-for="inst in todos" :key="inst.id" shadow="never" class="inst-card">
          <div class="inst-head">
            <div>
              <span class="title">{{ inst.title || inst.businessNo || `#${inst.businessId}` }}</span>
              <el-tag size="small" :type="statusTag(inst.status)" effect="plain">{{ inst.statusName }}</el-tag>
              <el-tag v-if="hasOverdue(inst)" size="small" type="danger" effect="dark">超时</el-tag>
            </div>
            <div class="meta">
              {{ inst.defName }} · 当前节点 {{ inst.currentNodeName || inst.currentNodeCode || '—' }}
              <span v-if="inst.ccUsers.length"> · 抄送 {{ inst.ccUsers.join('、') }}</span>
            </div>
          </div>

          <el-table :data="inst.tasks" size="small" border>
            <el-table-column prop="nodeName" label="节点" width="110" />
            <el-table-column prop="approverName" label="审批人" width="110" />
            <el-table-column label="状态" width="90" align="center">
              <template #default="{ row }">
                <el-tag size="small" :type="row.status === 0 ? 'warning' : row.status === 1 ? 'success' : 'info'">
                  {{ row.statusName }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="到期" width="150">
              <template #default="{ row }">
                <span :class="{ overdue: row.overdue }">{{ formatTime(row.dueAt) }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="opinion" label="意见" show-overflow-tooltip />
            <el-table-column label="操作" width="260" align="center">
              <template #default="{ row }">
                <template v-if="row.status === 0">
                  <el-button size="small" type="success" plain @click="approve(row, true)">通过</el-button>
                  <el-button size="small" type="danger" plain @click="approve(row, false)">驳回</el-button>
                  <el-button size="small" link @click="remind(row)">催办</el-button>
                  <el-dropdown size="small" trigger="click" @command="(cmd: string) => onCommand(cmd, inst, row)">
                    <el-button size="small" link>更多</el-button>
                    <template #dropdown>
                      <el-dropdown-menu>
                        <el-dropdown-item command="return">退回</el-dropdown-item>
                        <el-dropdown-item command="addsign">加签</el-dropdown-item>
                      </el-dropdown-menu>
                    </template>
                  </el-dropdown>
                </template>
              </template>
            </el-table-column>
          </el-table>

          <div class="inst-actions" v-if="inst.canWithdraw">
            <el-button size="small" type="warning" plain @click="withdraw(inst)">撤回</el-button>
          </div>
        </el-card>
      </el-tab-pane>

      <el-tab-pane name="cc">
        <template #label>
          <span>抄送我的<el-badge v-if="unread" :value="unread" class="badge" /></span>
        </template>

        <div class="toolbar">
          <el-button size="small" :loading="loading" @click="loadAll">刷新</el-button>
          <span class="muted">共 {{ ccs.length }} 条抄送，未读 {{ unread }} 条</span>
        </div>

        <el-empty v-if="!loading && !ccs.length" description="没有抄送给我的流程" />

        <el-card v-for="inst in ccs" :key="inst.id" shadow="never" class="inst-card">
          <div class="inst-head">
            <div>
              <span class="title">{{ inst.title || inst.businessNo || `#${inst.businessId}` }}</span>
              <el-tag size="small" :type="statusTag(inst.status)" effect="plain">{{ inst.statusName }}</el-tag>
            </div>
            <div class="meta">
              {{ inst.defName }} · 发起 {{ inst.startedByName || '—' }} · {{ formatTime(inst.startedAt) }}
            </div>
          </div>
          <el-timeline class="timeline">
            <el-timeline-item
              v-for="(log, i) in inst.logs"
              :key="i"
              :timestamp="formatTime(log.at)"
              placement="top"
              :type="log.action === 'REJECT' ? 'danger' : log.action === 'APPROVE' ? 'success' : 'primary'"
            >
              <b>{{ log.actionName }}</b>
              <span v-if="log.operatorName"> · {{ log.operatorName }}</span>
              <span v-if="log.opinion"> · {{ log.opinion }}</span>
            </el-timeline-item>
          </el-timeline>
          <el-button size="small" @click="markRead(inst)">标记已读</el-button>
        </el-card>
      </el-tab-pane>

      <el-tab-pane label="超时监控" name="overdue">
        <div class="toolbar">
          <el-button size="small" :loading="loading" @click="loadAll">刷新</el-button>
          <span class="muted">超过节点时限仍未处理的流程（管理员视角）</span>
        </div>
        <el-empty v-if="!loading && !overdueList.length" description="没有超时流程" />
        <el-card v-for="inst in overdueList" :key="inst.id" shadow="never" class="inst-card">
          <div class="inst-head">
            <div>
              <span class="title">{{ inst.title || inst.businessNo || `#${inst.businessId}` }}</span>
              <el-tag size="small" type="danger" effect="dark">超时</el-tag>
            </div>
            <div class="meta">{{ inst.defName }} · {{ inst.currentNodeName }} · 发起 {{ inst.startedByName }}</div>
          </div>
          <el-table :data="inst.tasks.filter((t) => t.overdue)" size="small" border>
            <el-table-column prop="approverName" label="审批人" width="120" />
            <el-table-column prop="nodeName" label="节点" width="120" />
            <el-table-column label="到期" width="160">
              <template #default="{ row }">
                <span class="overdue">{{ formatTime(row.dueAt) }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="120" align="center">
              <template #default="{ row }">
                <el-button size="small" type="warning" plain @click="remind(row)">催办</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <el-tab-pane label="审批代理" name="delegate">
        <div class="toolbar">
          <el-button size="small" type="primary" @click="newDelegate">新增代理</el-button>
          <span class="muted">代理生效期间，委托人的待办会直接派给代理人</span>
        </div>

        <el-table :data="delegates" size="small" border empty-text="还没有代理设置">
          <el-table-column label="委托人" width="140">
            <template #default="{ row }">{{ row.userName || `#${row.userId}` }}</template>
          </el-table-column>
          <el-table-column label="代理人" width="140">
            <template #default="{ row }">{{ row.delegateToName || `#${row.delegateToId}` }}</template>
          </el-table-column>
          <el-table-column label="生效区间" min-width="240">
            <template #default="{ row }">
              {{ formatTime(row.startAt) }} ~ {{ formatTime(row.endAt) }}
            </template>
          </el-table-column>
          <el-table-column label="状态" width="80" align="center">
            <template #default="{ row }">
              <el-tag size="small" :type="row.enabled ? 'success' : 'info'">{{ row.enabled ? '启用' : '停用' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="remark" label="备注" show-overflow-tooltip />
          <el-table-column label="操作" width="90" align="center">
            <template #default="{ row }">
              <el-button link size="small" type="danger" @click="removeDelegate(row.id)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="delegateVisible" title="新增审批代理" width="460px">
      <el-form :model="delegateForm" label-width="88px" size="small">
        <el-form-item label="委托人">
          <el-select v-model="delegateForm.userId" filterable>
            <el-option v-for="u in users" :key="u.id" :value="u.id" :label="u.displayName || u.userName" />
          </el-select>
        </el-form-item>
        <el-form-item label="代理人">
          <el-select v-model="delegateForm.delegateToId" filterable>
            <el-option v-for="u in users" :key="u.id" :value="u.id" :label="u.displayName || u.userName" />
          </el-select>
        </el-form-item>
        <el-form-item label="开始">
          <el-date-picker v-model="delegateForm.startAt" type="datetime" style="width: 100%" />
        </el-form-item>
        <el-form-item label="结束">
          <el-date-picker v-model="delegateForm.endAt" type="datetime" style="width: 100%" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="delegateForm.remark" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="delegateVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveDelegate">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  runtimeApi,
  type ApprovalInstance,
  type ApprovalTask,
  type DelegateDto
} from '../api/runtime'
import { designApi } from '../api/design'

const tab = ref('todo')
const todos = ref<ApprovalInstance[]>([])
const ccs = ref<ApprovalInstance[]>([])
const overdueList = ref<ApprovalInstance[]>([])
const delegates = ref<DelegateDto[]>([])
const unread = ref(0)
const loading = ref(false)
const saving = ref(false)
const delegateVisible = ref(false)
const users = ref<{ id: number; userName: string; displayName: string }[]>([])

const delegateForm = reactive({
  userId: 0,
  delegateToId: 0,
  startAt: null as Date | null,
  endAt: null as Date | null,
  remark: ''
})

const overdueCount = computed(() => todos.value.filter(hasOverdue).length)

function hasOverdue(inst: ApprovalInstance) {
  return inst.tasks.some((t) => t.overdue)
}
function statusTag(s: number) {
  return s === 1 ? 'success' : s === 2 ? 'danger' : s === 3 ? 'info' : 'warning'
}
function formatTime(t: string | null) {
  return t ? t.replace('T', ' ').slice(0, 19) : '—'
}

async function loadAll() {
  loading.value = true
  try {
    const [t, c, o, d, u] = await Promise.all([
      runtimeApi.todos(),
      runtimeApi.ccs(),
      runtimeApi.overdue(),
      runtimeApi.delegates(),
      designApi.approvalUsers()
    ])
    todos.value = t
    ccs.value = c
    overdueList.value = o
    delegates.value = d
    users.value = u
    unread.value = (await runtimeApi.unreadCc()).count
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    loading.value = false
  }
}

async function approve(task: ApprovalTask, approved: boolean) {
  try {
    const { value } = await ElMessageBox.prompt(
      approved ? '通过意见（可空）' : '驳回原因（建议填写）',
      approved ? '通过' : '驳回',
      { inputValue: approved ? '同意' : '' }
    )
    await runtimeApi.approve(task.id, approved, value ?? '')
    ElMessage.success(approved ? '已通过' : '已驳回')
    await loadAll()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

async function remind(task: ApprovalTask) {
  try {
    const { value } = await ElMessageBox.prompt('催办说明', '催办', { inputValue: '请尽快处理' })
    await runtimeApi.remind(task.id, value ?? '')
    ElMessage.success('已催办（写入流程日志）')
    await loadAll()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

async function onCommand(cmd: string, inst: ApprovalInstance, task: ApprovalTask) {
  if (cmd === 'return') {
    try {
      const codes = inst.tasks.map((t) => t.nodeCode).filter((c, i, a) => a.indexOf(c) === i)
      const { value } = await ElMessageBox.prompt(`退回目标节点（可选：${codes.join('/')}）`, '退回', {
        inputValue: codes[0] ?? ''
      })
      await runtimeApi.returnTo(task.id, value, '退回补充')
      ElMessage.success('已退回')
      await loadAll()
    } catch (e) {
      if (e !== 'cancel') ElMessage.error((e as Error).message)
    }
    return
  }
  if (cmd === 'addsign') {
    try {
      const { value } = await ElMessageBox.prompt(
        users.value.map((u, i) => `${i + 1}.${u.displayName || u.userName}`).join(' '),
        '加签：输入用户序号',
        {
          inputValidator: (v: string) => {
            const i = Number(v)
            return Number.isInteger(i) && i >= 1 && i <= users.value.length ? true : '请输入序号'
          }
        }
      )
      const u = users.value[Number(value) - 1]
      await runtimeApi.addSign(task.id, u.id, '加签')
      ElMessage.success('已加签')
      await loadAll()
    } catch (e) {
      if (e !== 'cancel') ElMessage.error((e as Error).message)
    }
  }
}

async function withdraw(inst: ApprovalInstance) {
  try {
    const { value } = await ElMessageBox.prompt('撤回原因', '撤回', { inputValue: '' })
    await runtimeApi.withdraw(inst.id, value ?? '')
    ElMessage.success('已撤回')
    await loadAll()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

async function markRead(inst: ApprovalInstance) {
  await runtimeApi.markCcRead(inst.id)
  ElMessage.success('已标记已读')
  await loadAll()
}

function newDelegate() {
  Object.assign(delegateForm, { userId: 0, delegateToId: 0, startAt: new Date(), endAt: null, remark: '' })
  delegateVisible.value = true
}

async function saveDelegate() {
  if (!delegateForm.userId || !delegateForm.delegateToId) {
    return ElMessage.warning('委托人和代理人都要选')
  }
  saving.value = true
  try {
    await runtimeApi.saveDelegate({
      userId: delegateForm.userId,
      delegateToId: delegateForm.delegateToId,
      startAt: delegateForm.startAt ? toLocalIso(delegateForm.startAt) : null,
      endAt: delegateForm.endAt ? toLocalIso(delegateForm.endAt) : null,
      enabled: true,
      remark: delegateForm.remark
    })
    ElMessage.success('已保存')
    delegateVisible.value = false
    await loadAll()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

/** 转成本地时间的 ISO 字符串（不带 Z），后端按服务器时区解释 */
function toLocalIso(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`
}

async function removeDelegate(id: number) {
  try {
    await ElMessageBox.confirm('删除该代理设置？', '确认', { type: 'warning' })
    await runtimeApi.deleteDelegate(id)
    ElMessage.success('已删除')
    await loadAll()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

onMounted(loadAll)
</script>

<style scoped>
.workflow-center { padding: 4px 2px; }
.tabs :deep(.el-tabs__content) { padding: 8px 2px; }
.toolbar { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }
.muted { color: var(--el-text-color-secondary); font-size: 12px; }
.inst-card { margin-bottom: 12px; }
.inst-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 8px; }
.title { font-weight: 600; margin-right: 8px; }
.meta { font-size: 11px; color: var(--el-text-color-secondary); text-align: right; }
.inst-actions { margin-top: 8px; }
.timeline { margin-top: 8px; }
.overdue { color: var(--el-color-danger); font-weight: 600; }
.badge { margin-left: 6px; }
</style>
