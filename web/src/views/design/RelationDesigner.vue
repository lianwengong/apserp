<template>
  <div class="relation-designer">
    <el-alert type="info" :closable="false" show-icon class="tip">
      子表设计器：声明「父对象 → 子对象」的关系。<b>别名</b>就是保存请求里的 JSON 键
      （例如 <code>Contacts</code>），前端表单按别名把明细数组一起提交，服务端在同一事务里保存主表与明细。
      外键字段必须是子对象已登记字段，子表外键与租户由服务端强制写入。
    </el-alert>

    <el-row :gutter="12">
      <el-col :span="9">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>关系列表</span>
              <el-button size="small" type="primary" @click="newRelation">新建</el-button>
            </div>
          </template>
          <el-scrollbar height="470px">
            <div
              v-for="r in relations"
              :key="r.id"
              class="relation-item"
              :class="{ active: form.id === r.id }"
              @click="edit(r)"
            >
              <div class="rel-top">
                <span class="rel-parent mono">{{ r.parentObjectCode }}</span>
                <el-tag size="small" effect="plain">{{ r.alias }}</el-tag>
                <el-tag v-if="!r.enabled" size="small" type="info">停用</el-tag>
              </div>
              <div class="rel-child">
                → <span class="mono">{{ r.childObjectCode }}</span>
                <span class="muted">（{{ r.displayName || r.childObjectName || '明细' }}）</span>
              </div>
              <div class="rel-meta">
                外键 {{ r.foreignKeyField }} · 上限 {{ r.maxRows }} 行 ·
                {{ r.cascadeDelete === 1 ? '未提交行软删除' : '不删除' }}
              </div>
            </div>
            <el-empty v-if="!relations.length" description="还没有子表关系" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="15">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>{{ editing ? '编辑关系' : '新建关系' }}</span>
              <div>
                <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
                <el-button v-if="editing" size="small" type="danger" plain @click="remove">删除</el-button>
              </div>
            </div>
          </template>

          <el-form :model="form" label-width="100px" size="small">
            <el-row :gutter="12">
              <el-col :span="12">
                <el-form-item label="父对象" required>
                  <el-select v-model="form.parentObjectCode" filterable>
                    <el-option v-for="o in objects" :key="o.code" :value="o.code" :label="`${o.code} ${o.name}`" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="子对象" required>
                  <el-select v-model="form.childObjectCode" filterable @change="loadChildFields">
                    <el-option v-for="o in objects" :key="o.code" :value="o.code" :label="`${o.code} ${o.name}`" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>
            <el-row :gutter="12">
              <el-col :span="12">
                <el-form-item label="JSON 别名" required>
                  <el-input v-model="form.alias" placeholder="Contacts" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="外键字段" required>
                  <el-select v-model="form.foreignKeyField" filterable allow-create placeholder="BrandId">
                    <el-option v-for="f in childFields" :key="f.fieldName" :value="f.fieldName" :label="`${f.fieldName}（${f.displayName}）`" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>
            <el-row :gutter="12">
              <el-col :span="10">
                <el-form-item label="显示名">
                  <el-input v-model="form.displayName" placeholder="联系人" />
                </el-form-item>
              </el-col>
              <el-col :span="7">
                <el-form-item label="排序">
                  <el-input-number v-model="form.sort" :step="10" :min="0" controls-position="right" />
                </el-form-item>
              </el-col>
              <el-col :span="7">
                <el-form-item label="行数上限">
                  <el-input-number v-model="form.maxRows" :step="50" :min="1" :max="500" controls-position="right" />
                </el-form-item>
              </el-col>
            </el-row>
            <el-row :gutter="12">
              <el-col :span="12">
                <el-form-item label="级联删除">
                  <el-select v-model="form.cascadeDelete">
                    <el-option :value="1" label="未提交的行软删除（推荐）" />
                    <el-option :value="2" label="不删除（子行只能改）" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="启用">
                  <el-switch v-model="form.enabled" />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="备注">
                  <el-input v-model="form.remark" />
                </el-form-item>
              </el-col>
            </el-row>
          </el-form>

          <el-alert
            v-if="childFields.length"
            type="success"
            :closable="false"
            show-icon
            :title="`子对象字段 ${childFields.length} 个，可作为外键的字段：${childFields.map((f) => f.fieldName).join('、')}`"
          />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { designApi, type RelationDto } from '../../api/design'
import { metaApi } from '../../api/definition'
import type { DataObjectDto, FieldDto } from '../../api/types'

const relations = ref<RelationDto[]>([])
const objects = ref<DataObjectDto[]>([])
const childFields = ref<FieldDto[]>([])
const editing = ref(false)
const saving = ref(false)

const form = reactive({
  id: null as number | null,
  parentObjectCode: '',
  childObjectCode: '',
  alias: '',
  foreignKeyField: '',
  displayName: '',
  sort: 10,
  cascadeDelete: 1,
  maxRows: 200,
  enabled: true,
  remark: ''
})

function newRelation() {
  editing.value = false
  childFields.value = []
  Object.assign(form, {
    id: null,
    parentObjectCode: '',
    childObjectCode: '',
    alias: '',
    foreignKeyField: '',
    displayName: '',
    sort: (relations.value.length + 1) * 10,
    cascadeDelete: 1,
    maxRows: 200,
    enabled: true,
    remark: ''
  })
}

function edit(r: RelationDto) {
  editing.value = true
  Object.assign(form, {
    id: r.id,
    parentObjectCode: r.parentObjectCode,
    childObjectCode: r.childObjectCode,
    alias: r.alias,
    foreignKeyField: r.foreignKeyField,
    displayName: r.displayName ?? '',
    sort: r.sort,
    cascadeDelete: r.cascadeDelete,
    maxRows: r.maxRows,
    enabled: r.enabled,
    remark: ''
  })
  void loadChildFields()
}

async function loadChildFields() {
  if (!form.childObjectCode) return
  try {
    childFields.value = await metaApi.fields(form.childObjectCode)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function load() {
  try {
    relations.value = await designApi.relations()
    objects.value = await metaApi.objects()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function save() {
  if (!form.parentObjectCode || !form.childObjectCode) return ElMessage.warning('父对象与子对象都必须选择')
  if (!form.alias.trim()) return ElMessage.warning('别名必填（它就是 JSON 键）')
  if (!form.foreignKeyField.trim()) return ElMessage.warning('外键字段必填')
  saving.value = true
  try {
    await designApi.saveRelation({ ...form, alias: form.alias.trim(), foreignKeyField: form.foreignKeyField.trim() })
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
  if (!form.id) return
  try {
    await ElMessageBox.confirm(`删除子表关系 ${form.alias}？已保存的明细数据不会被删除。`, '确认', { type: 'warning' })
    await designApi.deleteRelation(form.id)
    ElMessage.success('已删除')
    newRelation()
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

onMounted(load)
</script>

<style scoped>
.tip { margin-bottom: 12px; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.relation-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.relation-item:hover { background: var(--el-fill-color-light); }
.relation-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.rel-top { display: flex; align-items: center; gap: 8px; }
.rel-parent { font-size: 13px; font-weight: 600; }
.rel-child { font-size: 12px; margin: 2px 0; }
.rel-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.mono { font-family: Consolas, monospace; }
.muted { color: var(--el-text-color-secondary); }
</style>
