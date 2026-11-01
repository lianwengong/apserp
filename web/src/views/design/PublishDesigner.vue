<template>
  <div class="publish-designer">
    <el-row :gutter="12">
      <el-col :span="9">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>发布</span>
              <el-button size="small" type="primary" :loading="publishing" @click="publish">发布当前配置</el-button>
            </div>
          </template>
          <el-input v-model="remark" size="small" placeholder="本次发布说明（必填，便于回溯）" style="margin-bottom: 10px" />
          <el-alert type="warning" :closable="false" show-icon>
            发布会把当前租户的全部元数据（对象/字段/视图/表单/按钮/规则/审批/权限）打成一个快照。
            回滚会<b>整体替换</b>这些配置，业务单据数据不受影响。
          </el-alert>

          <el-divider content-position="left">版本历史</el-divider>
          <el-scrollbar height="420px">
            <div
              v-for="v in versions"
              :key="v.id"
              class="version-item"
              :class="{ active: selected === v.version }"
              @click="select(v.version)"
            >
              <div class="version-top">
                <span class="version-no">v{{ v.version }}</span>
                <el-tag v-if="v.rollbackOf" size="small" type="warning" effect="plain">
                  回滚自 v{{ v.rollbackOf }}
                </el-tag>
                <span class="version-time">{{ formatTime(v.publishedAt) }}</span>
              </div>
              <div class="version-remark">{{ v.remark || '（无说明）' }}</div>
              <div class="version-meta">
                {{ v.publishedByName || '未知' }} · {{ (v.sizeBytes / 1024).toFixed(1) }} KB · {{ v.contentHash.slice(0, 8) }}
              </div>
            </div>
            <el-empty v-if="!versions.length" description="还没有发布记录" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="15">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>版本对比 <b v-if="selected">v{{ selected }}</b></span>
              <div>
                <el-button size="small" :disabled="!selected" @click="loadDiff">对比当前</el-button>
                <el-button size="small" type="danger" plain :disabled="!selected" @click="rollback">回滚到此版本</el-button>
              </div>
            </div>
          </template>

          <el-table :data="diff.items" size="small" border max-height="480" empty-text="选择左侧版本后点「对比当前」">
            <el-table-column label="类型" width="150">
              <template #default="{ row }">
                <el-tag size="small" effect="plain">{{ kindName(row.kind) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="变化" width="90" align="center">
              <template #default="{ row }">
                <el-tag size="small" :type="actionTag(row.action)">{{ actionName(row.action) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="code" label="编码 / 键" />
          </el-table>
          <div class="summary" v-if="diff.items.length">
            共 {{ diff.items.length }} 处变化：新增
            {{ count('added') }} · 修改 {{ count('changed') }} · 删除 {{ count('removed') }}
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { designApi, type VersionDto, type DiffResult } from '../../api/design'

const versions = ref<VersionDto[]>([])
const selected = ref<number | null>(null)
const remark = ref('')
const publishing = ref(false)
const diff = reactive<DiffResult>({ fromVersion: null, toVersion: null, items: [] })

const KIND: Record<string, string> = {
  objects: '数据对象',
  fields: '字段',
  listViews: '列表视图',
  listViewColumns: '视图列',
  formLayouts: '表单',
  formFields: '表单字段',
  buttons: '按钮',
  buttonActions: '按钮动作',
  rules: '规则',
  ruleBindings: '规则绑定',
  workflows: '审批流',
  workflowNodes: '审批节点',
  workflowApprovers: '审批人',
  rolePermissions: '角色权限',
  fieldPermissions: '字段权限'
}
function kindName(k: string) {
  return KIND[k] ?? k
}
function actionName(a: string) {
  return a === 'added' ? '新增' : a === 'removed' ? '删除' : '修改'
}
function actionTag(a: string) {
  return a === 'added' ? 'success' : a === 'removed' ? 'danger' : 'warning'
}
function count(a: string) {
  return diff.items.filter((i) => i.action === a).length
}
function formatTime(t: string) {
  return t ? t.replace('T', ' ').slice(0, 19) : ''
}

async function load() {
  try {
    versions.value = await designApi.versions()
    if (!selected.value && versions.value.length) selected.value = versions.value[0].version
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function select(v: number) {
  selected.value = v
  diff.items = []
}

async function publish() {
  if (!remark.value.trim()) return ElMessage.warning('请填写发布说明')
  publishing.value = true
  try {
    const r = await designApi.publish(remark.value.trim())
    ElMessage.success(`已发布 v${r.version}（${(r.sizeBytes / 1024).toFixed(1)} KB）`)
    remark.value = ''
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    publishing.value = false
  }
}

async function loadDiff() {
  if (!selected.value) return
  try {
    const r = await designApi.diff(selected.value)
    diff.fromVersion = r.fromVersion
    diff.toVersion = r.toVersion
    diff.items = r.items
    if (!r.items.length) ElMessage.info('与当前配置没有差异')
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function rollback() {
  if (!selected.value) return
  try {
    await ElMessageBox.confirm(
      `回滚到 v${selected.value}？当前配置会被整体替换（业务数据不受影响），并生成一个新版本。`,
      '确认回滚',
      { type: 'warning' }
    )
    const r = await designApi.rollback(selected.value, `回滚到 v${selected.value}`)
    ElMessage.success(`已回滚，生成 v${r.version}`)
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

onMounted(load)
</script>

<style scoped>
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.version-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.version-item:hover { background: var(--el-fill-color-light); }
.version-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.version-top { display: flex; align-items: center; gap: 8px; }
.version-no { font-weight: 700; font-size: 13px; }
.version-time { margin-left: auto; font-size: 11px; color: var(--el-text-color-secondary); }
.version-remark { font-size: 12px; margin: 2px 0; }
.version-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.summary { font-size: 12px; color: var(--el-text-color-secondary); margin-top: 8px; }
</style>
