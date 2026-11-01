<template>
  <div class="todo-view">
    <div class="header">
      <h2>我的待办</h2>
      <div>
        <el-button size="small" :loading="loading" @click="load">刷新</el-button>
      </div>
    </div>

    <el-empty v-if="!loading && !todos.length" description="没有待办事项" />

    <el-card v-for="inst in todos" :key="inst.id" shadow="never" class="todo-card">
      <div class="todo-head">
        <div>
          <span class="todo-title">{{ inst.title || inst.businessNo || `#${inst.businessId}` }}</span>
          <el-tag size="small" :type="statusTag(inst.status)" effect="plain">{{ inst.statusName }}</el-tag>
        </div>
        <div class="todo-meta">
          {{ inst.defName }} · {{ inst.objectCode }} · 发起人 {{ inst.startedByName || '—' }} ·
          {{ formatTime(inst.startedAt) }}
        </div>
      </div>

      <div class="nodes">
        <span class="current">当前节点：{{ inst.currentNodeName || inst.currentNodeCode || '—' }}</span>
      </div>

      <el-table :data="inst.tasks" size="small" border>
        <el-table-column prop="nodeName" label="节点" width="120" />
        <el-table-column prop="approverName" label="审批人" width="120" />
        <el-table-column prop="statusName" label="状态" width="90" align="center" />
        <el-table-column prop="opinion" label="意见" show-overflow-tooltip />
        <el-table-column label="操作" width="200" align="center">
          <template #default="{ row }">
            <template v-if="row.status === 0">
              <el-button size="small" type="success" plain @click="approve(row, true)">通过</el-button>
              <el-button size="small" type="danger" plain @click="approve(row, false)">驳回</el-button>
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

      <div class="actions" v-if="inst.canWithdraw">
        <el-button size="small" type="warning" plain @click="withdraw(inst)">撤回</el-button>
      </div>

      <el-collapse class="timeline">
        <el-collapse-item title="审批时间轴" :name="inst.id">
          <el-timeline>
            <el-timeline-item
              v-for="(log, i) in inst.logs"
              :key="i"
              :timestamp="formatTime(log.at)"
              placement="top"
            >
              <b>{{ log.actionName }}</b>
              <span v-if="log.operatorName"> · {{ log.operatorName }}</span>
              <span v-if="log.opinion"> · {{ log.opinion }}</span>
            </el-timeline-item>
          </el-timeline>
        </el-collapse-item>
      </el-collapse>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { runtimeApi, type ApprovalInstance, type ApprovalTask } from '../api/runtime'
import { designApi } from '../api/design'

const todos = ref<ApprovalInstance[]>([])
const loading = ref(false)

function statusTag(s: number) {
  return s === 1 ? 'success' : s === 2 ? 'danger' : s === 3 ? 'info' : 'warning'
}
function formatTime(t: string | null) {
  return t ? t.replace('T', ' ').slice(0, 19) : '—'
}

async function load() {
  loading.value = true
  try {
    todos.value = await runtimeApi.todos()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    loading.value = false
  }
}

async function approve(task: ApprovalTask, approved: boolean) {
  try {
    const { value } = await ElMessageBox.prompt(approved ? '通过意见（可空）' : '驳回原因（建议填写）', approved ? '通过' : '驳回', {
      inputPlaceholder: approved ? '同意' : '请说明原因',
      inputValue: approved ? '同意' : ''
    })
    await runtimeApi.approve(task.id, approved, value ?? '')
    ElMessage.success(approved ? '已通过' : '已驳回')
    await load()
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
      await load()
    } catch (e) {
      if (e !== 'cancel') ElMessage.error((e as Error).message)
    }
    return
  }
  if (cmd === 'addsign') {
    try {
      const users = await designApi.approvalUsers()
      const { value } = await ElMessageBox.prompt(
        users.map((u, i) => `${i + 1}.${u.displayName || u.userName}`).join(' '),
        '加签：输入用户序号',
        {
          inputValidator: (v: string) => {
            const i = Number(v)
            return Number.isInteger(i) && i >= 1 && i <= users.length ? true : '请输入序号'
          }
        }
      )
      const u = users[Number(value) - 1]
      await runtimeApi.addSign(task.id, u.id, '加签')
      ElMessage.success('已加签')
      await load()
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
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

onMounted(load)
</script>

<style scoped>
.todo-view { padding: 4px 2px; }
.header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.header h2 { margin: 0; font-size: 18px; }
.todo-card { margin-bottom: 12px; }
.todo-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; }
.todo-title { font-weight: 600; margin-right: 8px; }
.todo-meta { font-size: 11px; color: var(--el-text-color-secondary); text-align: right; }
.nodes { margin: 8px 0; font-size: 12px; color: var(--el-text-color-secondary); }
.current { color: var(--el-color-primary); }
.actions { margin-top: 8px; }
.timeline { margin-top: 8px; }
</style>
