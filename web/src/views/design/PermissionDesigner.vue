<template>
  <div class="permission-designer">
    <el-row :gutter="12">
      <el-col :span="7">
        <el-card shadow="never" class="panel">
          <template #header><span>角色</span></template>
          <el-scrollbar height="500px">
            <div
              v-for="r in roles"
              :key="r.id"
              class="role-item"
              :class="{ active: roleId === r.id }"
              @click="selectRole(r.id)"
            >
              <div class="role-top">
                <span class="role-name">{{ r.name }}</span>
                <el-tag size="small" effect="plain">{{ r.code }}</el-tag>
              </div>
              <div class="role-meta">{{ r.userCount }} 人 · {{ r.enabled ? '启用' : '停用' }}</div>
            </div>
            <el-empty v-if="!roles.length" description="没有角色" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="17">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <el-tabs v-model="tab" class="tabs">
                <el-tab-pane label="资源权限" name="resource" />
                <el-tab-pane label="字段权限" name="field" />
              </el-tabs>
              <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
            </div>
          </template>

          <div v-if="!roleId" class="empty-tip">先选左侧角色</div>

          <template v-else-if="tab === 'resource'">
            <el-input v-model="resourceKeyword" size="small" placeholder="筛选资源（如 DESIGN: 或 md.brand）" clearable style="margin-bottom: 8px" />
            <el-scrollbar height="420px">
              <div v-for="group in resourceGroups" :key="group.type" class="resource-group">
                <div class="group-title">
                  {{ group.name }}
                  <el-checkbox
                    :model-value="group.allChecked"
                    :indeterminate="group.indeterminate"
                    @change="(v: boolean) => toggleGroup(group, v)"
                  >
                    全选
                  </el-checkbox>
                </div>
                <el-checkbox-group v-model="checkedResources">
                  <el-checkbox v-for="r in group.items" :key="r.key" :value="r.key" :label="r.key">
                    <span class="res-key">{{ r.key }}</span>
                    <span class="res-name">{{ r.name }}</span>
                  </el-checkbox>
                </el-checkbox-group>
              </div>
            </el-scrollbar>
          </template>

          <template v-else>
            <el-select v-model="fieldObject" size="small" filterable style="margin-bottom: 8px" @change="loadFields">
              <el-option v-for="o in objects" :key="o.code" :value="o.code" :label="`${o.code} ${o.name}`" />
            </el-select>
            <el-table :data="fieldRows" size="small" border max-height="430" empty-text="选择对象查看字段">
              <el-table-column prop="fieldName" label="字段" width="180" />
              <el-table-column prop="displayName" label="显示名" width="160" />
              <el-table-column label="访问级别" min-width="240">
                <template #default="{ row }">
                  <el-radio-group v-model="row.access" size="small">
                    <el-radio-button :value="2">可写</el-radio-button>
                    <el-radio-button :value="1">只读</el-radio-button>
                    <el-radio-button :value="0">不可见</el-radio-button>
                  </el-radio-group>
                </template>
              </el-table-column>
            </el-table>
            <div class="hint">默认全部可写；「不可见」的字段不会下发到前端，「只读」的字段返回但禁用输入。</div>
          </template>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { designApi, type RoleDto, type ResourceDto, type FieldAccessRow } from '../../api/design'
import { metaApi } from '../../api/definition'
import type { DataObjectDto } from '../../api/types'

const roles = ref<RoleDto[]>([])
const resources = ref<ResourceDto[]>([])
const objects = ref<DataObjectDto[]>([])
const roleId = ref<number | null>(null)
const checkedResources = ref<string[]>([])
const resourceKeyword = ref('')
const tab = ref<'resource' | 'field'>('resource')
const fieldObject = ref('')
const fieldRows = ref<FieldAccessRow[]>([])
const saving = ref(false)

const TYPE_NAME: Record<number, string> = { 1: '功能点', 2: '菜单', 3: '数据对象', 4: '动作', 5: '设计器' }

const filteredResources = computed(() => {
  const k = resourceKeyword.value.trim().toLowerCase()
  return k ? resources.value.filter((r) => r.key.toLowerCase().includes(k) || (r.name ?? '').toLowerCase().includes(k)) : resources.value
})

const resourceGroups = computed(() => {
  const map = new Map<string, ResourceDto[]>()
  for (const r of filteredResources.value) {
    const type = TYPE_NAME[r.type] ?? '其它'
    if (!map.has(type)) map.set(type, [])
    map.get(type)!.push(r)
  }
  return [...map.entries()].map(([type, items]) => {
    const checked = items.filter((i) => checkedResources.value.includes(i.key)).length
    return {
      type,
      name: `${type}（${items.length}）`,
      items,
      allChecked: checked === items.length && items.length > 0,
      indeterminate: checked > 0 && checked < items.length
    }
  })
})

function toggleGroup(group: { items: ResourceDto[]; allChecked: boolean }, value: boolean | string | number) {
  const keys = group.items.map((i) => i.key)
  if (value === true) {
    checkedResources.value = [...new Set([...checkedResources.value, ...keys])]
  } else {
    checkedResources.value = checkedResources.value.filter((k) => !keys.includes(k))
  }
}

async function selectRole(id: number) {
  roleId.value = id
  try {
    const m = await designApi.roleMatrix(id)
    checkedResources.value = m.grants.filter((g) => g.granted).map((g) => g.resourceKey)
    if (tab.value === 'field' && fieldObject.value) await loadFields()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function loadFields() {
  if (!roleId.value || !fieldObject.value) return
  try {
    const m = await designApi.fieldMatrix(roleId.value, fieldObject.value)
    fieldRows.value = m.fields
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function save() {
  if (!roleId.value) return
  saving.value = true
  try {
    if (tab.value === 'resource') {
      const r = await designApi.saveRoleMatrix(roleId.value, checkedResources.value)
      ElMessage.success(`已保存，授权 ${r.granted} 项`)
    } else {
      const access: Record<string, number> = {}
      for (const f of fieldRows.value) access[f.fieldName] = f.access
      const r = await designApi.saveFieldMatrix(roleId.value, fieldObject.value, access)
      ElMessage.success(`已保存，${r.saved} 个字段被收紧`)
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    roles.value = await designApi.roles()
    resources.value = await designApi.resources()
    objects.value = await metaApi.objects()
    if (objects.value.length) fieldObject.value = objects.value[0].code
    if (roles.value.length) await selectRole(roles.value[0].id)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
})
</script>

<style scoped>
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.tabs { flex: 1; }
.tabs :deep(.el-tabs__header) { margin-bottom: 0; }
.role-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.role-item:hover { background: var(--el-fill-color-light); }
.role-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.role-top { display: flex; justify-content: space-between; align-items: center; }
.role-name { font-size: 13px; font-weight: 600; }
.role-meta { font-size: 11px; color: var(--el-text-color-secondary); margin-top: 2px; }
.resource-group { margin-bottom: 12px; }
.group-title { display: flex; align-items: center; gap: 12px; font-weight: 600; font-size: 13px; margin-bottom: 4px; }
.res-key { font-family: Consolas, monospace; font-size: 12px; margin-right: 6px; }
.res-name { font-size: 12px; color: var(--el-text-color-secondary); }
.empty-tip { color: var(--el-text-color-secondary); padding: 40px 0; text-align: center; }
.hint { font-size: 11px; color: var(--el-text-color-secondary); margin-top: 6px; }
</style>
