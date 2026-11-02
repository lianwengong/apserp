<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete, Edit, Plus, Refresh, Search, View } from '@element-plus/icons-vue'
import { pageSchemaApi } from '../../api/page-schema'
import type { PageSchemaDto } from '../../api/page-schema'
import { invalidatePage } from '../../schema/loader'
import { assertPageSchema, isPageSchema, type PageKind } from '../../schema/types'
import { formatDateTime } from '../../utils/format'

defineOptions({ name: 'PageSchemaAdminView' })

const rows = ref<PageSchemaDto[]>([])
const loading = ref(false)
const error = ref('')
const keyword = ref('')
const drawer = ref(false)
const saving = ref(false)
const editingId = ref<number | null>(null)

const form = reactive({
  code: '',
  title: '',
  kind: 'placeholder' as PageKind,
  enabled: true,
  remark: '',
  configJson: ''
})

const kindOptions = [
  { value: 'object', label: '数据对象页' },
  { value: 'tabs', label: '多页签页' },
  { value: 'dashboard', label: '看板页' },
  { value: 'placeholder', label: '占位页' }
]

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    rows.value = await pageSchemaApi.list(keyword.value.trim())
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '页面定义加载失败'
    rows.value = []
  } finally {
    loading.value = false
  }
}

function defaultJson(code = 'new.page', title = '新页面', kind: PageKind = 'placeholder'): string {
  if (kind === 'object') {
    return JSON.stringify(
      { code, title, kind, objectCode: 'md.brand', description: '对象列表页' },
      null,
      2
    )
  }
  if (kind === 'tabs') {
    return JSON.stringify(
      {
        code,
        title,
        kind,
        tabs: [
          { key: 'brand', label: '品牌', objectCode: 'md.brand' },
          { key: 'partner', label: '往来单位', objectCode: 'md.partner' }
        ]
      },
      null,
      2
    )
  }
  if (kind === 'dashboard') {
    return JSON.stringify(
      {
        code,
        title,
        kind,
        dashboard: {
          cards: [
            { key: 'brand', label: '品牌', objectCode: 'md.brand', icon: 'PriceTag', to: '/object/md.brand' }
          ],
          shortcuts: [{ label: '基础资料中心', to: '/page/master-data', icon: 'Files' }]
        }
      },
      null,
      2
    )
  }
  return JSON.stringify({ code, title, kind, description: '待接入页面' }, null, 2)
}

function openCreate(): void {
  editingId.value = null
  Object.assign(form, {
    code: 'new.page',
    title: '新页面',
    kind: 'placeholder',
    enabled: true,
    remark: '',
    configJson: defaultJson()
  })
  drawer.value = true
}

function openEdit(row: PageSchemaDto): void {
  editingId.value = row.id
  Object.assign(form, {
    code: row.code,
    title: row.title,
    kind: row.kind as PageKind,
    enabled: row.enabled,
    remark: row.remark ?? '',
    configJson: row.configJson
  })
  drawer.value = true
}

function onKindChange(): void {
  if (editingId.value === null && !form.configJson.trim()) {
    form.configJson = defaultJson(form.code, form.title, form.kind)
  }
}

/** 表单的 code/title/kind 是权威值；JSON 里不允许写另一套。 */
function normalizedConfig(): string {
  let parsed: unknown
  try {
    parsed = JSON.parse(form.configJson)
  } catch {
    throw new Error('页面配置不是合法 JSON')
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('页面配置必须是 JSON 对象')
  }
  const node = { ...(parsed as Record<string, unknown>) }
  node.code = form.code.trim()
  node.title = form.title.trim()
  node.kind = form.kind
  const text = JSON.stringify(node, null, 2)
  const check = JSON.parse(text) as unknown
  if (!isPageSchema(check)) throw new Error('页面配置缺少 code/title/kind')
  assertPageSchema(check)
  return text
}

function validate(): void {
  try {
    normalizedConfig()
    ElMessage.success('校验通过')
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '校验失败')
  }
}

function formatJson(): void {
  try {
    const parsed = JSON.parse(form.configJson) as unknown
    form.configJson = JSON.stringify(parsed, null, 2)
    ElMessage.success('已格式化')
  } catch {
    ElMessage.error('不是合法 JSON，无法格式化')
  }
}

function applyTemplate(): void {
  form.configJson = defaultJson(form.code, form.title, form.kind)
  ElMessage.info('已插入模板，请按需修改')
}

async function save(): Promise<void> {
  if (!form.code.trim() || !form.title.trim()) {
    ElMessage.warning('页面编码和标题不能为空')
    return
  }
  let configJson: string
  try {
    configJson = normalizedConfig()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '页面配置不合法')
    return
  }
  saving.value = true
  try {
    await pageSchemaApi.save({
      id: editingId.value,
      code: form.code.trim(),
      title: form.title.trim(),
      kind: form.kind,
      configJson,
      enabled: form.enabled,
      remark: form.remark.trim() || null
    })
    invalidatePage(form.code.trim())
    ElMessage.success(editingId.value ? '页面定义已更新' : '页面定义已创建')
    drawer.value = false
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '保存失败')
  } finally {
    saving.value = false
  }
}

async function remove(row: PageSchemaDto): Promise<void> {
  try {
    await ElMessageBox.confirm(`确认删除页面「${row.title}」？`, '删除页面定义', {
      type: 'warning'
    })
  } catch {
    return
  }
  try {
    await pageSchemaApi.remove(row.id)
    invalidatePage(row.code)
    ElMessage.success('已删除')
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '删除失败')
  }
}

function preview(row?: PageSchemaDto): void {
  const code = row?.code ?? form.code.trim()
  if (!code) return
  if (!row) {
    try {
      normalizedConfig()
    } catch (ex) {
      ElMessage.error(ex instanceof Error ? ex.message : '页面配置不合法')
      return
    }
    ElMessage.info('未保存的页面请先保存，预览打开的是已保存版本')
  }
  const href = `${window.location.origin}${window.location.pathname}#/page/${encodeURIComponent(code)}`
  window.open(href, '_blank', 'noopener')
}

function kindLabel(kind: string): string {
  return kindOptions.find((item) => item.value === kind)?.label ?? kind
}

onMounted(load)
</script>

<template>
  <div class="page-admin">
    <div class="head">
      <div>
        <p class="eyebrow">PAGE SCHEMA</p>
        <h2>页面编排</h2>
        <p class="sub">
          页面组合存后端、立即生效；前端保留同构本地定义作为回退。字段、视图、表单仍由数据对象元数据控制。
        </p>
      </div>
      <div class="head-actions">
        <el-input
          v-model="keyword"
          clearable
          placeholder="搜索编码 / 标题 / 类型"
          class="search"
          @keyup.enter="load"
          @clear="load"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-button :loading="loading" @click="load"><el-icon><Refresh /></el-icon>刷新</el-button>
        <el-button type="primary" @click="openCreate"><el-icon><Plus /></el-icon>新建页面</el-button>
      </div>
    </div>

    <el-alert v-if="error" :title="error" type="error" show-icon :closable="false" class="alert" />

    <div class="card table-card">
      <el-table v-loading="loading" :data="rows" row-key="id" border stripe>
        <el-table-column prop="code" label="页面编码" min-width="180">
          <template #default="{ row }"><span class="mono">{{ row.code }}</span></template>
        </el-table-column>
        <el-table-column prop="title" label="标题" min-width="180" />
        <el-table-column prop="kind" label="类型" width="130">
          <template #default="{ row }"><el-tag size="small" effect="plain">{{ kindLabel(row.kind) }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="version" label="版本" width="80" align="center" />
        <el-table-column prop="enabled" label="启用" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'info'" size="small">{{ row.enabled ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="modifiedAt" label="更新时间" width="170">
          <template #default="{ row }">{{ row.modifiedAt ? formatDateTime(row.modifiedAt) : '—' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="230" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="openEdit(row)">
              <el-icon><Edit /></el-icon>编辑
            </el-button>
            <el-button link size="small" @click="preview(row)">
              <el-icon><View /></el-icon>预览
            </el-button>
            <el-button link type="danger" size="small" @click="remove(row)">
              <el-icon><Delete /></el-icon>删除
            </el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="还没有页面定义；新建一个或保存后由后端下发" :image-size="72" />
        </template>
      </el-table>
    </div>

    <el-drawer v-model="drawer" :title="editingId ? '编辑页面定义' : '新建页面定义'" size="760px" destroy-on-close>
      <div class="editor">
        <div class="grid">
          <el-form-item label="页面编码">
            <el-input v-model="form.code" :disabled="editingId !== null" placeholder="如 master-data" />
          </el-form-item>
          <el-form-item label="页面标题">
            <el-input v-model="form.title" placeholder="如 基础资料中心" />
          </el-form-item>
          <el-form-item label="页面类型">
            <el-select v-model="form.kind" style="width: 100%" @change="onKindChange">
              <el-option v-for="item in kindOptions" :key="item.value" :label="item.label" :value="item.value" />
            </el-select>
          </el-form-item>
          <el-form-item label="启用">
            <el-switch v-model="form.enabled" />
          </el-form-item>
        </div>

        <el-form-item label="备注">
          <el-input v-model="form.remark" placeholder="变更原因 / 灰度说明" />
        </el-form-item>

        <div class="json-head">
          <span>PageSchema JSON</span>
          <div class="json-actions">
            <el-button link type="primary" size="small" @click="applyTemplate">插入模板</el-button>
            <el-button link size="small" @click="formatJson">格式化</el-button>
            <el-button link size="small" @click="validate">校验</el-button>
          </div>
        </div>
        <el-input
          v-model="form.configJson"
          type="textarea"
          :rows="22"
          resize="vertical"
          class="json-editor"
          spellcheck="false"
        />
        <p class="hint">
          保存时以表单的 code/title/kind 为准覆盖 JSON 中的对应字段；object 必须有 objectCode，tabs 至少一个页签，
          dashboard 必须有 cards。
        </p>
      </div>

      <template #footer>
        <div class="drawer-footer">
          <el-button @click="drawer = false">取消</el-button>
          <el-button @click="preview()">预览已保存版本</el-button>
          <el-button type="primary" :loading="saving" @click="save">保存并生效</el-button>
        </div>
      </template>
    </el-drawer>
  </div>
</template>

<style scoped>
.page-admin {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 16px;
  min-height: 100%;
  background: var(--bg);
}
.head { display: flex; align-items: flex-end; justify-content: space-between; gap: 20px; }
.head h2 { margin: 4px 0 6px; font-size: 22px; }
.sub { margin: 0; color: var(--ink-2); font-size: 12.5px; line-height: 1.7; max-width: 760px; }
.head-actions { display: flex; align-items: center; gap: 8px; flex: 0 0 auto; }
.search { width: 240px; }
.alert { margin: 0; }
.table-card { padding: 0; overflow: hidden; }
.editor { display: flex; flex-direction: column; gap: 14px; }
.grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 0 16px; }
.json-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px; font-size: 12px; font-weight: 600; }
.json-actions { display: flex; gap: 4px; }
.json-editor :deep(textarea) {
  font-family: "Cascadia Code", Consolas, monospace;
  font-size: 12px;
  line-height: 1.6;
}
.hint { margin: 0; color: var(--muted); font-size: 11.5px; line-height: 1.7; }
.drawer-footer { display: flex; justify-content: flex-end; gap: 8px; }
@media (max-width: 900px) {
  .head { flex-direction: column; align-items: flex-start; }
  .head-actions { width: 100%; flex-wrap: wrap; }
  .search { width: 100%; }
  .grid { grid-template-columns: 1fr; }
}
</style>
