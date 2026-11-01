<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Close, Download, Filter, Plus, Refresh, Search, Setting } from '@element-plus/icons-vue'
import { ApiError } from '../api/http'
import { fieldAccess } from '../api/perm'
import { getObject, listFields, listFormLayouts, listRows, listViews } from '../api/meta'
import type {
  ColumnDto,
  DataObjectDto,
  FieldAccess,
  FieldDto,
  FilterCondition,
  FilterOp,
  FormLayoutDto,
  ListViewDto,
  Row
} from '../api/types'
import { catalog } from '../stores/catalog'
import { session } from '../stores/session'
import { decimalScale, formatCell, formatNumber, isBitField, isDateField } from '../utils/format'
import { groupOf } from '../utils/schema'
import CellValue from '../components/CellValue.vue'
import MetaFormDialog from '../components/MetaFormDialog.vue'
import ActionBar from '../components/ActionBar.vue'
import ApprovalPanel from '../components/ApprovalPanel.vue'

type ViewState = 'loading' | 'ready' | 'denied' | 'missing' | 'error'

/** 没有列表视图时，系统列不进默认列（Id 除外，行标识仍会随数据返回）。 */
const SYSTEM_COLUMNS = /^(isdeleted|createdby|createdat|modifiedby|modifiedat|deletedby|deletedat|rowversion)$/i

const OPERATORS: { value: FilterOp; label: string }[] = [
  { value: 'like', label: '包含' },
  { value: 'eq', label: '等于' },
  { value: 'neq', label: '不等于' },
  { value: 'gt', label: '大于' },
  { value: 'gte', label: '大于等于' },
  { value: 'lt', label: '小于' },
  { value: 'lte', label: '小于等于' }
]

const route = useRoute()
const router = useRouter()

const code = computed(() => (typeof route.params.code === 'string' ? route.params.code : ''))
/** 数据对象编码：模板里多处引用（元数据接口、按钮与审批组件的入参）。 */
const objectCode = computed(() => code.value)

const viewState = ref<ViewState>('loading')
const errorText = ref('')
const object = ref<DataObjectDto | null>(null)
const fields = ref<FieldDto[]>([])
const views = ref<ListViewDto[]>([])
const forms = ref<FormLayoutDto[]>([])
const access = ref<FieldAccess>({})

const rows = ref<Row[]>([])
const total = ref(0)
const page = ref(1)
const size = ref(50)
const sort = ref('')
/** 默认排序来自视图，不算“用户条件”；只有手动点表头才显示排序标签 */
const sortTouched = ref(false)
const conditions = ref<FilterCondition[]>([])
const keyword = ref('')
const loading = ref(false)
const exporting = ref(false)
const filterOpen = ref(false)
const draft = ref<FilterCondition[]>([])
const activeViewCode = ref('')
const visibleMap = reactive<Record<string, boolean>>({})
const tableKey = ref(0)
const dialogVisible = ref(false)
const editingRow = ref<Row | null>(null)

let keywordCondition: FilterCondition | null = null
let requestId = 0

// ---------------------------------------------------------------- 派生数据

const activeView = computed<ListViewDto | null>(() => {
  return (
    views.value.find((view) => view.code === activeViewCode.value) ??
    views.value.find((view) => view.isDefault) ??
    views.value[0] ??
    null
  )
})

/** 列定义：默认视图优先；没有视图时回退到数据对象字段。 */
const columns = computed<ColumnDto[]>(() => {
  const view = activeView.value
  if (view && view.columns.length) return view.columns.filter((column) => column.visible)
  return fields.value
    .filter((field) => !field.primaryKey && !SYSTEM_COLUMNS.test(field.fieldName))
    .map<ColumnDto>((field) => ({
      fieldName: field.fieldName,
      title: field.displayName,
      width: null,
      align: null,
      sum: false,
      visible: true,
      sort: field.sort
    }))
})

const displayColumns = computed(() =>
  columns.value.filter((column) => visibleMap[column.fieldName] !== false)
)

const defaultSort = computed<{ prop: string; order: 'ascending' } | undefined>(() => {
  if (!sort.value || sort.value.includes(',')) return undefined
  return { prop: sort.value, order: 'ascending' }
})

const hasSumColumn = computed(() => displayColumns.value.some((column) => column.sum))

const sortLabel = computed(() =>
  sort.value
    .split(',')
    .map((name) => fieldOfName(name.trim())?.displayName ?? name.trim())
    .join(' + ')
)

const searchField = computed<FieldDto | undefined>(() => {
  const candidates = fields.value.filter(
    (field) => !field.primaryKey && /^(n?varchar|char)/i.test(field.dataType)
  )
  return (
    candidates.find((field) => /^name$/i.test(field.fieldName)) ??
    candidates.find((field) => field.displayName.includes('名称')) ??
    candidates[0]
  )
})

const canWrite = computed(() => {
  const current = object.value
  if (!current || current.readOnly) return false
  return session.has(`DATA:${current.code}`)
})

const stateDescription = computed(() => {
  if (viewState.value === 'denied') {
    return `当前账号没有「${object.value?.name ?? code.value}」的访问权限`
  }
  if (viewState.value === 'missing') {
    return `数据对象 ${code.value} 不存在或未启用`
  }
  return errorText.value || '加载失败'
})

// ---------------------------------------------------------------- 加载

function fieldOfName(name: string): FieldDto | undefined {
  return fields.value.find((field) => field.fieldName === name)
}

function columnTitle(column: ColumnDto): string {
  return column.title ?? fieldOfName(column.fieldName)?.displayName ?? column.fieldName
}

function alignOf(column: ColumnDto): 'left' | 'right' | 'center' {
  if (column.align === '2') return 'right'
  if (column.align === '3') return 'center'
  return 'left'
}

function rowKey(row: Row): string {
  const key = object.value?.primaryKey ?? 'Id'
  return String(row[key] ?? '')
}

function resetVisibility(): void {
  for (const key of Object.keys(visibleMap)) delete visibleMap[key]
  for (const column of columns.value) visibleMap[column.fieldName] = true
}

async function bootstrap(): Promise<void> {
  const objectCode = code.value
  if (!objectCode) return
  const currentRequest = ++requestId
  viewState.value = 'loading'
  errorText.value = ''
  object.value = null
  rows.value = []
  total.value = 0
  conditions.value = []
  keyword.value = ''
  keywordCondition = null
  filterOpen.value = false
  dialogVisible.value = false

  try {
    const [objectDto, fieldList, viewList, formList] = await Promise.all([
      getObject(objectCode),
      listFields(objectCode),
      listViews(objectCode),
      listFormLayouts(objectCode)
    ])
    if (currentRequest !== requestId) return

    object.value = objectDto
    fields.value = fieldList
    views.value = viewList
    forms.value = formList

    // 字段级权限不影响列表主流程：拿不到就按“全部可写”降级，服务端仍会兜底
    access.value = await fieldAccess(objectCode).catch(() => ({}) as FieldAccess)
    if (currentRequest !== requestId) return

    const view = viewList.find((item) => item.isDefault) ?? viewList[0]
    activeViewCode.value = view?.code ?? ''
    size.value = view && view.pageSize > 0 ? view.pageSize : 50
    sort.value = view?.defaultSort ?? ''
    sortTouched.value = false
    page.value = 1
    resetVisibility()
    viewState.value = 'ready'
    await load()
  } catch (ex) {
    if (currentRequest !== requestId) return
    if (ex instanceof ApiError && ex.status === 403) viewState.value = 'denied'
    else if (ex instanceof ApiError && ex.status === 404) viewState.value = 'missing'
    else {
      viewState.value = 'error'
      errorText.value = ex instanceof Error ? ex.message : '加载失败'
    }
  }
}

async function load(): Promise<void> {
  const current = object.value
  if (!current) return
  const currentRequest = ++requestId
  loading.value = true
  try {
    const result = await listRows(current.code, {
      page: page.value,
      size: size.value,
      sort: sort.value,
      filters: conditions.value.length ? JSON.stringify(conditions.value) : ''
    })
    if (currentRequest !== requestId) return
    rows.value = result.rows
    total.value = result.total
  } catch (ex) {
    if (currentRequest !== requestId) return
    if (ex instanceof ApiError && ex.status === 403) {
      viewState.value = 'denied'
      return
    }
    ElMessage.error(ex instanceof Error ? ex.message : '查询失败')
  } finally {
    if (currentRequest === requestId) loading.value = false
  }
}

watch(
  code,
  () => {
    void bootstrap()
  },
  { immediate: true }
)

onBeforeUnmount(() => {
  requestId += 1
})

// ---------------------------------------------------------------- 查询交互

function applyKeyword(): void {
  const text = keyword.value.trim()
  if (!text) return
  const field = searchField.value
  if (!field) {
    ElMessage.info('该数据对象没有可模糊搜索的文本字段，请使用“筛选”')
    return
  }
  removeKeywordCondition(false)
  const condition: FilterCondition = { f: field.fieldName, op: 'like', v: text }
  keywordCondition = condition
  conditions.value = [...conditions.value, condition]
  page.value = 1
  void load()
}

function clearKeyword(): void {
  removeKeywordCondition(false)
  page.value = 1
  void load()
}

function removeKeywordCondition(reload: boolean): void {
  if (!keywordCondition) return
  const target = keywordCondition
  conditions.value = conditions.value.filter((item) => item !== target)
  keywordCondition = null
  keyword.value = ''
  if (reload) {
    page.value = 1
    void load()
  }
}

function conditionLabel(condition: FilterCondition): string {
  const field = fieldOfName(condition.f)
  const operator = OPERATORS.find((item) => item.value === condition.op)?.label ?? condition.op
  return `${field?.displayName ?? condition.f} ${operator} ${condition.v}`
}

function removeCondition(condition: FilterCondition): void {
  conditions.value = conditions.value.filter((item) => item !== condition)
  if (keywordCondition === condition) {
    keywordCondition = null
    keyword.value = ''
  }
  page.value = 1
  void load()
}

function clearAllConditions(): void {
  conditions.value = []
  keyword.value = ''
  keywordCondition = null
  page.value = 1
  void load()
}

function toggleFilter(): void {
  filterOpen.value = !filterOpen.value
  if (filterOpen.value) draft.value = conditions.value.map((item) => ({ ...item }))
}

function addCondition(): void {
  const field = fields.value.find((item) => !item.primaryKey)
  if (!field) return
  draft.value.push({ f: field.fieldName, op: 'like', v: '' })
}

function resetDraft(): void {
  draft.value = []
}

function applyDraft(): void {
  conditions.value = draft.value
    .map((item) => ({ ...item, v: item.v.trim() }))
    .filter((item) => item.v !== '')
  keyword.value = ''
  keywordCondition = null
  page.value = 1
  filterOpen.value = false
  void load()
}

function onSortChange({ prop, order }: { prop: string; order: 'ascending' | 'descending' | null }): void {
  if (order === 'descending') {
    // 引擎的排序只接受升序字段列表（DESC 会被忽略），这里直接取消排序并重绘表头
    sort.value = ''
    sortTouched.value = false
    tableKey.value += 1
    ElMessage.info('当前查询引擎只支持升序排序')
  } else {
    sort.value = order ? prop : ''
    sortTouched.value = order !== null
  }
  page.value = 1
  void load()
}

function clearSort(): void {
  sort.value = ''
  sortTouched.value = false
  tableKey.value += 1
  page.value = 1
  void load()
}

function onPageChange(next: number): void {
  page.value = next
  void load()
}

function onSizeChange(next: number): void {
  size.value = next
  page.value = 1
  void load()
}

function switchView(viewCode: string): void {
  const view = views.value.find((item) => item.code === viewCode)
  activeViewCode.value = viewCode
  size.value = view && view.pageSize > 0 ? view.pageSize : size.value
  sort.value = view?.defaultSort ?? ''
  sortTouched.value = false
  page.value = 1
  resetVisibility()
  void load()
}

function reload(): void {
  void load()
}

// ---------------------------------------------------------------- 表格 / 导出

function summaryMethod(param: { columns: { property?: string }[] }): string[] {
  const sums: string[] = []
  param.columns.forEach((column, index) => {
    if (index === 0) {
      sums[index] = '本页合计'
      return
    }
    const columnMeta = displayColumns.value.find((item) => item.fieldName === column.property)
    if (!columnMeta?.sum) {
      sums[index] = ''
      return
    }
    const field = fieldOfName(columnMeta.fieldName)
    const sum = rows.value.reduce((acc, row) => acc + Number(row[columnMeta.fieldName] ?? 0), 0)
    sums[index] = formatNumber(sum, decimalScale(field))
  })
  return sums
}

function csvValue(value: string): string {
  return /[",\n\r]/.test(value) ? `"${value.replace(/"/g, '""')}"` : value
}

function downloadCsv(filename: string, content: string): void {
  const blob = new Blob([`\uFEFF${content}`], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}

async function exportCsv(): Promise<void> {
  const current = object.value
  if (!current) return
  exporting.value = true
  try {
    const result = await listRows(current.code, {
      page: 1,
      size: 500,
      sort: sort.value,
      filters: conditions.value.length ? JSON.stringify(conditions.value) : ''
    })
    const header = displayColumns.value.map((column) => csvValue(columnTitle(column))).join(',')
    const lines = result.rows.map((row) =>
      displayColumns.value
        .map((column) => csvValue(formatCell(row[column.fieldName], fieldOfName(column.fieldName))))
        .join(',')
    )
    const stamp = new Date().toISOString().slice(0, 10)
    downloadCsv(`${current.name}_${stamp}.csv`, [header, ...lines].join('\r\n'))
    ElMessage.success(
      result.total > result.rows.length
        ? `已导出前 ${result.rows.length} 行（共 ${result.total} 行，上限 500）`
        : `已导出 ${result.rows.length} 行`
    )
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '导出失败')
  } finally {
    exporting.value = false
  }
}

// ---------------------------------------------------------------- 表单弹窗

function openCreate(): void {
  editingRow.value = null
  dialogVisible.value = true
}

function openEdit(row: Row): void {
  if (!canWrite.value) return
  editingRow.value = row
  dialogVisible.value = true
}

/** 审批抽屉：行内“审批”按钮打开，展示该单据的全部流程实例与时间轴。 */
const approvalVisible = ref(false)
const approvalBusinessId = ref<number | null>(null)

function openApproval(row: Row): void {
  const id = Number(row['Id']) || 0
  if (!id) {
    ElMessage.warning('缺少主键，无法查看审批')
    return
  }
  approvalBusinessId.value = id
  approvalVisible.value = true
}

function onSubmitted(instanceId: number): void {
  void instanceId
  approvalVisible.value = false
  void load()
}

function onSaved(): void {
  dialogVisible.value = false
  void load()
  void catalog.load(true)
}

function backHome(): void {
  void router.push('/')
}

function retry(): void {
  void bootstrap()
}
</script>

<template>
  <div class="list-page">
    <!-- 加载 / 异常状态 -->
    <div v-if="viewState === 'loading'" class="card state-card">
      <div class="skeleton-head">
        <el-skeleton animated>
          <template #template>
            <el-skeleton-item variant="h3" style="width: 180px" />
            <el-skeleton-item variant="text" style="width: 60%; margin-top: 14px" />
            <el-skeleton-item variant="text" style="width: 80%; margin-top: 8px" />
          </template>
        </el-skeleton>
        <el-skeleton :rows="8" animated style="margin-top: 20px" />
      </div>
    </div>

    <div v-else-if="viewState !== 'ready'" class="card state-card">
      <el-empty :description="stateDescription" :image-size="96">
        <el-button v-if="viewState === 'error'" type="primary" @click="retry">重新加载</el-button>
        <el-button v-else type="primary" plain @click="backHome">返回工作台</el-button>
      </el-empty>
    </div>

    <!-- 列表主体 -->
    <div v-else class="card list-card">
      <div class="list-head">
        <div class="title-row">
          <div class="titles">
            <div class="eyebrow">
              {{ object ? groupOf(object.code).label : '数据对象' }}
            </div>
            <h2>
              {{ object?.name }}
              <span class="object-code mono">{{ object?.code }}</span>
              <el-tag v-if="object?.readOnly" size="small" type="info" effect="plain">只读</el-tag>
            </h2>
          </div>

          <div class="actions">
            <el-select
              v-if="views.length > 1"
              :model-value="activeViewCode"
              class="view-select"
              size="default"
              @change="switchView"
            >
              <el-option
                v-for="view in views"
                :key="view.code"
                :label="view.name"
                :value="view.code"
              />
            </el-select>

            <el-input
              v-model="keyword"
              class="keyword"
              :placeholder="searchField ? `按${searchField.displayName}搜索` : '搜索'"
              :prefix-icon="Search"
              clearable
              @keyup.enter="applyKeyword"
              @clear="clearKeyword"
            />

            <el-button plain @click="toggleFilter">
              <el-icon><Filter /></el-icon>
              筛选
              <span v-if="conditions.length" class="filter-count">{{ conditions.length }}</span>
            </el-button>

            <el-popover placement="bottom-end" :width="240" trigger="click">
              <template #reference>
                <el-button circle title="列设置">
                  <el-icon><Setting /></el-icon>
                </el-button>
              </template>
              <div class="col-settings">
                <div class="col-settings-head">
                  <span>显示列</span>
                  <el-button link type="primary" size="small" @click="resetVisibility">全部显示</el-button>
                </div>
                <el-checkbox
                  v-for="column in columns"
                  :key="column.fieldName"
                  v-model="visibleMap[column.fieldName]"
                  class="col-check"
                >
                  {{ columnTitle(column) }}
                </el-checkbox>
              </div>
            </el-popover>

            <el-button :loading="loading" @click="reload">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>

            <el-button :loading="exporting" @click="exportCsv">
              <el-icon><Download /></el-icon>
              导出
            </el-button>

            <el-button type="primary" :disabled="!canWrite" @click="openCreate">
              <el-icon><Plus /></el-icon>
              新建
            </el-button>
          </div>
        </div>

        <div v-if="conditions.length || (sort && sortTouched)" class="chips">
          <span class="chips-label">已启用</span>
          <el-tag v-if="sort && sortTouched" closable type="info" effect="plain" @close="clearSort">
            排序：{{ sortLabel }} ↑
          </el-tag>
          <el-tag
            v-for="condition in conditions"
            :key="`${condition.f}-${condition.op}-${condition.v}`"
            closable
            type="info"
            effect="plain"
            @close="removeCondition(condition)"
          >
            {{ conditionLabel(condition) }}
          </el-tag>
          <el-button link type="primary" size="small" @click="clearAllConditions">清空全部</el-button>
        </div>

        <div v-if="filterOpen" class="filter-panel">
          <div v-for="(condition, index) in draft" :key="index" class="filter-row">
            <el-select v-model="condition.f" filterable class="filter-field">
              <el-option
                v-for="field in fields"
                :key="field.fieldName"
                :label="field.displayName"
                :value="field.fieldName"
              />
            </el-select>
            <el-select v-model="condition.op" class="filter-op">
              <el-option
                v-for="operator in OPERATORS"
                :key="operator.value"
                :label="operator.label"
                :value="operator.value"
              />
            </el-select>
            <el-select
              v-if="isBitField(fieldOfName(condition.f))"
              v-model="condition.v"
              class="filter-value"
              placeholder="选择"
            >
              <el-option label="是" value="1" />
              <el-option label="否" value="0" />
            </el-select>
            <el-date-picker
              v-else-if="isDateField(fieldOfName(condition.f))"
              v-model="condition.v"
              type="date"
              value-format="YYYY-MM-DD"
              class="filter-value"
              placeholder="选择日期"
            />
            <el-input v-else v-model="condition.v" class="filter-value" placeholder="值" clearable />
            <el-button text class="filter-remove" @click="draft.splice(index, 1)">
              <el-icon><Close /></el-icon>
            </el-button>
          </div>

          <div v-if="!draft.length" class="filter-empty muted">还没有条件，点“添加条件”开始。</div>

          <div class="filter-actions">
            <el-button text type="primary" @click="addCondition">
              <el-icon><Plus /></el-icon>
              添加条件
            </el-button>
            <span class="muted filter-tip">条件之间为 AND；字符串“包含”为前后模糊匹配</span>
            <div class="spacer" />
            <el-button @click="resetDraft">清空</el-button>
            <el-button type="primary" @click="applyDraft">查询</el-button>
          </div>
        </div>
      </div>

      <div class="table-wrap">
        <el-table
          :key="tableKey"
          v-loading="loading"
          :data="rows"
          :row-key="rowKey"
          :default-sort="defaultSort"
          :show-summary="hasSumColumn"
          :summary-method="summaryMethod"
          height="100%"
          border
          @row-dblclick="openEdit"
          @sort-change="onSortChange"
        >
          <el-table-column
            v-for="column in displayColumns"
            :key="column.fieldName"
            :prop="column.fieldName"
            :label="columnTitle(column)"
            :width="column.width ?? undefined"
            :min-width="column.width ? undefined : 140"
            :align="alignOf(column)"
            sortable="custom"
            show-overflow-tooltip
          >
            <template #default="{ row }">
              <CellValue :value="row[column.fieldName]" :field="fieldOfName(column.fieldName)" />
            </template>
          </el-table-column>

          <el-table-column label="操作" width="220" fixed="right" align="center">
            <template #default="{ row }">
              <ActionBar
                :object-code="objectCode"
                :row="row"
                @open-form="openEdit"
                @refresh="reload"
                @submitted="onSubmitted"
              />
              <el-button link size="small" @click="openApproval(row)">审批</el-button>
            </template>
          </el-table-column>

          <template #empty>
            <el-empty description="暂无数据" :image-size="72">
              <el-button v-if="canWrite" type="primary" @click="openCreate">新建一条</el-button>
            </el-empty>
          </template>
        </el-table>
      </div>

      <div class="list-foot">
        <div class="foot-meta muted">
          共 {{ total }} 条 · 第 {{ page }} / {{ Math.max(1, Math.ceil(total / size)) }} 页
          <span v-if="activeView"> · 视图：{{ activeView.name }}</span>
        </div>
        <el-pagination
          :current-page="page"
          :page-size="size"
          :page-sizes="[20, 50, 100, 200]"
          :total="total"
          layout="sizes, prev, pager, next, jumper"
          background
          size="small"
          @current-change="onPageChange"
          @size-change="onSizeChange"
        />
      </div>
    </div>

    <MetaFormDialog
      v-model="dialogVisible"
      :object="object"
      :fields="fields"
      :forms="forms"
      :access="access"
      :row="editingRow"
      @saved="onSaved"
    />

    <ApprovalPanel
      v-model="approvalVisible"
      :object-code="objectCode"
      :business-id="approvalBusinessId"
      @changed="reload"
    />
  </div>
</template>

<style scoped>
.list-page {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 0;
}

.state-card {
  flex: 1;
  display: grid;
  place-items: center;
  padding: 40px;
}

.skeleton-head {
  width: min(900px, 100%);
}

.list-card {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

.list-head {
  flex: 0 0 auto;
  padding: 14px 16px 10px;
  border-bottom: 1px solid var(--line);
}

.title-row {
  display: flex;
  align-items: flex-end;
  gap: 16px;
  flex-wrap: wrap;
}

.titles h2 {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 3px;
  font-size: 19px;
  letter-spacing: -0.01em;
}

.object-code {
  font-size: 11px;
  font-weight: 400;
  color: var(--muted);
  padding: 2px 6px;
  border: 1px solid var(--line);
  border-radius: 4px;
  background: #f7f9fb;
}

.actions {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: auto;
}

.view-select {
  width: 132px;
}

.keyword {
  width: 200px;
}

.filter-count {
  display: inline-grid;
  place-items: center;
  min-width: 16px;
  height: 16px;
  margin-left: 4px;
  padding: 0 4px;
  border-radius: 8px;
  background: var(--brand);
  color: #fff;
  font-size: 10px;
}

.chips {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 10px;
}

.chips-label {
  font-size: 11px;
  color: var(--muted);
}

.filter-panel {
  margin-top: 12px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #fafcfe;
}

.filter-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.filter-field {
  width: 150px;
}

.filter-op {
  width: 110px;
}

.filter-value {
  width: 200px;
}

.filter-remove {
  color: var(--muted);
}

.filter-empty {
  padding: 6px 2px 10px;
  font-size: 12px;
}

.filter-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  padding-top: 4px;
}

.filter-tip {
  font-size: 11px;
}

.spacer {
  flex: 1;
}

.table-wrap {
  flex: 1;
  min-height: 0;
  padding: 0 0 0;
}

.list-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 16px;
  border-top: 1px solid var(--line);
  background: #fbfcfe;
  flex: 0 0 auto;
}

.foot-meta {
  font-size: 11.5px;
}

.col-settings {
  display: flex;
  flex-direction: column;
  gap: 2px;
  max-height: 320px;
  overflow: auto;
}

.col-settings-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
  font-weight: 600;
  font-size: 12px;
}

.col-check {
  height: 26px;
  margin-right: 0;
}
</style>
