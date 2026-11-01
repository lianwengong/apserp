<template>
  <el-drawer v-model="visible" :title="title" size="480px" @open="load">
    <div v-loading="loading">
      <el-empty v-if="!loading && !instances.length" description="该单据还没有审批记录" />

      <div v-for="inst in instances" :key="inst.id" class="instance">
        <div class="inst-head">
          <span class="inst-title">{{ inst.title || inst.businessNo || `#${inst.businessId}` }}</span>
          <el-tag size="small" :type="statusTag(inst.status)" effect="plain">{{ inst.statusName }}</el-tag>
        </div>
        <div class="inst-meta">
          {{ inst.defName }} · 当前节点 {{ inst.currentNodeName || inst.currentNodeCode || '—' }} ·
          发起 {{ inst.startedByName || '—' }}
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
            <div v-if="log.opinion" class="opinion">{{ log.opinion }}</div>
          </el-timeline-item>
        </el-timeline>

        <el-table :data="inst.tasks" size="small" border>
          <el-table-column prop="nodeName" label="节点" width="100" />
          <el-table-column prop="approverName" label="审批人" width="100" />
          <el-table-column prop="statusName" label="状态" width="80" align="center" />
          <el-table-column prop="opinion" label="意见" show-overflow-tooltip />
        </el-table>

        <div class="inst-actions">
          <el-button
            v-if="inst.canWithdraw"
            size="small"
            type="warning"
            plain
            @click="withdraw(inst)"
          >
            撤回
          </el-button>
        </div>
      </div>
    </div>
  </el-drawer>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { runtimeApi, type ApprovalInstance } from '../api/runtime'

const props = defineProps<{
  modelValue: boolean
  objectCode: string
  businessId: number | null
}>()
const emit = defineEmits<{ (e: 'update:modelValue', v: boolean): void; (e: 'changed'): void }>()

const visible = computed({
  get: () => props.modelValue,
  set: (v: boolean) => emit('update:modelValue', v)
})
const title = computed(() => `审批记录 · ${props.objectCode}`)
const instances = ref<ApprovalInstance[]>([])
const loading = ref(false)

function statusTag(s: number) {
  return s === 1 ? 'success' : s === 2 ? 'danger' : s === 3 ? 'info' : 'warning'
}
function formatTime(t: string | null) {
  return t ? t.replace('T', ' ').slice(0, 19) : '—'
}

async function load() {
  if (!props.businessId) return
  loading.value = true
  try {
    instances.value = await runtimeApi.instances(props.objectCode, props.businessId)
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    loading.value = false
  }
}

async function withdraw(inst: ApprovalInstance) {
  try {
    const { value } = await ElMessageBox.prompt('撤回原因', '撤回', { inputValue: '' })
    await runtimeApi.withdraw(inst.id, value ?? '')
    ElMessage.success('已撤回')
    await load()
    emit('changed')
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

watch(() => props.businessId, load)
</script>

<style scoped>
.instance { border-bottom: 1px dashed var(--el-border-color); padding-bottom: 12px; margin-bottom: 12px; }
.inst-head { display: flex; justify-content: space-between; align-items: center; }
.inst-title { font-weight: 600; }
.inst-meta { font-size: 11px; color: var(--el-text-color-secondary); margin: 2px 0 8px; }
.timeline { padding-left: 2px; margin-top: 8px; }
.opinion { font-size: 12px; color: var(--el-text-color-regular); margin-top: 2px; }
.inst-actions { margin-top: 8px; }
</style>
