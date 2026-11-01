<template>
  <div class="field-designer">
    <el-alert type="info" :closable="false" show-icon class="tip">
      字段设计器：数据对象与字段的元数据是引擎的根，本页只读展示并给出「字段语义体检」。
      修改走版本化迁移（Flyway），不允许在设计器里直接改表结构。
    </el-alert>

    <el-row :gutter="12">
      <el-col :span="7">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>数据对象</span>
              <el-input v-model="keyword" size="small" placeholder="搜索编码/名称" clearable style="width: 140px" />
            </div>
          </template>
          <el-scrollbar height="460px">
            <div
              v-for="o in filteredObjects"
              :key="o.code"
              class="object-item"
              :class="{ active: o.code === current }"
              @click="select(o.code)"
            >
              <div class="object-code">{{ o.code }}</div>
              <div class="object-name">{{ o.name }}</div>
              <el-tag size="small" type="info" effect="plain">{{ o.schemaName }}.{{ o.objectName }}</el-tag>
            </div>
            <el-empty v-if="!filteredObjects.length" description="没有匹配的数据对象" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="17">
        <el-card shadow="never" class="panel" v-loading="loading">
          <template #header>
            <div class="panel-head">
              <span>字段定义 <b v-if="current">{{ current }}</b></span>
              <div class="head-actions">
                <el-tag v-if="object" size="small">主键 {{ object.primaryKey }}</el-tag>
                <el-tag v-if="object?.docNoField" size="small" type="warning">单号 {{ object.docNoField }}</el-tag>
                <el-tag v-if="object?.tenantField" size="small" type="success">租户 {{ object.tenantField }}</el-tag>
              </div>
            </div>
          </template>

          <el-table :data="fields" size="small" border height="380px" empty-text="选择左侧对象查看字段">
            <el-table-column prop="fieldName" label="字段" width="150" />
            <el-table-column prop="displayName" label="显示名" width="120" />
            <el-table-column prop="dataType" label="类型" width="130" />
            <el-table-column label="约束" min-width="220">
              <template #default="{ row }">
                <el-tag v-if="row.primaryKey" size="small" type="danger" effect="plain">PK</el-tag>
                <el-tag v-if="row.identity" size="small" type="info" effect="plain">自增</el-tag>
                <el-tag v-if="row.required" size="small" type="warning" effect="plain">必填</el-tag>
                <el-tag v-if="row.lookupType > 0" size="small" type="success" effect="plain">
                  查找 {{ row.lookupSource ?? '' }}
                </el-tag>
                <el-tag v-if="!row.nullable && !row.primaryKey" size="small" effect="plain">非空</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="sort" label="排序" width="70" align="center" />
          </el-table>

          <div class="health" v-if="current">
            <div class="health-title">字段语义体检</div>
            <ul>
              <li v-for="(issue, idx) in healthIssues" :key="idx" :class="issue.level">
                {{ issue.text }}
              </li>
              <li v-if="!healthIssues.length" class="ok">未发现明显问题</li>
            </ul>
          </div>

          <div class="views">
            <div class="views-title">列表视图 / 表单布局</div>
            <el-space wrap>
              <el-tag v-for="v in views" :key="v.id" size="small" type="info">
                {{ v.code }}（{{ v.columns.length }} 列，{{ v.pageSize }} 行/页）
              </el-tag>
              <el-tag v-for="f in forms" :key="f.id" size="small" type="success">
                {{ f.code }}（{{ f.fields.length }} 字段）
              </el-tag>
              <span v-if="!views.length && !forms.length" class="muted">该对象还没有视图/表单配置</span>
            </el-space>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { metaApi } from '../../api/definition'
import type { DataObjectDto, FieldDto, ListViewDto, FormLayoutDto } from '../../api/types'

const objects = ref<DataObjectDto[]>([])
const fields = ref<FieldDto[]>([])
const views = ref<ListViewDto[]>([])
const forms = ref<FormLayoutDto[]>([])
const current = ref('')
const keyword = ref('')
const loading = ref(false)

const object = computed(() => objects.value.find((o) => o.code === current.value))
const filteredObjects = computed(() => {
  const k = keyword.value.trim().toLowerCase()
  if (!k) return objects.value
  return objects.value.filter(
    (o) => o.code.toLowerCase().includes(k) || (o.name ?? '').toLowerCase().includes(k)
  )
})

const healthIssues = computed(() => {
  const issues: { level: string; text: string }[] = []
  const f = fields.value
  if (!f.length) return issues
  if (!f.some((x) => x.primaryKey)) issues.push({ level: 'warn', text: '没有主键字段：列表/保存引擎会退化' })
  if (object.value && !object.value.tenantField) {
    issues.push({ level: 'warn', text: '未声明租户字段：该对象不会受 RLS 保护' })
  }
  const noLabel = f.filter((x) => !x.displayName)
  if (noLabel.length) issues.push({ level: 'warn', text: `${noLabel.length} 个字段缺少中文显示名` })
  const lookups = f.filter((x) => x.lookupType > 0 && !x.lookupSource)
  if (lookups.length) issues.push({ level: 'warn', text: `${lookups.length} 个查找字段缺少查找源` })
  const money = f.filter((x) => /amount|price|cost|tax|money/i.test(x.fieldName))
  const badMoney = money.filter((x) => !/decimal|numeric|money/i.test(x.dataType))
  if (badMoney.length) {
    issues.push({
      level: 'error',
      text: `金额类字段用了非精确类型：${badMoney.map((x) => x.fieldName).join('、')}`
    })
  }
  return issues
})

async function select(code: string) {
  current.value = code
  loading.value = true
  try {
    const [f, v, fm] = await Promise.all([metaApi.fields(code), metaApi.views(code), metaApi.forms(code)])
    fields.value = f
    views.value = v
    forms.value = fm
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  try {
    objects.value = await metaApi.objects()
    if (objects.value.length) await select(objects.value[0].code)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
})
</script>

<style scoped>
.tip { margin-bottom: 12px; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.head-actions { display: flex; gap: 6px; }
.object-item {
  padding: 8px 10px;
  border-radius: 6px;
  cursor: pointer;
  border: 1px solid transparent;
}
.object-item:hover { background: var(--el-fill-color-light); }
.object-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.object-code { font-family: Consolas, monospace; font-size: 13px; }
.object-name { font-size: 12px; color: var(--el-text-color-secondary); margin: 2px 0 4px; }
.health { margin-top: 12px; border-top: 1px dashed var(--el-border-color); padding-top: 10px; }
.health-title, .views-title { font-weight: 600; margin-bottom: 6px; font-size: 13px; }
.health ul { margin: 0; padding-left: 18px; font-size: 12px; }
.health li { margin: 2px 0; }
.health li.error { color: var(--el-color-danger); }
.health li.warn { color: var(--el-color-warning); }
.health li.ok { color: var(--el-color-success); }
.views { margin-top: 12px; border-top: 1px dashed var(--el-border-color); padding-top: 10px; }
.muted { color: var(--el-text-color-secondary); font-size: 12px; }
</style>
