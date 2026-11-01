<template>
  <div class="button-designer">
    <el-row :gutter="12">
      <el-col :span="7">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>按钮（{{ objectCode }}）</span>
              <el-button size="small" type="primary" @click="newButton">新建</el-button>
            </div>
          </template>
          <el-select v-model="objectCode" size="small" filterable style="width: 100%; margin-bottom: 8px" @change="load">
            <el-option v-for="o in objects" :key="o.code" :value="o.code" :label="`${o.code} ${o.name}`" />
          </el-select>
          <el-scrollbar height="450px">
            <div
              v-for="b in buttons"
              :key="b.code"
              class="button-item"
              :class="{ active: form.code === b.code }"
              @click="edit(b)"
            >
              <div class="button-top">
                <el-tag size="small" :type="styleTag(b.style)" effect="plain">{{ b.text || b.name }}</el-tag>
                <span class="button-code">{{ b.code }}</span>
              </div>
              <div class="button-meta">
                {{ b.actions.length }} 个动作 · {{ b.buttonType === 3 ? '审批' : b.buttonType === 4 ? '工具栏' : '行内' }}
              </div>
            </div>
            <el-empty v-if="!buttons.length" description="该对象还没有按钮" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="17">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>{{ editing ? '编辑按钮' : '新建按钮' }}</span>
              <div>
                <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
                <el-button v-if="editing" size="small" type="danger" plain @click="remove">删除</el-button>
              </div>
            </div>
          </template>

          <el-form :model="form" label-width="92px" size="small">
            <el-row :gutter="12">
              <el-col :span="10">
                <el-form-item label="编码" required>
                  <el-input v-model="form.code" :disabled="editing" placeholder="BTN-XXX" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="文案">
                  <el-input v-model="form.text" />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="类型">
                  <el-select v-model="form.buttonType">
                    <el-option :value="1" label="行内动作" />
                    <el-option :value="2" label="表单动作" />
                    <el-option :value="3" label="审批" />
                    <el-option :value="4" label="工具栏" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>
            <el-row :gutter="12">
              <el-col :span="10">
                <el-form-item label="名称">
                  <el-input v-model="form.name" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="样式">
                  <el-select v-model="form.style" clearable>
                    <el-option value="primary" label="primary" />
                    <el-option value="success" label="success" />
                    <el-option value="warning" label="warning" />
                    <el-option value="danger" label="danger" />
                    <el-option value="" label="默认" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="排序">
                  <el-input-number v-model="form.sort" :min="0" :step="10" controls-position="right" />
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="权限功能点">
              <el-select v-model="form.functionId" clearable filterable placeholder="不选=所有有该对象读权限的人可见">
                <el-option v-for="f in functions" :key="f.id" :value="f.id" :label="`${f.code} ${f.name}`" />
              </el-select>
            </el-form-item>

            <el-row :gutter="12">
              <el-col :span="12">
                <el-form-item label="可见表达式">
                  <el-input v-model="form.visibleExpr" placeholder="ctx.IsEnabled == true" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="可用表达式">
                  <el-input v-model="form.enabledExpr" placeholder="ctx.Status != 2" />
                </el-form-item>
              </el-col>
            </el-row>
            <div class="hint">
              可见表达式为 false 时按钮<b>不下发</b>；可用表达式为 false 时<b>置灰</b>并给出原因。
              两个表达式都按当前行数据求值，空值比较一律 false。
            </div>

            <el-divider content-position="left">动作链（按顺序执行）</el-divider>
            <el-table :data="form.actions" size="small" border>
              <el-table-column label="序号" width="60" align="center">
                <template #default="{ $index }">{{ $index + 1 }}</template>
              </el-table-column>
              <el-table-column label="类型" width="120">
                <template #default="{ row }">
                  <el-select v-model="row.actionType" size="small">
                    <el-option :value="1" label="内置" />
                    <el-option :value="2" label="导航" />
                    <el-option :value="3" label="命令" />
                    <el-option :value="4" label="脚本(白名单)" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="内置动作/命令" min-width="150">
                <template #default="{ row }">
                  <el-select
                    v-if="row.actionType === 1 || row.actionType === 4"
                    v-model="row.builtinCode"
                    size="small"
                    allow-create
                    filterable
                  >
                    <el-option
                      v-for="c in row.actionType === 1 ? BUILTINS : WHITELIST"
                      :key="c"
                      :value="c"
                      :label="c"
                    />
                  </el-select>
                  <el-input v-else v-model="row.target" size="small" placeholder="/object/md.brand" />
                </template>
              </el-table-column>
              <el-table-column label="确认文案" min-width="140">
                <template #default="{ row }">
                  <el-input v-model="row.confirmText" size="small" />
                </template>
              </el-table-column>
              <el-table-column label="流程" width="60" align="center">
                <template #default="{ row }">
                  <el-checkbox v-model="row.needWorkflow" />
                </template>
              </el-table-column>
              <el-table-column label="" width="60" align="center">
                <template #default="{ $index }">
                  <el-button link type="danger" size="small" @click="form.actions.splice($index, 1)">删</el-button>
                </template>
              </el-table-column>
            </el-table>
            <el-button size="small" plain style="margin-top: 8px" @click="addAction">新增动作</el-button>
          </el-form>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { designApi, type ActionForm, type ButtonDto } from '../../api/design'
import { metaApi } from '../../api/definition'
import type { DataObjectDto } from '../../api/types'

const BUILTINS = ['OPEN_FORM', 'DELETE', 'SUBMIT', 'EXPORT', 'REFRESH', 'CLOSE']
const WHITELIST = ['PRINT', 'EXPORT', 'REFRESH', 'SYNC', 'COPY', 'NOTIFY']


const objects = ref<DataObjectDto[]>([])
const buttons = ref<ButtonDto[]>([])
const functions = ref<{ id: number; code: string; name: string }[]>([])
const objectCode = ref('')
const editing = ref(false)
const saving = ref(false)

const form = reactive({
  id: null as number | null,
  code: '',
  name: '',
  text: '',
  icon: '',
  buttonType: 1,
  functionId: 0,
  sort: 10,
  visible: true,
  visibleExpr: '',
  enabledExpr: '',
  style: '',
  remark: '',
  actions: [] as ActionForm[]
})

function styleTag(style: string | null) {
  if (style === 'danger') return 'danger'
  if (style === 'warning') return 'warning'
  if (style === 'success') return 'success'
  return 'primary'
}

function newButton() {
  editing.value = false
  Object.assign(form, {
    id: null,
    code: '',
    name: '',
    text: '',
    icon: '',
    buttonType: 1,
    functionId: 0,
    sort: (buttons.value.length + 1) * 10,
    visible: true,
    visibleExpr: '',
    enabledExpr: '',
    style: '',
    remark: '',
    actions: []
  })
}

function edit(b: ButtonDto) {
  editing.value = true
  Object.assign(form, {
    id: b.id,
    code: b.code,
    name: b.name,
    text: b.text ?? '',
    icon: b.icon ?? '',
    buttonType: b.buttonType,
    functionId: 0,
    sort: b.sort,
    visible: true,
    visibleExpr: b.visibleExpr ?? '',
    enabledExpr: b.enabledExpr ?? '',
    style: b.style ?? '',
    remark: '',
    actions: b.actions.map((a) => ({
      actionType: a.actionType,
      builtinCode: a.builtinCode,
      target: a.target,
      command: a.command,
      paramJson: a.paramJson,
      confirmText: a.confirmText,
      successMessage: a.successMessage,
      needWorkflow: a.needWorkflow
    }))
  })
}

function addAction() {
  form.actions.push({
    actionType: 1,
    builtinCode: 'OPEN_FORM',
    target: null,
    command: null,
    paramJson: null,
    confirmText: '',
    successMessage: '',
    needWorkflow: false
  })
}

async function load() {
  try {
    objects.value = await metaApi.objects()
    if (!objectCode.value && objects.value.length) objectCode.value = objects.value[0].code
    buttons.value = await designApi.buttons(objectCode.value)
    functions.value = await designApi.buttonFunctions(objectCode.value)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function save() {
  if (!form.code.trim()) return ElMessage.warning('编码必填')
  saving.value = true
  try {
    await designApi.saveButton({ ...form, code: form.code.trim() })
    ElMessage.success('已保存')
    editing.value = true
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

async function remove() {
  try {
    await ElMessageBox.confirm(`删除按钮 ${form.code}？`, '确认', { type: 'warning' })
    await designApi.deleteButton(form.code)
    ElMessage.success('已删除')
    newButton()
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
.button-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.button-item:hover { background: var(--el-fill-color-light); }
.button-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.button-top { display: flex; align-items: center; gap: 8px; }
.button-code { font-family: Consolas, monospace; font-size: 12px; color: var(--el-text-color-secondary); }
.button-meta { font-size: 11px; color: var(--el-text-color-secondary); margin-top: 3px; }
.hint { font-size: 11px; color: var(--el-text-color-secondary); margin: -4px 0 8px 92px; line-height: 1.6; }
</style>
