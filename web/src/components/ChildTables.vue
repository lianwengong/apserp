<template>
  <div v-if="relations.length" class="child-tables">
    <div class="child-head">
      <span class="child-title">明细</span>
      <span class="muted">子表数据随主表一起提交（同一事务）；删除的行在保存后生效</span>
    </div>

    <div v-for="rel in relations" :key="rel.alias" class="child-block">
      <div class="block-head">
        <span class="block-name">{{ rel.displayName || rel.alias }}</span>
        <span class="mono muted">{{ rel.childObjectCode }} · {{ rel.alias }}</span>
        <el-button
          size="small"
          link
          type="primary"
          :disabled="rowsOf(rel.alias).length >= rel.maxRows"
          @click="addRow(rel)"
        >
          + 新增一行
        </el-button>
        <span class="muted">共 {{ rowsOf(rel.alias).length }} / {{ rel.maxRows }}</span>
      </div>

      <el-table :data="rowsOf(rel.alias)" size="small" border empty-text="没有明细">
        <el-table-column
          v-for="field in columnsOf(rel.childObjectCode, rel.foreignKeyField)"
          :key="field.fieldName"
          :label="field.displayName || field.fieldName"
          :min-width="widthOf(field)"
        >
          <template #default="{ row }">
            <el-switch
              v-if="isBit(field)"
              v-model="row[field.fieldName]"
              size="small"
            />
            <el-input-number
              v-else-if="isNumeric(field)"
              v-model="row[field.fieldName] as number"
              size="small"
              :controls="false"
              style="width: 100%"
            />
            <el-input
              v-else
              v-model="row[field.fieldName] as string"
              size="small"
              :maxlength="field.maxLength ?? undefined"
            />
          </template>
        </el-table-column>
        <el-table-column label="" width="60" align="center">
          <template #default="{ $index }">
            <el-button link size="small" type="danger" @click="removeRow(rel.alias, $index)">删</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { designApi, type RelationDto } from '../api/design'
import { runtimeApi } from '../api/runtime'
import { metaApi } from '../api/definition'
import type { FieldDto } from '../api/types'

/**
 * 明细编辑器：子表结构来自关系元数据，字段来自子对象定义。
 * 值通过 v-model 回传给表单，由表单随主表一起提交。
 */
const props = defineProps<{
  objectCode: string
  parentId: number | null
  modelValue: Record<string, Record<string, unknown>[]>
}>()
const emit = defineEmits<{
  (e: 'update:modelValue', v: Record<string, Record<string, unknown>[]>): void
}>()

const relations = ref<RelationDto[]>([])
const fieldsMap = ref<Record<string, FieldDto[]>>({})
const state = ref<Record<string, Record<string, unknown>[]>>({})

function rowsOf(alias: string): Record<string, unknown>[] {
  return state.value[alias] ?? []
}

function columnsOf(childCode: string, exclude?: string): FieldDto[] {
  const all = fieldsMap.value[childCode] ?? []
  return all.filter(
    (f) =>
      !f.primaryKey &&
      f.fieldName !== exclude &&
      !/^(isdeleted|tenantid|createdby|createdat|modifiedby|modifiedat|deletedby|deletedat|rowversion)$/i.test(
        f.fieldName
      )
  )
}

function isBit(field: FieldDto) {
  return /^bit$/i.test(field.dataType)
}
function isNumeric(field: FieldDto) {
  return /^(int|bigint|smallint|tinyint|decimal|numeric|money|float|real)$/i.test(field.dataType)
}
function widthOf(field: FieldDto) {
  if (isBit(field)) return 90
  if (isNumeric(field)) return 110
  return 160
}

function sync() {
  const plain: Record<string, Record<string, unknown>[]> = {}
  for (const [k, v] of Object.entries(state.value)) plain[k] = v
  emit('update:modelValue', plain)
}

function addRow(rel: RelationDto) {
  const blank: Record<string, unknown> = {}
  for (const f of columnsOf(rel.childObjectCode, rel.foreignKeyField)) {
    blank[f.fieldName] = isBit(f) ? false : isNumeric(f) ? null : ''
  }
  if (!state.value[rel.alias]) state.value[rel.alias] = []
  state.value[rel.alias].push(blank)
  sync()
}

function removeRow(alias: string, index: number) {
  state.value[alias]?.splice(index, 1)
  sync()
}

async function loadRelations() {
  try {
    const all = await designApi.relations(props.objectCode)
    relations.value = all.filter((r) => r.enabled && r.parentObjectCode === props.objectCode)
    for (const rel of relations.value) {
      if (!fieldsMap.value[rel.childObjectCode]) {
        fieldsMap.value[rel.childObjectCode] = await metaApi.fields(rel.childObjectCode)
      }
      if (!state.value[rel.alias]) state.value[rel.alias] = []
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function loadRows() {
  if (!props.parentId) return
  try {
    const groups = await runtimeApi.children(props.objectCode, props.parentId)
    for (const g of groups) {
      state.value[g.alias] = g.rows.map((r) => ({ ...r }))
    }
    sync()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

watch(
  () => props.parentId,
  () => {
    state.value = {}
    void loadRows()
  }
)

onMounted(async () => {
  await loadRelations()
  await loadRows()
})

defineExpose({ reload: loadRows })
</script>

<style scoped>
.child-tables { margin-top: 14px; border-top: 1px dashed var(--el-border-color); padding-top: 10px; }
.child-head { display: flex; align-items: baseline; gap: 10px; margin-bottom: 8px; }
.child-title { font-weight: 600; font-size: 13px; }
.child-block { margin-bottom: 14px; }
.block-head { display: flex; align-items: center; gap: 10px; margin-bottom: 4px; }
.block-name { font-weight: 600; font-size: 13px; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.mono { font-family: Consolas, monospace; }
</style>
