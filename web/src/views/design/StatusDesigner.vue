<template>
  <div class="status-designer">
    <el-alert type="info" :closable="false" show-icon class="tip">
      单据状态机：声明每个状态能否<b>编辑/删除/提交</b>，以及哪些<b>动作码</b>能把单据推到哪个状态。
      引擎在保存、删除、提交审批三处设卡；审批通过与驳回自动按 <code>APPROVE</code> / <code>REJECT</code> 流转。
      没配状态的对象不受影响。
    </el-alert>

    <el-row :gutter="12">
      <el-col :span="7">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>数据对象</span>
              <el-button size="small" :loading="loading" @click="load">刷新</el-button>
            </div>
          </template>
          <el-scrollbar height="470px">
            <div
              v-for="o in objects"
              :key="o.objectCode"
              class="object-item"
              :class="{ active: o.objectCode === objectCode }"
              @click="select(o.objectCode)"
            >
              <div class="obj-top">
                <span class="mono">{{ o.objectCode }}</span>
                <el-tag v-if="o.statusField" size="small" type="success" effect="plain">
                  {{ o.statusCount }} 状态
                </el-tag>
                <el-tag v-else size="small" type="info" effect="plain">未接入</el-tag>
              </div>
              <div class="obj-meta">
                {{ o.objectName }} · 流转 {{ o.transitionCount }} 条
                <span v-if="o.statusField"> · 字段 {{ o.statusField }}</span>
              </div>
            </div>
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="17">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>状态与流转 <b v-if="objectCode">{{ objectCode }}</b></span>
              <el-button
                v-if="objectCode && !statuses.length"
                size="small"
                type="primary"
                @click="initDefault"
              >
                初始化默认状态
              </el-button>
            </div>
          </template>

          <div v-if="!objectCode" class="empty-tip">先选左侧数据对象</div>

          <template v-else>
            <div class="section-title">状态</div>
            <el-table :data="statuses" size="small" border empty-text="还没有状态">
              <el-table-column label="值" width="70" align="center">
                <template #default="{ row }">
                  <el-input-number v-model="row.statusValue" size="small" :min="0" :max="255" :controls="false" style="width: 100%" />
                </template>
              </el-table-column>
              <el-table-column label="名称" width="140">
                <template #default="{ row }">
                  <el-input v-model="row.statusName" size="small" />
                </template>
              </el-table-column>
              <el-table-column label="可编辑" width="76" align="center">
                <template #default="{ row }"><el-checkbox v-model="row.canEdit" /></template>
              </el-table-column>
              <el-table-column label="可删除" width="76" align="center">
                <template #default="{ row }"><el-checkbox v-model="row.canDelete" /></template>
              </el-table-column>
              <el-table-column label="可提交" width="76" align="center">
                <template #default="{ row }"><el-checkbox v-model="row.canSubmit" /></template>
              </el-table-column>
              <el-table-column label="终态" width="66" align="center">
                <template #default="{ row }"><el-checkbox v-model="row.isFinal" /></template>
              </el-table-column>
              <el-table-column label="颜色" width="110">
                <template #default="{ row }">
                  <el-select v-model="row.colorType" size="small" clearable>
                    <el-option value="info" label="灰" />
                    <el-option value="primary" label="蓝" />
                    <el-option value="warning" label="橙" />
                    <el-option value="success" label="绿" />
                    <el-option value="danger" label="红" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="排序" width="80" align="center">
                <template #default="{ row }">
                  <el-input-number v-model="row.sort" size="small" :step="10" :controls="false" style="width: 100%" />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="110" align="center">
                <template #default="{ row }">
                  <el-button link size="small" type="primary" @click="saveStatus(row)">保存</el-button>
                  <el-button link size="small" type="danger" @click="removeStatus(row)">删</el-button>
                </template>
              </el-table-column>
            </el-table>
            <el-button size="small" plain style="margin-top: 8px" @click="addStatus">新增状态</el-button>

            <div class="section-title" style="margin-top: 16px">流转</div>
            <el-table :data="transitions" size="small" border empty-text="还没有流转">
              <el-table-column label="从" width="90" align="center">
                <template #default="{ row }">
                  <el-input-number v-model="row.fromStatus" size="small" :min="0" :max="255" :controls="false" style="width: 100%" />
                </template>
              </el-table-column>
              <el-table-column label="到" width="90" align="center">
                <template #default="{ row }">
                  <el-input-number v-model="row.toStatus" size="small" :min="0" :max="255" :controls="false" style="width: 100%" />
                </template>
              </el-table-column>
              <el-table-column label="动作码" width="150">
                <template #default="{ row }">
                  <el-input v-model="row.actionCode" size="small" placeholder="SUBMIT / APPROVE" />
                </template>
              </el-table-column>
              <el-table-column label="动作名" min-width="140">
                <template #default="{ row }">
                  <el-input v-model="row.actionName" size="small" placeholder="提交审批" />
                </template>
              </el-table-column>
              <el-table-column label="启用" width="70" align="center">
                <template #default="{ row }"><el-switch v-model="row.enabled" size="small" /></template>
              </el-table-column>
              <el-table-column label="操作" width="110" align="center">
                <template #default="{ row }">
                  <el-button link size="small" type="primary" @click="saveTransition(row)">保存</el-button>
                  <el-button link size="small" type="danger" @click="removeTransition(row)">删</el-button>
                </template>
              </el-table-column>
            </el-table>
            <el-button size="small" plain style="margin-top: 8px" @click="addTransition">新增流转</el-button>
          </template>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { designApi, type StatusRow, type TransitionRow } from '../../api/design'

const objects = ref<
  { objectCode: string; objectName: string; statusField: string | null; statusCount: number; transitionCount: number }[]
>([])
const objectCode = ref('')
const statuses = ref<StatusRow[]>([])
const transitions = ref<TransitionRow[]>([])
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    const overview = await designApi.docStatusOverview()
    objects.value = overview.objects ?? []
    if (!objectCode.value) {
      const first = objects.value.find((o) => o.statusField) ?? objects.value[0]
      if (first) objectCode.value = first.objectCode
    }
    await loadDetail()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    loading.value = false
  }
}

async function loadDetail() {
  if (!objectCode.value) return
  const detail = await designApi.docStatusDetail(objectCode.value)
  statuses.value = detail.statuses
  transitions.value = detail.transitions
}

async function select(code: string) {
  objectCode.value = code
  await loadDetail()
}

function addStatus() {
  const nextValue = Math.max(-1, ...statuses.value.map((s) => s.statusValue)) + 1
  statuses.value.push({
    id: 0,
    objectCode: objectCode.value,
    statusValue: nextValue,
    statusName: '新状态',
    sort: (statuses.value.length + 1) * 10,
    canEdit: true,
    canDelete: true,
    canSubmit: false,
    isFinal: false,
    colorType: 'info',
    enabled: true
  })
}

async function saveStatus(row: StatusRow) {
  try {
    await designApi.saveDocStatus(row)
    ElMessage.success('已保存')
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function removeStatus(row: StatusRow) {
  if (!row.id) {
    statuses.value = statuses.value.filter((s) => s !== row)
    return
  }
  try {
    await ElMessageBox.confirm(`删除状态「${row.statusName}」？`, '确认', { type: 'warning' })
    await designApi.deleteDocStatus(row.id)
    ElMessage.success('已删除')
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

function addTransition() {
  transitions.value.push({
    id: 0,
    objectCode: objectCode.value,
    fromStatus: 0,
    fromStatusName: '',
    toStatus: 1,
    toStatusName: '',
    actionCode: 'SUBMIT',
    actionName: '提交审批',
    sort: (transitions.value.length + 1) * 10,
    enabled: true
  })
}

async function saveTransition(row: TransitionRow) {
  try {
    await designApi.saveDocTransition(row)
    ElMessage.success('已保存')
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function removeTransition(row: TransitionRow) {
  if (!row.id) {
    transitions.value = transitions.value.filter((t) => t !== row)
    return
  }
  try {
    await ElMessageBox.confirm(`删除流转 ${row.actionCode}？`, '确认', { type: 'warning' })
    await designApi.deleteDocTransition(row.id)
    ElMessage.success('已删除')
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

async function initDefault() {
  try {
    await designApi.initDocStatus(objectCode.value)
    ElMessage.success('已初始化默认状态')
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

onMounted(load)
</script>

<style scoped>
.tip { margin-bottom: 12px; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.object-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.object-item:hover { background: var(--el-fill-color-light); }
.object-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.obj-top { display: flex; align-items: center; justify-content: space-between; gap: 6px; }
.obj-meta { font-size: 11px; color: var(--el-text-color-secondary); margin-top: 2px; }
.section-title { font-weight: 600; font-size: 13px; margin-bottom: 6px; }
.empty-tip { color: var(--el-text-color-secondary); padding: 40px 0; text-align: center; }
.mono { font-family: Consolas, monospace; }
</style>
