<template>
  <div class="rule-designer">
    <el-row :gutter="12">
      <el-col :span="8">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>规则列表</span>
              <el-button size="small" type="primary" @click="newRule">新建</el-button>
            </div>
          </template>
          <el-scrollbar height="520px">
            <div
              v-for="r in rules"
              :key="r.code"
              class="rule-item"
              :class="{ active: form.code === r.code, disabled: !r.enabled }"
              @click="edit(r)"
            >
              <div class="rule-top">
                <span class="rule-code">{{ r.code }}</span>
                <el-tag size="small" :type="r.severity === 2 ? 'danger' : 'warning'" effect="plain">
                  {{ r.severity === 2 ? '错误' : '警告' }}
                </el-tag>
              </div>
              <div class="rule-name">{{ r.name }}</div>
              <div class="rule-meta">绑定 {{ r.bindingCount }} 处 · {{ r.enabled ? '启用' : '停用' }}</div>
            </div>
            <el-empty v-if="!rules.length" description="还没有规则" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="16">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>{{ editing ? '编辑规则' : '新建规则' }}</span>
              <div>
                <el-button size="small" @click="validateExpr">校验表达式</el-button>
                <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
                <el-button v-if="editing" size="small" type="danger" plain @click="remove">删除</el-button>
              </div>
            </div>
          </template>

          <el-form :model="form" label-width="96px" size="small">
            <el-row :gutter="12">
              <el-col :span="10">
                <el-form-item label="规则编码" required>
                  <el-input v-model="form.code" :disabled="editing" placeholder="R-XXX" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="名称">
                  <el-input v-model="form.name" placeholder="面向前端展示" />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="级别">
                  <el-select v-model="form.severity">
                    <el-option :value="2" label="错误（阻断）" />
                    <el-option :value="1" label="警告（放行）" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="表达式" required>
              <el-input
                v-model="form.expression"
                type="textarea"
                :rows="4"
                spellcheck="false"
                placeholder="ctx.Code != null && ctx.Code.length() <= 32"
              />
              <div class="hint">
                可用：<code>ctx.字段</code>、<code>== != &gt; &gt;= &lt; &lt;=</code>、<code>&amp;&amp; || !</code>、
                <code>len / isEmpty / contains / upper</code>，链式 <code>ctx.Name.trim().isEmpty()</code>。
                空值参与大小比较一律为 false，判空请显式写 <code>ctx.X == null</code>。
              </div>
              <el-alert
                v-if="exprResult"
                :type="exprResult.valid ? 'success' : 'error'"
                :title="exprResult.valid ? '语法通过' : exprResult.error ?? '语法错误'"
                :closable="false"
                show-icon
                class="expr-alert"
              />
            </el-form-item>

            <el-form-item label="错误提示">
              <el-input v-model="form.errorMessage" placeholder="校验失败时给用户看的文案" />
            </el-form-item>
            <el-form-item label="启用">
              <el-switch v-model="form.enabled" />
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remark" />
            </el-form-item>
          </el-form>

          <el-divider content-position="left">绑定与测试</el-divider>
          <el-row :gutter="12">
            <el-col :span="11">
              <el-form label-width="78px" size="small">
                <el-form-item label="数据对象">
                  <el-select v-model="bindObject" filterable @change="loadBindings">
                    <el-option v-for="o in objects" :key="o.code" :value="o.code" :label="`${o.code} ${o.name}`" />
                  </el-select>
                </el-form-item>
                <el-form-item label="触发时机">
                  <el-select v-model="bindTrigger">
                    <el-option :value="1" label="保存前（阻断）" />
                    <el-option :value="3" label="删除前（阻断）" />
                  </el-select>
                </el-form-item>
                <el-form-item>
                  <el-button size="small" type="primary" plain @click="addBinding">绑定当前规则</el-button>
                </el-form-item>
              </el-form>
              <el-table :data="bindings" size="small" border max-height="180">
                <el-table-column prop="ruleCode" label="规则" />
                <el-table-column prop="fieldName" label="字段" width="90" />
                <el-table-column prop="triggerEvent" label="时机" width="70" align="center" />
                <el-table-column label="" width="60" align="center">
                  <template #default="{ row }">
                    <el-button link type="danger" size="small" @click="removeBinding(row.id)">解绑</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </el-col>

            <el-col :span="13">
              <el-form label-width="78px" size="small">
                <el-form-item label="测试数据">
                  <el-input v-model="testJson" type="textarea" :rows="5" spellcheck="false" />
                </el-form-item>
                <el-form-item>
                  <el-button size="small" type="primary" @click="runTest">运行测试</el-button>
                  <span class="hint-inline">对象 {{ bindObject || '未选' }} 的全部规则逐条执行</span>
                </el-form-item>
              </el-form>
              <el-table :data="testRows" size="small" border max-height="160" empty-text="点“运行测试”看结果">
                <el-table-column prop="ruleCode" label="规则" width="150" />
                <el-table-column label="结果" width="70" align="center">
                  <template #default="{ row }">
                    <el-tag size="small" :type="row.passed ? 'success' : 'danger'">
                      {{ row.passed ? '通过' : '不通过' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="message" label="提示 / 错误" show-overflow-tooltip />
              </el-table>
            </el-col>
          </el-row>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { designApi, type RuleDto, type RuleBindingDto } from '../../api/design'
import { metaApi } from '../../api/definition'
import type { DataObjectDto } from '../../api/types'

const rules = ref<RuleDto[]>([])
const objects = ref<DataObjectDto[]>([])
const bindings = ref<RuleBindingDto[]>([])
const bindObject = ref('')
const bindTrigger = ref(1)
const editing = ref(false)
const saving = ref(false)
const exprResult = ref<{ valid: boolean; error: string | null } | null>(null)
const testJson = ref('{\n  "Code": "B001",\n  "Name": "测试品牌",\n  "Sort": 10\n}')
const testRows = ref<import('../../api/design').RuleTestRow[]>([])

const form = reactive({
  id: null as number | null,
  code: '',
  name: '',
  ruleType: 1,
  expression: '',
  errorMessage: '',
  severity: 2,
  enabled: true,
  remark: ''
})

function newRule() {
  editing.value = false
  exprResult.value = null
  Object.assign(form, {
    id: null,
    code: '',
    name: '',
    ruleType: 1,
    expression: '',
    errorMessage: '',
    severity: 2,
    enabled: true,
    remark: ''
  })
}

function edit(r: RuleDto) {
  editing.value = true
  exprResult.value = null
  Object.assign(form, {
    id: r.id,
    code: r.code,
    name: r.name,
    ruleType: r.ruleType,
    expression: r.expression,
    errorMessage: r.errorMessage ?? '',
    severity: r.severity,
    enabled: r.enabled,
    remark: r.remark ?? ''
  })
}

async function load() {
  try {
    rules.value = await designApi.rules()
    objects.value = await metaApi.objects()
    if (!bindObject.value && objects.value.length) bindObject.value = objects.value[0].code
    await loadBindings()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function loadBindings() {
  if (!bindObject.value) return
  try {
    bindings.value = await designApi.bindings(bindObject.value)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function validateExpr() {
  try {
    exprResult.value = await designApi.validateRule(form.expression)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function save() {
  if (!form.code.trim()) return ElMessage.warning('规则编码必填')
  if (!form.expression.trim()) return ElMessage.warning('表达式必填')
  saving.value = true
  try {
    await designApi.saveRule({ ...form, code: form.code.trim() })
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
    await ElMessageBox.confirm(`删除规则 ${form.code}？其绑定会一并删除。`, '确认', { type: 'warning' })
    await designApi.deleteRule(form.code)
    ElMessage.success('已删除')
    newRule()
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

async function addBinding() {
  if (!form.code) return ElMessage.warning('先选一条规则')
  const rule = rules.value.find((r) => r.code === form.code)
  if (!rule) return ElMessage.warning('规则尚未保存')
  try {
    await designApi.bind({
      ruleId: rule.id,
      objectCode: bindObject.value,
      fieldName: null,
      triggerEvent: bindTrigger.value,
      sort: (bindings.value.length + 1) * 10,
      enabled: true
    })
    ElMessage.success('已绑定')
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function removeBinding(id: number) {
  try {
    await designApi.unbind(id)
    ElMessage.success('已解绑')
    await loadBindings()
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function runTest() {
  let data: Record<string, unknown>
  try {
    data = JSON.parse(testJson.value)
  } catch {
    return ElMessage.warning('测试数据不是合法 JSON')
  }
  try {
    testRows.value = await designApi.testRule(bindObject.value, bindTrigger.value, data)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

onMounted(load)
</script>

<style scoped>
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.rule-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.rule-item:hover { background: var(--el-fill-color-light); }
.rule-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.rule-item.disabled { opacity: 0.55; }
.rule-top { display: flex; justify-content: space-between; align-items: center; }
.rule-code { font-family: Consolas, monospace; font-size: 13px; }
.rule-name { font-size: 12px; margin: 2px 0; }
.rule-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.hint { font-size: 11px; color: var(--el-text-color-secondary); line-height: 1.6; margin-top: 4px; }
.hint code { background: var(--el-fill-color); padding: 0 3px; border-radius: 3px; }
.hint-inline { font-size: 11px; color: var(--el-text-color-secondary); margin-left: 8px; }
.expr-alert { margin-top: 6px; }
</style>
