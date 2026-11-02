<template>
  <div class="code-rule-admin">
    <div class="head">
      <div>
        <h2>编号规则</h2>
        <p class="sub">
          单号 = 前缀 + 日期 + 分隔符 + 补零流水。流水按「期间」单独计数，按年/月/日重置只是换一行流水，
          不需要定时任务；取号使用行锁原子自增，并发下不会重号。
        </p>
      </div>
      <div class="head-actions">
        <el-input v-model="keyword" size="small" placeholder="搜索编码/名称" clearable style="width: 170px" />
        <el-button size="small" @click="load">刷新</el-button>
        <el-button size="small" type="primary" @click="newRule">新建规则</el-button>
      </div>
    </div>

    <el-row :gutter="12">
      <el-col :span="15">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>规则列表</span>
              <span class="muted">共 {{ rules.length }} 条</span>
            </div>
          </template>
          <el-table :data="filtered" size="small" border empty-text="还没有编号规则" @row-click="edit">
            <el-table-column label="编码" width="170">
              <template #default="{ row }"><span class="mono">{{ row.code }}</span></template>
            </el-table-column>
            <el-table-column prop="name" label="名称" width="130" />
            <el-table-column label="示例" width="190">
              <template #default="{ row }"><span class="mono sample">{{ row.sample }}</span></template>
            </el-table-column>
            <el-table-column label="重置" width="90" align="center">
              <template #default="{ row }">{{ cycleName(row.resetCycle) }}</template>
            </el-table-column>
            <el-table-column label="状态" width="80" align="center">
              <template #default="{ row }">
                <el-tag size="small" :type="row.enabled ? 'success' : 'info'">
                  {{ row.enabled ? '启用' : '停用' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150" align="center">
              <template #default="{ row }">
                <el-button link size="small" @click.stop="showStat(row)">流水</el-button>
                <el-button link size="small" type="primary" @click.stop="edit(row)">改</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <el-col :span="9">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>试算</span>
              <span class="muted">预览不消耗流水</span>
            </div>
          </template>
          <el-select
            v-model="previewCode"
            size="small"
            filterable
            style="width: 100%; margin-bottom: 10px"
            placeholder="选一条规则"
            @change="onPreviewCode"
          >
            <el-option v-for="r in rules" :key="r.code" :value="r.code" :label="`${r.code} ${r.name ?? ''}`" />
          </el-select>
          <div class="preview-box">
            <div class="preview-label">下一个号</div>
            <div class="preview-value mono">{{ previewNo || '—' }}</div>
          </div>
          <div class="preview-actions">
            <el-button size="small" @click="refreshPreview">预览</el-button>
            <el-button size="small" type="warning" plain @click="consume">真实取号（消耗 +1）</el-button>
          </div>
          <p class="tip">真实取号会推进流水，只用于验证；业务取号应在保存单据时调用。</p>

          <template v-if="stat">
            <el-divider />
            <div class="stat-title">
              流水 · <span class="mono">{{ stat.code }}</span>
            </div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="当前期间">{{ stat.period || '（不重置）' }}</el-descriptions-item>
              <el-descriptions-item label="当前值">{{ stat.currentValue }}</el-descriptions-item>
              <el-descriptions-item label="下一个" :span="2">
                <span class="mono">{{ stat.next }}</span>
              </el-descriptions-item>
            </el-descriptions>
            <el-table :data="stat.periods" size="small" border class="period-table">
              <el-table-column label="期间" min-width="120">
                <template #default="{ row }">{{ row.Period || '（不重置）' }}</template>
              </el-table-column>
              <el-table-column prop="CurrentValue" label="流水值" width="90" align="right" />
            </el-table>
          </template>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog v-model="formVisible" :title="form.id ? `编辑规则 ${form.code}` : '新建编号规则'" width="620px">
      <el-form :model="form" label-width="96px" size="small">
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="规则编码" required>
              <el-input v-model="form.code" :disabled="!!form.id" placeholder="PURCHASE_ORDER" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="名称">
              <el-input v-model="form.name" placeholder="采购订单" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="前缀">
              <el-input v-model="form.prefix" placeholder="PO" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="日期格式">
              <el-select v-model="form.datePattern" clearable placeholder="不带日期">
                <el-option value="yyyyMMdd" label="yyyyMMdd（20261102）" />
                <el-option value="yyyyMM" label="yyyyMM（202611）" />
                <el-option value="yyyy" label="yyyy（2026）" />
                <el-option value="yyMMdd" label="yyMMdd（261102）" />
                <el-option value="yyyyMMddHHmmss" label="yyyyMMddHHmmss（到秒）" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="8">
            <el-form-item label="分隔符">
              <el-input v-model="form.separator" placeholder="-" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="流水位数">
              <el-input-number v-model="form.digitCount" :min="1" :max="12" :controls="false" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="重置周期">
              <el-select v-model="form.resetCycle">
                <el-option :value="0" label="不重置" />
                <el-option :value="1" label="按年" />
                <el-option :value="2" label="按月" />
                <el-option :value="3" label="按日" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="业务对象">
          <el-input v-model="form.objectType" placeholder="可空；填单据类型编码，便于按对象找规则" />
        </el-form-item>
        <el-form-item label="示例">
          <div class="sample-line">
            <span class="mono sample">{{ sampleOf(form) }}</span>
            <span class="muted">（保存后由服务端按同样规则生成并存库）</span>
          </div>
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="form.enabled" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { codeRuleApi, type CodeRuleDto } from '../../api/code'

const rules = ref<CodeRuleDto[]>([])
const keyword = ref('')
const saving = ref(false)
const formVisible = ref(false)
const previewCode = ref('')
const previewNo = ref('')
const stat = ref<Awaited<ReturnType<typeof codeRuleApi.statistics>> | null>(null)

const form = reactive({
  id: null as number | null,
  code: '',
  name: '',
  objectType: '',
  prefix: '',
  datePattern: 'yyyyMMdd',
  separator: '-',
  digitCount: 4,
  resetCycle: 3,
  enabled: true,
  remark: ''
})

const filtered = computed(() => {
  const key = keyword.value.trim().toLowerCase()
  if (!key) return rules.value
  return rules.value.filter(
    (r) => r.code.toLowerCase().includes(key) || (r.name ?? '').toLowerCase().includes(key)
  )
})

function cycleName(cycle: number): string {
  return ['不重置', '按年', '按月', '按日'][cycle] ?? String(cycle)
}

/** 前端只做「所见即所得」的示例；真值以服务端保存后返回的 sample 为准 */
function sampleOf(f: typeof form): string {
  const now = new Date()
  const pad = (n: number) => String(n).padStart(2, '0')
  const yyyy = String(now.getFullYear())
  const mm = pad(now.getMonth() + 1)
  const dd = pad(now.getDate())
  const date =
    f.datePattern === 'yyyyMMdd'
      ? `${yyyy}${mm}${dd}`
      : f.datePattern === 'yyyyMM'
        ? `${yyyy}${mm}`
        : f.datePattern === 'yyyy'
          ? yyyy
          : f.datePattern === 'yyMMdd'
            ? `${yyyy.slice(2)}${mm}${dd}`
            : f.datePattern === 'yyyyMMddHHmmss'
              ? `${yyyy}${mm}${dd}${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`
              : ''
  return `${f.prefix || ''}${date}${f.separator ?? ''}${'1'.padStart(Math.max(1, f.digitCount), '0')}`
}

async function load() {
  try {
    rules.value = await codeRuleApi.list()
    if (!previewCode.value && rules.value.length) {
      previewCode.value = rules.value[0].code
      await refreshPreview()
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function newRule() {
  Object.assign(form, {
    id: null,
    code: '',
    name: '',
    objectType: '',
    prefix: '',
    datePattern: 'yyyyMMdd',
    separator: '-',
    digitCount: 4,
    resetCycle: 3,
    enabled: true,
    remark: ''
  })
  formVisible.value = true
}

function edit(row: CodeRuleDto) {
  Object.assign(form, {
    id: row.id,
    code: row.code,
    name: row.name ?? '',
    objectType: row.objectType ?? '',
    prefix: row.prefix ?? '',
    datePattern: row.datePattern ?? '',
    separator: row.separator ?? '-',
    digitCount: row.digitCount,
    resetCycle: row.resetCycle,
    enabled: row.enabled,
    remark: row.remark ?? ''
  })
  formVisible.value = true
}

async function save() {
  if (!form.code.trim()) return ElMessage.warning('规则编码必填')
  saving.value = true
  try {
    await codeRuleApi.save({ ...form, code: form.code.trim() })
    ElMessage.success('已保存')
    formVisible.value = false
    await load()
    if (previewCode.value) await refreshPreview()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

async function onPreviewCode(code: string) {
  stat.value = null
  await refreshPreview()
  void code
}

async function refreshPreview() {
  if (!previewCode.value) return
  try {
    const result = await codeRuleApi.preview(previewCode.value)
    previewNo.value = result.docNo
  } catch (e) {
    previewNo.value = ''
    ElMessage.error((e as Error).message)
  }
}

async function consume() {
  if (!previewCode.value) return
  try {
    const result = await codeRuleApi.next(previewCode.value)
    ElMessage.success(`已取号 ${result.docNo}`)
    await refreshPreview()
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function showStat(row: CodeRuleDto) {
  previewCode.value = row.code
  try {
    stat.value = await codeRuleApi.statistics(row.code)
    previewNo.value = stat.value.next
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

onMounted(load)
</script>

<style scoped>
.code-rule-admin { padding: 4px 2px; }
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 10px; }
.head h2 { margin: 0; font-size: 18px; }
.sub { margin: 4px 0 0; font-size: 12px; color: var(--el-text-color-secondary); max-width: 820px; line-height: 1.6; }
.head-actions { display: flex; gap: 8px; align-items: center; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.mono { font-family: Consolas, monospace; }
.sample { color: var(--brand-700); font-weight: 600; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.preview-box { border: 1px dashed var(--el-border-color); border-radius: 8px; padding: 12px; text-align: center; }
.preview-label { font-size: 11px; color: var(--el-text-color-secondary); }
.preview-value { font-size: 20px; font-weight: 700; letter-spacing: 0.04em; margin-top: 4px; color: var(--brand-700); }
.preview-actions { display: flex; gap: 8px; margin-top: 10px; }
.tip { margin: 8px 0 0; font-size: 11px; color: var(--el-text-color-secondary); line-height: 1.6; }
.stat-title { font-size: 13px; font-weight: 600; margin-bottom: 8px; }
.period-table { margin-top: 8px; }
.sample-line { display: flex; align-items: center; gap: 10px; }
</style>
