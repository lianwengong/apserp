<script setup lang="ts">
import { computed, nextTick, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  DataObjectDto,
  FieldAccess,
  FieldDto,
  FormLayoutDto,
  Row
} from '../api/types'
import { listRows, saveRow } from '../api/meta'
import { catalog } from '../stores/catalog'
import {
  decimalScale,
  formatDateTime,
  isBitField,
  isDateField,
  isIntegerField,
  isNumberField
} from '../utils/format'

interface DialogField {
  fieldName: string
  label: string
  controlType: number
  readOnly: boolean
  required: boolean
  span: number
}

interface LookupOption {
  label: string
  value: unknown
}

const props = defineProps<{
  modelValue: boolean
  object: DataObjectDto | null
  fields: FieldDto[]
  forms: FormLayoutDto[]
  access: FieldAccess
  row: Row | null
}>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  saved: []
}>()

const formRef = ref<FormInstance>()
const saving = ref(false)
const values = reactive<Record<string, any>>({})
const lookupOptions = reactive<Record<string, LookupOption[]>>({})

const visible = computed({
  get: () => props.modelValue,
  set: (value: boolean) => emit('update:modelValue', value)
})

const layout = computed<FormLayoutDto | null>(() => {
  return props.forms.find((form) => form.isDefault) ?? props.forms[0] ?? null
})

const layoutColumns = computed(() => Math.min(Math.max(layout.value?.columns ?? 1, 1), 3))

const isEditing = computed(() => props.row !== null)

const title = computed(() => `${isEditing.value ? '编辑' : '新增'}${props.object?.name ?? ''}`)

const SYSTEM_FIELDS = /^(createdby|createdat|modifiedby|modifiedat|deletedby|deletedat|isdeleted|rowversion)$/i

function fieldOf(name: string): FieldDto | undefined {
  return props.fields.find((field) => field.fieldName === name)
}

function guessControl(field: FieldDto): number {
  if (field.lookupType === 2) return 6
  if (isBitField(field)) return 8
  if (isDateField(field)) return 4
  if (isIntegerField(field)) return 2
  if (isNumberField(field)) return 3
  return 1
}

const dialogFields = computed<DialogField[]>(() => {
  const hidden = (name: string): boolean => props.access[name] === 0
  const currentLayout = layout.value

  if (currentLayout && currentLayout.fields.length) {
    return currentLayout.fields
      .filter((field) => !field.hidden && !hidden(field.fieldName))
      .map((field) => {
        const meta = fieldOf(field.fieldName)
        return {
          fieldName: field.fieldName,
          label: field.label ?? meta?.displayName ?? field.fieldName,
          controlType: Number(field.controlType),
          readOnly: field.readOnly,
          required: field.required || meta?.required === true,
          span: field.span
        } satisfies DialogField
      })
  }

  return props.fields
    .filter(
      (field) =>
        !field.primaryKey && !field.identity && !hidden(field.fieldName) && !SYSTEM_FIELDS.test(field.fieldName)
    )
    .map<DialogField>((field) => ({
      fieldName: field.fieldName,
      label: field.displayName,
      controlType: guessControl(field),
      readOnly: false,
      required: field.required,
      span: 0
    }))
})

function effectiveSpan(field: DialogField): number {
  if (!layout.value) return 1
  const base = 12 / layoutColumns.value
  if (!field.span) return 1
  return Math.max(1, Math.min(layoutColumns.value, Math.round(field.span / base)))
}

function isDisabled(field: DialogField): boolean {
  return (
    props.object?.readOnly === true ||
    field.readOnly ||
    props.access[field.fieldName] === 1
  )
}

const rules = computed<FormRules>(() => {
  const result: FormRules = {}
  for (const field of dialogFields.value) {
    if (field.required && !isDisabled(field)) {
      result[field.fieldName] = [
        { required: true, message: `请输入${field.label}`, trigger: ['blur', 'change'] }
      ]
    }
  }
  return result
})

// ---------------------------------------------------------------- 值初始化

function toPickerValue(value: unknown): string {
  if (value === null || value === undefined || value === '') return ''
  return formatDateTime(value, true)
}

function resetValues(): void {
  for (const key of Object.keys(values)) delete values[key]
  const row = props.row
  for (const field of dialogFields.value) {
    const meta = fieldOf(field.fieldName)
    if (row) {
      const raw = row[field.fieldName]
      if (isBitField(meta)) values[field.fieldName] = Boolean(raw)
      else if (isDateField(meta)) values[field.fieldName] = toPickerValue(raw)
      else if (isNumberField(meta)) values[field.fieldName] = raw === null || raw === undefined ? undefined : Number(raw)
      else values[field.fieldName] = raw ?? ''
    } else if (isBitField(meta)) {
      values[field.fieldName] = /^isenabled$/i.test(field.fieldName)
    } else if (isNumberField(meta) && meta?.nullable === false) {
      // 数据库列 NOT NULL 但没有默认值时，留空会导致 INSERT 失败，这里给 0
      values[field.fieldName] = 0
    } else {
      values[field.fieldName] = undefined
    }
  }
}

// ---------------------------------------------------------------- 查找字段

async function loadLookups(): Promise<void> {
  for (const field of dialogFields.value) {
    const meta = fieldOf(field.fieldName)
    if (!meta || meta.lookupType !== 2 || !meta.lookupSource) continue
    if (lookupOptions[field.fieldName]) continue

    const target = catalog.byCode(meta.lookupSource)
    if (!target) continue

    try {
      const result = await listRows(target.code, { page: 1, size: 200, sort: target.defaultOrder ?? '' })
      const display =
        meta.lookupDisplayField && meta.lookupDisplayField !== target.code
          ? meta.lookupDisplayField
          : 'Name'
      lookupOptions[field.fieldName] = result.rows.map((row) => ({
        label: String(row[display] ?? row[target.primaryKey] ?? ''),
        value: row[target.primaryKey]
      }))
    } catch {
      // 查找对象无权限/无数据时降级为手工输入，不阻断表单
      lookupOptions[field.fieldName] = []
    }
  }
}

// ---------------------------------------------------------------- 控件

function controlOf(field: DialogField): 'text' | 'number' | 'money' | 'date' | 'switch' | 'lookup' {
  const meta = fieldOf(field.fieldName)
  if (!meta) return 'text'
  if (isBitField(meta)) return 'switch'
  if (isDateField(meta)) return 'date'
  if (field.controlType === 6) return 'lookup'
  if (isIntegerField(meta)) return 'number'
  if (isNumberField(meta)) return 'money'
  return 'text'
}

function pickerType(field: DialogField): 'date' | 'datetime' {
  const meta = fieldOf(field.fieldName)
  return meta && /datetime/i.test(meta.dataType) ? 'datetime' : 'date'
}

function pickerFormat(field: DialogField): string {
  return pickerType(field) === 'datetime' ? 'YYYY-MM-DD HH:mm:ss' : 'YYYY-MM-DD'
}

function hasLookupOptions(field: DialogField): boolean {
  return (lookupOptions[field.fieldName]?.length ?? 0) > 0
}

/** 查找源对象是否已在当前租户登记（决定渲染下拉还是手工输入）。 */
function lookupConfigured(field: DialogField): boolean {
  const meta = fieldOf(field.fieldName)
  return !!meta?.lookupSource && catalog.byCode(meta.lookupSource) !== undefined
}

function lookupFallbackPlaceholder(field: DialogField): string {
  return `${field.label} ID（查找对象未配置）`
}

// ---------------------------------------------------------------- 保存

function normalizeValue(field: DialogField): unknown {
  const meta = fieldOf(field.fieldName)
  const raw = values[field.fieldName]
  if (isBitField(meta)) return Boolean(raw)
  if (raw === undefined || raw === null || raw === '') return null
  if (isNumberField(meta)) {
    const number = Number(raw)
    return Number.isFinite(number) ? number : null
  }
  return typeof raw === 'string' ? raw : String(raw)
}

async function submit(): Promise<void> {
  if (!props.object || !formRef.value || saving.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  const isInsert = props.row === null
  const payload: Row = {}
  if (props.row) payload[props.object.primaryKey] = props.row[props.object.primaryKey]
  for (const field of dialogFields.value) {
    if (isDisabled(field)) continue
    const meta = fieldOf(field.fieldName)
    let value = normalizeValue(field)

    // 新增时不要提交空值：交给数据库默认值，避免把 NOT NULL 列写成 NULL
    if (isInsert && (value === null || value === '')) continue

    // 修改时把“清空”落到合法值，避免 NOT NULL 约束报 500
    if (value === null && meta && meta.nullable === false) {
      if (isNumberField(meta)) value = 0
      else if (isBitField(meta)) value = false
    }
    payload[field.fieldName] = value
  }

  saving.value = true
  try {
    await saveRow(props.object.code, payload)
    ElMessage.success(isEditing.value ? '已保存修改' : '已新增')
    emit('saved')
    visible.value = false
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '保存失败')
  } finally {
    saving.value = false
  }
}

watch(
  () => props.modelValue,
  (open) => {
    if (!open) return
    resetValues()
    void nextTick(() => formRef.value?.clearValidate())
    void loadLookups()
  }
)
</script>

<template>
  <el-dialog
    v-model="visible"
    :title="title"
    width="660px"
    :close-on-click-modal="false"
    destroy-on-close
  >
    <div v-if="object" class="dialog-sub muted">
      <span class="mono">{{ object.code }}</span>
      <span>·</span>
      <span>{{ object.name }}</span>
      <span v-if="object.readOnly" class="readonly-flag">该对象只读</span>
    </div>

    <el-form
      ref="formRef"
      :model="values"
      :rules="rules"
      label-position="top"
      class="meta-form"
    >
      <div
        class="form-grid"
        :style="{ gridTemplateColumns: `repeat(${layoutColumns}, minmax(0, 1fr))` }"
      >
        <el-form-item
          v-for="field in dialogFields"
          :key="field.fieldName"
          :label="field.label"
          :prop="field.fieldName"
          :style="{ gridColumn: `span ${effectiveSpan(field)}` }"
        >
          <el-select
            v-if="controlOf(field) === 'lookup' && hasLookupOptions(field)"
            v-model="values[field.fieldName]"
            filterable
            clearable
            :disabled="isDisabled(field)"
            :placeholder="`选择${field.label}`"
          >
            <el-option
              v-for="option in lookupOptions[field.fieldName]"
              :key="String(option.value)"
              :label="option.label"
              :value="option.value"
            />
          </el-select>

          <el-select
            v-else-if="controlOf(field) === 'lookup' && lookupConfigured(field)"
            v-model="values[field.fieldName]"
            disabled
            placeholder="查找对象暂无可选数据"
            class="lookup-missing"
          />

          <el-input-number
            v-else-if="controlOf(field) === 'lookup' && isIntegerField(fieldOf(field.fieldName))"
            v-model="values[field.fieldName]"
            :disabled="isDisabled(field)"
            :controls="false"
            :placeholder="lookupFallbackPlaceholder(field)"
            style="width: 100%"
          />

          <el-input
            v-else-if="controlOf(field) === 'lookup'"
            v-model="values[field.fieldName]"
            :disabled="isDisabled(field)"
            :placeholder="lookupFallbackPlaceholder(field)"
          />

          <el-switch
            v-else-if="controlOf(field) === 'switch'"
            v-model="values[field.fieldName]"
            :disabled="isDisabled(field)"
          />

          <el-date-picker
            v-else-if="controlOf(field) === 'date'"
            v-model="values[field.fieldName]"
            :type="pickerType(field)"
            :value-format="pickerFormat(field)"
            :disabled="isDisabled(field)"
            :placeholder="`选择${field.label}`"
            style="width: 100%"
          />

          <el-input-number
            v-else-if="controlOf(field) === 'number'"
            v-model="values[field.fieldName]"
            :disabled="isDisabled(field)"
            :precision="0"
            :controls="false"
            :placeholder="`请输入${field.label}`"
            style="width: 100%"
          />

          <el-input-number
            v-else-if="controlOf(field) === 'money'"
            v-model="values[field.fieldName]"
            :disabled="isDisabled(field)"
            :precision="decimalScale(fieldOf(field.fieldName))"
            :controls="false"
            :placeholder="`请输入${field.label}`"
            style="width: 100%"
          />

          <el-input
            v-else
            v-model="values[field.fieldName]"
            :disabled="isDisabled(field)"
            :maxlength="fieldOf(field.fieldName)?.maxLength ?? undefined"
            :placeholder="`请输入${field.label}`"
            clearable
          />
        </el-form-item>
      </div>
    </el-form>

    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="submit">保存</el-button>
    </template>
  </el-dialog>
</template>

<style scoped>
.dialog-sub {
  display: flex;
  align-items: center;
  gap: 6px;
  margin: -4px 0 14px;
  font-size: 11.5px;
}

.readonly-flag {
  margin-left: 6px;
  padding: 1px 6px;
  border-radius: 4px;
  background: #f2f5f9;
  color: #7d8b9a;
}

.form-grid {
  display: grid;
  gap: 0 16px;
}

.meta-form :deep(.el-form-item) {
  margin-bottom: 14px;
}

.lookup-missing {
  width: 100%;
}
</style>
