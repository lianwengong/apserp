<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { getObject, listFields, listRows, listViews } from '../api/meta'
import type { ColumnDto, DataObjectDto, FieldDto, ListViewDto, Row } from '../api/types'
import { formatNumber } from '../utils/format'
import CellValue from './CellValue.vue'

/**
 * 通用参照选择器。
 *
 * 与表单里的“200 条下拉”不同，这里走列表引擎：关键字过滤、分页、默认视图列、
 * 字段级展示都和后端一致；选中行后把整行交给调用方做 mapTo 回填。
 */
defineOptions({ name: 'RecordPicker' })

const props = withDefaults(
  defineProps<{
    modelValue: boolean
    objectCode: string
    title?: string
    size?: number
  }>(),
  { title: '', size: 10 }
)

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  select: [row: Row]
}>()

const visible = computed({
  get: () => props.modelValue,
  set: (value: boolean) => emit('update:modelValue', value)
})

const loading = ref(false)
const error = ref('')
const object = ref<DataObjectDto | null>(null)
const fields = ref<FieldDto[]>([])
const view = ref<ListViewDto | null>(null)
const rows = ref<Row[]>([])
const total = ref(0)
const page = ref(1)
const keyword = ref('')
const selected = ref<Row | null>(null)

const columns = computed<ColumnDto[]>(() => {
  if (view.value?.columns.length) return view.value.columns.filter((column) => column.visible).slice(0, 8)
  return fields.value
    .filter((field) => !field.primaryKey && !/^(isdeleted|created|modified|deleted|rowversion)/i.test(field.fieldName))
    .slice(0, 8)
    .map((field) => ({
      fieldName: field.fieldName,
      title: field.displayName,
      width: null,
      align: null,
      sum: false,
      visible: true,
      sort: field.sort
    }))
})

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

function fieldOf(name: string): FieldDto | undefined {
  return fields.value.find((field) => field.fieldName === name)
}

function titleOf(column: ColumnDto): string {
  return column.title ?? fieldOf(column.fieldName)?.displayName ?? column.fieldName
}

function alignOf(column: ColumnDto): 'left' | 'right' | 'center' {
  if (column.align === '2') return 'right'
  if (column.align === '3') return 'center'
  return 'left'
}

async function load(): Promise<void> {
  if (!props.objectCode) return
  loading.value = true
  error.value = ''
  try {
    const [objectDto, fieldList, viewList] = await Promise.all([
      getObject(props.objectCode),
      listFields(props.objectCode),
      listViews(props.objectCode)
    ])
    object.value = objectDto
    fields.value = fieldList
    view.value = viewList.find((item) => item.isDefault) ?? viewList[0] ?? null
    await query(1)
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '参照数据加载失败'
    rows.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

async function query(next: number): Promise<void> {
  if (!props.objectCode) return
  page.value = next
  loading.value = true
  error.value = ''
  try {
    const conditions =
      keyword.value.trim() && searchField.value
        ? [{ f: searchField.value.fieldName, op: 'like' as const, v: keyword.value.trim() }]
        : []
    const result = await listRows(props.objectCode, {
      page: page.value,
      size: props.size,
      sort: view.value?.defaultSort ?? object.value?.defaultOrder ?? '',
      filters: conditions.length ? JSON.stringify(conditions) : ''
    })
    rows.value = result.rows
    total.value = result.total
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '查询失败'
    rows.value = []
  } finally {
    loading.value = false
  }
}

function search(): void {
  selected.value = null
  void query(1)
}

function confirm(): void {
  if (!selected.value) return
  emit('select', selected.value)
  visible.value = false
}

watch(
  () => props.modelValue,
  (open) => {
    if (!open) return
    keyword.value = ''
    selected.value = null
    page.value = 1
    void load()
  }
)
</script>

<template>
  <el-dialog
    v-model="visible"
    :title="title || `选择${object?.name ?? '记录'}`"
    width="920px"
    append-to-body
    destroy-on-close
    class="record-picker"
  >
    <div class="picker-search">
      <el-input
        v-model="keyword"
        clearable
        :placeholder="searchField ? `按${searchField.displayName}搜索` : '该对象没有可搜索的文本字段'"
        :disabled="!searchField"
        @keyup.enter="search"
      >
        <template #prefix><el-icon><Search /></el-icon></template>
      </el-input>
      <el-button type="primary" @click="search">查询</el-button>
    </div>

    <el-alert v-if="error" :title="error" type="error" :closable="false" show-icon class="picker-alert" />

    <el-table
      v-loading="loading"
      :data="rows"
      height="380"
      border
      stripe
      highlight-current-row
      :row-key="object?.primaryKey ?? 'Id'"
      @row-click="(row: Row) => (selected = row)"
      @row-dblclick="(row: Row) => { selected = row; confirm() }"
    >
      <el-table-column
        v-for="column in columns"
        :key="column.fieldName"
        :prop="column.fieldName"
        :label="titleOf(column)"
        :width="column.width ?? undefined"
        :min-width="column.width ? undefined : 120"
        :align="alignOf(column)"
        show-overflow-tooltip
      >
        <template #default="{ row }">
          <CellValue :value="row[column.fieldName]" :field="fieldOf(column.fieldName)" />
        </template>
      </el-table-column>
      <template #empty>
        <el-empty :description="error ? '加载失败' : '没有匹配的数据'" :image-size="64" />
      </template>
    </el-table>

    <div class="picker-footer">
      <span class="muted">共 {{ formatNumber(total, 0) }} 条 · 双击行可直接选择</span>
      <el-pagination
        small
        layout="prev, pager, next"
        :current-page="page"
        :page-size="size"
        :total="total"
        :pager-count="5"
        @current-change="query"
      />
    </div>

    <template #footer>
      <div class="picker-actions">
        <span class="selected-hint">
          {{ selected ? `已选：${selected['Name'] ?? selected['Code'] ?? selected['Id']}` : '请选择一行' }}
        </span>
        <el-button @click="visible = false">取消</el-button>
        <el-button type="primary" :disabled="!selected" @click="confirm">确定</el-button>
      </div>
    </template>
  </el-dialog>
</template>

<style scoped>
.picker-search { display: flex; gap: 8px; margin-bottom: 12px; }
.picker-search .el-input { max-width: 360px; }
.picker-alert { margin-bottom: 10px; }
.picker-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 10px;
  font-size: 12px;
}
.picker-actions { display: flex; align-items: center; justify-content: flex-end; gap: 10px; }
.selected-hint { margin-right: auto; font-size: 12px; color: var(--muted); }
</style>
