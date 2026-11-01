<template>
  <span class="action-bar">
    <el-tooltip
      v-for="btn in buttons"
      :key="btn.code"
      :disabled="btn.enabled"
      :content="btn.disableReason || ''"
      placement="top"
    >
      <el-button
        :type="btn.style || 'primary'"
        link
        size="small"
        :disabled="!btn.enabled"
        :loading="busy === btn.code"
        @click="run(btn)"
      >
        {{ btn.text }}
      </el-button>
    </el-tooltip>
    <span v-if="!buttons.length" class="muted">—</span>
  </span>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { runtimeApi, type ResolvedButton, type ResolvedAction } from '../api/runtime'

/**
 * 行内动作条：按钮完全来自后端元数据（含权限点与可见/可用表达式），
 * 前端不写死任何按钮。当前支持内置动作：OPEN_FORM / DELETE / SUBMIT / EXPORT / REFRESH。
 */
const props = defineProps<{
  objectCode: string
  row: Record<string, unknown> | null
}>()

const emit = defineEmits<{
  (e: 'open-form', row: Record<string, unknown>): void
  (e: 'refresh'): void
  (e: 'submitted', instanceId: number): void
}>()

const buttons = ref<ResolvedButton[]>([])
const busy = ref('')

async function load() {
  const id = props.row ? Number(props.row['Id'] ?? 0) : undefined
  try {
    const list = await runtimeApi.buttons(props.objectCode, id && id > 0 ? id : undefined)
    buttons.value = list.slice(0, 5)
  } catch {
    buttons.value = []
  }
}

function confirmOf(actions: ResolvedAction[]): string | null {
  for (const a of actions) {
    if (a.confirmText) return a.confirmText
  }
  return null
}

async function run(btn: ResolvedButton) {
  const action = btn.actions[0]
  if (!action) return
  const ask = confirmOf(btn.actions)
  if (ask) {
    try {
      await ElMessageBox.confirm(ask, btn.text, { type: 'warning' })
    } catch {
      return
    }
  }
  busy.value = btn.code
  try {
    switch (action.builtinCode) {
      case 'OPEN_FORM':
        if (props.row) emit('open-form', props.row)
        break
      case 'DELETE':
        await doDelete()
        break
      case 'SUBMIT':
        await doSubmit(action)
        break
      case 'REFRESH':
        emit('refresh')
        break
      case 'EXPORT':
        ElMessage.success(action.successMessage || '导出任务已提交（本期为占位实现）')
        break
      default:
        ElMessage.info(`动作 ${action.builtinCode ?? action.command ?? '未知'} 暂未实现`)
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    busy.value = ''
  }
}

async function doDelete() {
  const id = Number(props.row?.['Id'] ?? 0)
  if (!id) return ElMessage.warning('缺少主键，无法删除')
  const rowNo = props.row?.['Code'] ?? props.row?.['Name'] ?? id
  await ElMessageBox.confirm(`确认删除 ${String(rowNo)}？`, '删除', { type: 'warning' })
  // 删除走保存引擎的“标记删除”语义：提交 IsDeleted=1，由后端规则/权限把关
  await fetch(`/api/meta/${encodeURIComponent(props.objectCode)}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json;charset=UTF-8',
      Authorization: `Bearer ${localStorage.getItem('apserp.token') ?? ''}`
    },
    body: JSON.stringify({ Id: id, IsDeleted: true })
  })
  ElMessage.success('已删除')
  emit('refresh')
}

async function doSubmit(action: ResolvedAction) {
  const row = props.row
  if (!row) return ElMessage.warning('请先选择一行')
  const id = Number(row['Id'] ?? 0)
  if (!id) return ElMessage.warning('缺少主键，无法提交')
  const businessNo = String(row['Code'] ?? row['DocNo'] ?? '')
  const r = await runtimeApi.submit({
    objectCode: props.objectCode,
    businessId: id,
    businessNo,
    title: `${props.objectCode} ${businessNo}`
  })
  ElMessage.success(action.successMessage || '已提交审批')
  emit('submitted', r.instanceId)
  emit('refresh')
}

watch(() => props.row, load, { deep: true })
onMounted(load)
</script>

<style scoped>
.action-bar { display: inline-flex; gap: 8px; align-items: center; }
.muted { color: var(--el-text-color-placeholder); }
</style>
