<script setup lang="ts">
defineOptions({ name: 'PlatformUserView' })
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Key, Refresh, Search, SwitchButton, UserFilled } from '@element-plus/icons-vue'
import {
  listAdminRoles,
  listAdminUsers,
  resetAdminUserPassword,
  setAdminUserEnabled,
  setAdminUserRoles
} from '../../api/platformUser'
import type { AdminRole, AdminUserRow } from '../../api/platformUser'
import { listTenants } from '../../api/admin'
import type { TenantDto } from '../../api/admin'
import { formatDateTime } from '../../utils/format'

const loading = ref(false)
const error = ref('')
const rows = ref<AdminUserRow[]>([])
const total = ref(0)
const tenants = ref<TenantDto[]>([])

const query = reactive({ keyword: '', tenantId: null as number | null, page: 1, size: 20 })

const roleDialog = reactive({
  visible: false,
  user: null as AdminUserRow | null,
  roles: [] as AdminRole[],
  selected: [] as number[],
  saving: false
})

const pwdDialog = reactive({
  visible: false,
  user: null as AdminUserRow | null,
  password: '',
  saving: false
})

const pwdValid = computed(
  () => /^(?=.*[A-Za-z])(?=.*\d).{8,64}$/.test(pwdDialog.password)
)

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const result = await listAdminUsers({
      keyword: query.keyword.trim() || undefined,
      tenantId: query.tenantId,
      page: query.page,
      size: query.size
    })
    rows.value = result.items
    total.value = result.total
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '用户列表加载失败'
  } finally {
    loading.value = false
  }
}

async function search(): Promise<void> {
  query.page = 1
  await load()
}

async function toggle(row: AdminUserRow): Promise<void> {
  const next = !row.enabled
  try {
    await ElMessageBox.confirm(
      next
        ? `启用后「${row.displayName || row.userName}」可以重新登录。`
        : `停用后「${row.displayName || row.userName}」将立即无法登录；已登录的会话在令牌过期后失效。`,
      next ? '启用账号' : '停用账号',
      { type: 'warning', confirmButtonText: next ? '启用' : '停用', cancelButtonText: '取消' }
    )
  } catch {
    return
  }
  try {
    await setAdminUserEnabled(row.id, next)
    ElMessage.success(next ? '已启用' : '已停用')
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '操作失败')
  }
}

async function openRoles(row: AdminUserRow): Promise<void> {
  roleDialog.user = row
  roleDialog.roles = []
  roleDialog.selected = []
  roleDialog.visible = true
  try {
    const roles = await listAdminRoles(row.tenantId)
    roleDialog.roles = roles
    roleDialog.selected = roles
      .filter((role) => row.roles.includes(role.code))
      .map((role) => role.id)
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '角色加载失败')
  }
}

async function saveRoles(): Promise<void> {
  if (!roleDialog.user) return
  roleDialog.saving = true
  try {
    await setAdminUserRoles(roleDialog.user.id, roleDialog.selected)
    ElMessage.success('角色已保存')
    roleDialog.visible = false
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '保存失败')
  } finally {
    roleDialog.saving = false
  }
}

function openPassword(row: AdminUserRow): void {
  pwdDialog.user = row
  pwdDialog.password = ''
  pwdDialog.visible = true
}

async function savePassword(): Promise<void> {
  if (!pwdDialog.user || !pwdValid.value) return
  pwdDialog.saving = true
  try {
    await resetAdminUserPassword(pwdDialog.user.id, pwdDialog.password)
    ElMessage.success('口令已重置，对方下次登录必须改密')
    pwdDialog.visible = false
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '重置失败')
  } finally {
    pwdDialog.saving = false
  }
}

onMounted(async () => {
  try {
    tenants.value = await listTenants()
  } catch {
    // 租户列表拿不到不影响用户列表
  }
  await load()
})
</script>

<template>
  <div class="page">
    <section class="card head">
      <div>
        <p class="eyebrow">USERS</p>
        <h1>用户与权限</h1>
        <p class="muted sub">
          平台视角的跨租户登录账号：可启停账号、重置口令（强制改密）、分配角色。
          平台登录才能进入；租户内只能管自己租户的用户。
        </p>
      </div>
      <div class="filters">
        <el-select
          v-model="query.tenantId"
          placeholder="全部租户"
          clearable
          class="tenant-select"
          @change="search"
        >
          <el-option
            v-for="tenant in tenants"
            :key="tenant.id"
            :label="`${tenant.code} · ${tenant.name}`"
            :value="tenant.id"
          />
        </el-select>
        <el-input
          v-model="query.keyword"
          placeholder="用户名 / 姓名 / 手机"
          clearable
          class="search"
          @keyup.enter="search"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-button type="primary" :loading="loading" @click="search">查询</el-button>
        <el-button :loading="loading" @click="load">
          <el-icon><Refresh /></el-icon>
        </el-button>
      </div>
    </section>

    <el-alert v-if="error" type="error" :title="error" :closable="false" show-icon />

    <section class="card body">
      <el-table v-loading="loading" :data="rows" border height="100%" row-key="id">
        <el-table-column prop="tenantCode" label="租户" width="90">
          <template #default="{ row }"><span class="mono">{{ row.tenantCode }}</span></template>
        </el-table-column>
        <el-table-column prop="userName" label="用户名" width="150">
          <template #default="{ row }">
            <span class="mono">{{ row.userName }}</span>
            <el-tag v-if="row.platformAccount" size="small" type="warning" effect="plain" class="badge">
              平台
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="displayName" label="姓名" width="130">
          <template #default="{ row }">{{ row.displayName || '—' }}</template>
        </el-table-column>
        <el-table-column label="角色" min-width="160">
          <template #default="{ row }">
            <div class="roles">
              <el-tag v-for="role in row.roles" :key="role" size="small" effect="light">
                {{ role }}
              </el-tag>
              <span v-if="!row.roles.length" class="muted">未分配</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="110" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'info'" size="small" effect="light">
              {{ row.enabled ? '启用' : '停用' }}
            </el-tag>
            <el-tag v-if="row.locked" type="danger" size="small" effect="plain" class="badge">
              锁定
            </el-tag>
            <el-tag v-else-if="row.mustChangePwd" type="warning" size="small" effect="plain" class="badge">
              待改密
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="最近登录" width="160">
          <template #default="{ row }">{{ row.lastLoginAt ? formatDateTime(row.lastLoginAt) : '—' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="240" align="center" fixed="right">
          <template #default="{ row }">
            <el-button text size="small" :icon="UserFilled" @click="openRoles(row)">角色</el-button>
            <el-button text size="small" :icon="Key" @click="openPassword(row)">重置口令</el-button>
            <el-button
              text
              size="small"
              :type="row.enabled ? 'danger' : 'primary'"
              :icon="SwitchButton"
              @click="toggle(row)"
            >
              {{ row.enabled ? '停用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="没有匹配的用户" :image-size="64" />
        </template>
      </el-table>
    </section>

    <section class="card foot">
      <span class="muted">共 {{ total }} 个账号</span>
      <el-pagination
        v-model:current-page="query.page"
        :page-size="query.size"
        :total="total"
        layout="prev, pager, next"
        background
        @current-change="load"
      />
    </section>

    <el-dialog v-model="roleDialog.visible" title="分配角色" width="480px">
      <p class="dialog-hint">
        {{ roleDialog.user?.tenantCode }} · {{ roleDialog.user?.userName }}
        （{{ roleDialog.user?.displayName || '未命名' }}）
      </p>
      <el-select v-model="roleDialog.selected" multiple filterable class="role-select" placeholder="选择角色">
        <el-option
          v-for="role in roleDialog.roles"
          :key="role.id"
          :label="`${role.code} · ${role.name}`"
          :value="role.id"
        />
      </el-select>
      <p class="dialog-note muted">保存为覆盖式：勾选结果即最终角色，会清空未勾选的角色。</p>
      <template #footer>
        <el-button @click="roleDialog.visible = false">取消</el-button>
        <el-button type="primary" :loading="roleDialog.saving" @click="saveRoles">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="pwdDialog.visible" title="重置口令" width="440px">
      <p class="dialog-hint">
        {{ pwdDialog.user?.tenantCode }} · {{ pwdDialog.user?.userName }}
      </p>
      <el-input
        v-model="pwdDialog.password"
        type="password"
        show-password
        placeholder="新口令 8-64 位，含字母与数字"
      />
      <p class="dialog-note muted">重置后对方下次登录会被强制改密，同时清除失败计数与锁定。</p>
      <template #footer>
        <el-button @click="pwdDialog.visible = false">取消</el-button>
        <el-button type="primary" :disabled="!pwdValid" :loading="pwdDialog.saving" @click="savePassword">
          重置
        </el-button>
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
  max-width: 640px;
  line-height: 1.7;
}

.filters {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.tenant-select {
  width: 200px;
}

.search {
  width: 200px;
}

.body {
  flex: 1;
  min-height: 240px;
  overflow: hidden;
  padding: 8px;
}

.roles {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.badge {
  margin-left: 6px;
}

.foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  font-size: 12px;
}

.dialog-hint {
  margin: 0 0 10px;
  font-size: 13px;
  color: var(--ink);
}

.role-select {
  width: 100%;
}

.dialog-note {
  margin: 10px 0 0;
  font-size: 11.5px;
  line-height: 1.6;
}
</style>
