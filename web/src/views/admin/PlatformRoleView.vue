<script setup lang="ts">
defineOptions({ name: 'PlatformRoleView' })
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Refresh, UserFilled } from '@element-plus/icons-vue'
import {
  listPlatformPermissions,
  listPlatformRoles,
  listRoleMembers,
  savePlatformRole,
  setRoleMembers
} from '../../api/platformRole'
import type { PlatformPermission, PlatformRole } from '../../api/platformRole'
import { listPlatformAccounts } from '../../api/platformUser'
import type { PlatformAccountRow } from '../../api/platformUser'

const loading = ref(false)
const error = ref('')
const roles = ref<PlatformRole[]>([])
const permissions = ref<PlatformPermission[]>([])
const accounts = ref<PlatformAccountRow[]>([])

const editDialog = reactive({
  visible: false,
  saving: false,
  isNew: false,
  id: null as number | null,
  code: '',
  name: '',
  enabled: true,
  selected: [] as string[]
})

const memberDialog = reactive({
  visible: false,
  saving: false,
  role: null as PlatformRole | null,
  selected: [] as number[]
})

const childPermissions = (): PlatformPermission[] =>
  permissions.value.filter((p) => p.parentKey !== null)

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const [roleList, permissionList, accountList] = await Promise.all([
      listPlatformRoles(),
      listPlatformPermissions(),
      listPlatformAccounts()
    ])
    roles.value = roleList
    permissions.value = permissionList
    accounts.value = accountList
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '平台角色加载失败'
  } finally {
    loading.value = false
  }
}

function openCreate(): void {
  editDialog.isNew = true
  editDialog.id = null
  editDialog.code = ''
  editDialog.name = ''
  editDialog.enabled = true
  editDialog.selected = []
  editDialog.visible = true
}

function openEdit(role: PlatformRole): void {
  editDialog.isNew = false
  editDialog.id = role.id
  editDialog.code = role.code
  editDialog.name = role.name
  editDialog.enabled = role.enabled
  editDialog.selected = [...role.permissions]
  editDialog.visible = true
}

async function saveEdit(): Promise<void> {
  if (!editDialog.name.trim()) {
    ElMessage.warning('请填写角色名称')
    return
  }
  if (editDialog.isNew && !/^[A-Z][A-Z0-9_]{2,29}$/.test(editDialog.code.trim())) {
    ElMessage.warning('编码需为 3-30 位大写字母/数字/下划线，例如 PLAT_OPS2')
    return
  }
  editDialog.saving = true
  try {
    await savePlatformRole({
      id: editDialog.id,
      code: editDialog.isNew ? editDialog.code.trim() : undefined,
      name: editDialog.name.trim(),
      enabled: editDialog.enabled,
      permissions: editDialog.selected
    })
    ElMessage.success('角色已保存')
    editDialog.visible = false
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '保存失败')
  } finally {
    editDialog.saving = false
  }
}

async function openMembers(role: PlatformRole): Promise<void> {
  memberDialog.role = role
  memberDialog.visible = true
  memberDialog.selected = []
  try {
    memberDialog.selected = await listRoleMembers(role.id)
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '成员加载失败')
  }
}

async function saveMembers(): Promise<void> {
  if (!memberDialog.role) return
  memberDialog.saving = true
  try {
    await setRoleMembers(memberDialog.role.id, memberDialog.selected)
    ElMessage.success('成员已保存')
    memberDialog.visible = false
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '保存失败')
  } finally {
    memberDialog.saving = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <section class="card head">
      <div>
        <p class="eyebrow">PLATFORM ROLES</p>
        <h1>角色与权限</h1>
        <p class="muted sub">
          平台账号的运营权限（<code>PLAT:*</code>）：租户管理、平台账号、菜单、模块、监控、审计。
          角色变更立即生效；平台管理员（<code>PLAT_ADMIN</code>）为内置全权角色。
        </p>
      </div>
      <div class="actions">
        <el-button :loading="loading" @click="load">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button type="primary" @click="openCreate">
          <el-icon><Plus /></el-icon>
          新增角色
        </el-button>
      </div>
    </section>

    <el-alert v-if="error" type="error" :title="error" :closable="false" show-icon />

    <section class="card body">
      <el-table v-loading="loading" :data="roles" border height="100%" row-key="id">
        <el-table-column prop="name" label="角色名称" min-width="160" />
        <el-table-column prop="code" label="编码" width="150">
          <template #default="{ row }"><span class="mono">{{ row.code }}</span></template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'info'" size="small" effect="light">
              {{ row.enabled ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="权限" min-width="260">
          <template #default="{ row }">
            <div class="chips">
              <el-tag
                v-for="key in row.permissions.filter((k: string) => k !== 'PLAT')"
                :key="key"
                size="small"
                effect="plain"
              >
                {{ key }}
              </el-tag>
              <el-tag v-if="row.code === 'PLAT_ADMIN'" type="warning" size="small" effect="light">
                全部权限
              </el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="成员" width="80" align="center">
          <template #default="{ row }">{{ row.memberCount }}</template>
        </el-table-column>
        <el-table-column label="操作" width="190" align="center" fixed="right">
          <template #default="{ row }">
            <el-button text size="small" @click="openEdit(row)">权限</el-button>
            <el-button text size="small" :icon="UserFilled" @click="openMembers(row)">成员</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="还没有平台角色" :image-size="64" />
        </template>
      </el-table>
    </section>

    <el-dialog
      v-model="editDialog.visible"
      :title="editDialog.isNew ? '新增平台角色' : `编辑角色：${editDialog.name}`"
      width="560px"
      destroy-on-close
    >
      <el-form label-width="90px">
        <el-form-item v-if="editDialog.isNew" label="编码" required>
          <el-input v-model="editDialog.code" placeholder="如 PLAT_OPS2（3-30 位大写）" />
        </el-form-item>
        <el-form-item label="名称" required>
          <el-input v-model="editDialog.name" placeholder="如 平台运维" />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="editDialog.enabled" />
        </el-form-item>
        <el-form-item label="权限">
          <el-checkbox-group v-model="editDialog.selected" class="perm-group">
            <el-checkbox v-for="p in childPermissions()" :key="p.resourceKey" :value="p.resourceKey">
              <span class="perm-key">{{ p.resourceKey }}</span>
              <span class="perm-name">{{ p.name }}</span>
            </el-checkbox>
          </el-checkbox-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialog.visible = false">取消</el-button>
        <el-button type="primary" :loading="editDialog.saving" @click="saveEdit">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="memberDialog.visible" title="角色成员" width="480px">
      <p class="dialog-hint">角色：<strong>{{ memberDialog.role?.name }}</strong></p>
      <el-select v-model="memberDialog.selected" multiple filterable class="member-select" placeholder="选择平台账号">
        <el-option
          v-for="account in accounts"
          :key="account.id"
          :label="`${account.userName} · ${account.displayName || ''}`"
          :value="account.id"
        />
      </el-select>
      <p class="dialog-note muted">只能选平台账号；保存为覆盖式，未勾选的成员会被移出该角色。</p>
      <template #footer>
        <el-button @click="memberDialog.visible = false">取消</el-button>
        <el-button type="primary" :loading="memberDialog.saving" @click="saveMembers">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 14px;
  height: 100%;
  min-height: 0;
}

.head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 20px;
}

.head h1 {
  margin: 4px 0 0;
  font-size: 22px;
}

.sub {
  margin: 6px 0 0;
  font-size: 12.5px;
  max-width: 680px;
  line-height: 1.7;
}

.sub code {
  font-family: 'Cascadia Code', Consolas, monospace;
  color: var(--brand-700);
}

.actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.body {
  flex: 1;
  min-height: 260px;
  overflow: hidden;
  padding: 8px;
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.perm-group {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
}

.perm-key {
  font-family: 'Cascadia Code', Consolas, monospace;
  font-size: 12px;
  margin-right: 8px;
  color: var(--brand-700);
}

.perm-name {
  font-size: 12px;
  color: var(--ink-2);
}

.dialog-hint {
  margin: 0 0 10px;
  font-size: 13px;
}

.member-select {
  width: 100%;
}

.dialog-note {
  margin: 10px 0 0;
  font-size: 11.5px;
  line-height: 1.6;
}
</style>
