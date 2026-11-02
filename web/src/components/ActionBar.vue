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
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { runtimeApi, type ResolvedAction, type ResolvedButton } from '../api/runtime'

/**
 * 行内动作条：按钮完全来自后端元数据（含权限点与可见/可用表达式），前端不写死任何按钮。
 * 动作语义统一由后端 `POST /api/runtime/action/execute` 决定（内置/导航/命令/脚本），
 * 前端只按返回的 kind 做跳转、下载、刷新或提示。
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

const router = useRouter()
const buttons = ref<ResolvedButton[]>([])
const busy = ref('')

async function load() {
  const raw = props.row ? Number(props.row['Id'] ?? 0) : 0
  try {
    buttons.value = (await runtimeApi.buttons(props.objectCode, raw > 0 ? raw : undefined)).slice(0, 5)
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

/**
 * 确认文案：只有「会改数据」的动作才可能弹框，且只在设计器写了文案
 * 或这是删除动作时才弹；打开发表单/刷新/导出属于读操作，不打扰。
 */
function confirmTextOf(action: ResolvedAction, actions: ResolvedAction[], btnText: string): string | null {
  if (action.actionType === 2) return null
  if (action.builtinCode && ['OPEN_FORM', 'REFRESH', 'CLOSE', 'EXPORT'].includes(action.builtinCode)) {
    return null
  }
  return confirmOf(actions) ?? (action.builtinCode === 'DELETE' ? `${btnText}，确认继续？` : null)
}

/** 打印：取回渲染好的 HTML，写进新窗口再调浏览器打印。 */
async function printPage(url: string) {
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${localStorage.getItem('aschain.token') ?? ''}` }
  })
  if (!res.ok) throw new Error(`打印渲染失败（HTTP ${res.status}）`)
  const html = await res.text()
  const win = window.open('', '_blank')
  if (!win) {
    ElMessage.warning('浏览器拦截了新窗口，请允许弹窗后重试')
    return
  }
  win.document.write(html)
  win.document.close()
  win.focus()
  win.print()
}

/** 带 token 下载：导出接口需要鉴权，不能直接用 window.open。 */
async function download(url: string) {
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${localStorage.getItem('aschain.token') ?? ''}` }
  })
  if (!res.ok) throw new Error(`导出失败（HTTP ${res.status}）`)
  const blob = await res.blob()
  const name = url.includes('objectCode=')
    ? decodeURIComponent(url.split('objectCode=')[1].split('&')[0]).replace('.', '_') + '.csv'
    : 'export.csv'
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = name
  link.click()
  URL.revokeObjectURL(link.href)
}

async function run(btn: ResolvedButton) {
  const action = btn.actions[0]
  if (!action) return

  // 打开发表单是纯前端行为（弹出编辑框），不必绕服务端
  if (action.builtinCode === 'OPEN_FORM') {
    if (props.row) emit('open-form', props.row)
    return
  }

  const ask = confirmTextOf(action, btn.actions, btn.text)
  if (ask) {
    try {
      await ElMessageBox.confirm(ask, btn.text, { type: 'warning' })
    } catch {
      return
    }
  }

  busy.value = btn.code
  try {
    const id = Number(props.row?.['Id'] ?? 0)
    const result = await runtimeApi.executeAction({
      objectCode: props.objectCode,
      id: id > 0 ? id : null,
      buttonCode: btn.code,
      params: {
        businessNo: props.row?.['Code'] ?? props.row?.['DocNo'] ?? null,
        title: `${props.objectCode} ${props.row?.['Code'] ?? ''}`
      }
    })
    switch (result.kind) {
      case 'navigate':
        if (result.route) await router.push(result.route)
        break
      case 'download':
        if (result.downloadUrl) await download(result.downloadUrl)
        ElMessage.success('导出已开始下载')
        break
      case 'print':
        if (result.downloadUrl) await printPage(result.downloadUrl)
        break
      case 'refresh':
        ElMessage.success(result.message || '已执行')
        emit('refresh')
        break
      case 'message':
        ElMessage.info(result.message || '已执行')
        break
      default:
        ElMessage.success(result.message || '已执行')
    }
    const instanceId = result.data?.instanceId
    if (typeof instanceId === 'number') emit('submitted', instanceId)
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    busy.value = ''
  }
}

watch(() => props.row, load, { deep: true })
onMounted(load)
</script>

<style scoped>
.action-bar { display: inline-flex; gap: 8px; align-items: center; }
.muted { color: var(--el-text-color-placeholder); }
</style>
