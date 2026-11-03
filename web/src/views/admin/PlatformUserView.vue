<script setup lang="ts">
defineOptions({ name: 'PlatformUserView' })
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Key, Plus, Refresh, Search, SwitchButton } from '@element-plus/icons-vue'
import {
  createPlatformAccount,
  listPlatformAccounts,
  resetPlatformAccountPassword,
  setPlatformAccountEnabled
} from '../../api/platformUser'
import type { PlatformAccountRow } from '../../api/platformUser'
import { formatDateTime } from '../../utils/format'

const loading = ref(false)
const error = ref('')
const rows = ref<PlatformAccountRow[]>([])
const keyword = ref('')

const createDialog = reactive({
  visible: false,
  saving: false,
  userName: '',
  displayName: '',
  password: ''
})

const pwdDialog = reactive({
  visible: false,
  saving: false,
  row: null as PlatformAccountRow | null,
  password: ''
})

const passwordValid = (value: string): boolean => /^(?=.*[A-Za-z])(?=.*\d).{8,64}$/.test(value)

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    rows.value = await listPlatformAccounts(keyword.value.trim() || undefined)
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '平台账号加载失败'
  } finally {
    loading.value = false
  }
}

function openCreate(): void {
  createDialog.userName = ''
  createDialog.displayName = ''
  createDialog.password = ''
  createDialog.visible = true
}

async function submitCreate(): Promise<void> {
  if (createDialog.saving) return
  if (!/^[A-Za-z][A-Za-z0-9_.-]{1,49}$/.test(createDialog.userName.trim())) {
    ElMessage.warning('账号名只能是字母开头的 2-50 位字母/数字/下划线/点/短横线')
    return
  }
  if (!createDialog.displayName.trim()) {
    ElMessage.warning('请填写显示名称')
    return
  }
  if (!passwordValid(createDialog.password)) {
    ElMessage.warning('口令 8-64 位，必须同时包含字母与数字')
    return
  }
  createDialog.saving = true
  try {
    await createPlatformAccount({
      userName: createDialog.userName.trim(),
      displayName: createDialog.displayName.trim(),
      password: createDialog.password
    })
    ElMessage.success('平台账号已创建，首次登录需改密')
    createDialog.visible = false
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '创建失败')
  } finally {
    createDialog.saving = false
  }
}

async function toggle(row: PlatformAccountRow): Promise<void> {
  const next = !row.enabled
  try {
    await ElMessageBox.confirm(
      next
        ? `启用后「${row.displayName || row.userName}」可以登录平台管理入口。`
        : `停用后「${row.displayName || row.userName}」将无法登录平台管理入口。`,
      next ? '启用账号' : '停用账号',
      { type: 'warning', confirmButtonText: next ? '启用' : '停用', cancelButtonText: '取消' }
    )
  } catch {
    return
  }
  try {
    await setPlatformAccountEnabled(row.id, next)
    ElMessage.success(next ? '已启用' : '已停用')
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '操作失败')
  }
}

function openPassword(row: PlatformAccountRow): void {
  pwdDialog.row = row
  pwdDialog.password = ''
  pwdDialog.visible = true
}

async function submitPassword(): Promise<void> {
  if (!pwdDialog.row || !passwordValid(pwdDialog.password)) return
  pwdDialog.saving = true
  try {
    const result = await resetPlatformAccountPassword(pwdDialog.row.id, pwdDialog.password)
    ElMessage.success(`已重置 ${result.userName} 的口令，下次登录需改密`)
    pwdDialog.visible = false
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '重置失败')
  } finally {
    pwdDialog.saving = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <section class="card head">
      <div>
        <p class="eyebrow">PLATFORM ACCOUNTS</p>
        <h1>平台账号</h1>
        <p class="muted sub">
          只管理平台账号（无租户名的平台登录账号）。租户里的用户请到对应租户的用户管理里维护——
          两边分开，避免平台管理员误改客户账号。
        </p>
      </div>
      <div class="actions">
        <el-input
          v-model="keyword"
          placeholder="账号 / 显示名"
          clearable
          class="search"
          @keyup.enter="load"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-button :loading="loading" @click="load">
          <el-icon><Refresh /></el-icon>
        </el-button>
        <el-button type="primary" @click="openCreate">
          <el-icon><Plus /></el-icon>
          新增平台账号
        </el-button>
      </div>
    </section>

    <el-alert v-if="error" type="error" :title="error" :closable="false" show-icon />

    <section class="card body">
      <el-table v-loading="loading" :data="rows" border height="100%" row-key="id">
        <el-table-column prop="userName" label="账号" width="180">
          <template #default="{ row }"><span class="mono">{{ row.userName }}</span></template>
        </el-table-column>
        <el-table-column prop="displayName" label="显示名称" min-width="180">
          <template #default="{ row }">{{ row.displayName || '—' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="150" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'info'" size="small" effect="light">
              {{ row.enabled ? '启用' : '停用' }}
            </el-tag>
            <el-tag v-if="row.locked" type="danger" size="small" effect="plain" class="badge">锁定</el-tag>
            <el-tag v-else-if="row.mustChangePwd" type="warning" size="small" effect="plain" class="badge">
              待改密
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="最近登录" width="170">
          <template #default="{ row }">{{ row.lastLoginAt ? formatDateTime(row.lastLoginAt) : '—' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template #default="{ row }">
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
          <el-empty description="还没有平台账号" :image-size="64" />
        </template>
      </el-table>
    </section>

    <el-dialog v-model="createDialog.visible" title="新增平台账号" width="480px" destroy-on-close>
      <el-form label-width="96px">
        <el-form-item label="账号" required>
          <el-input v-model="createDialog.userName" placeholder="字母开头，如 ops01" />
        </el-form-item>
        <el-form-item label="显示名称" required>
          <el-input v-model="createDialog.displayName" placeholder="如 运维小王" />
        </el-form-item>
        <el-form-item label="初始口令" required>
          <el-input
            v-model="createDialog.password"
            type="password"
            show-password
            placeholder="8-64 位，含字母与数字；首次登录需改密"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createDialog.visible = false">取消</el-button>
        <el-button type="primary" :loading="createDialog.saving" @click="submitCreate">创建</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="pwdDialog.visible" title="重置平台账号口令" width="440px">
      <p class="dialog-hint">账号：<strong>{{ pwdDialog.row?.userName }}</strong></p>
      <el-input
        v-model="pwdDialog.password"
        type="password"
        show-password
        placeholder="新口令 8-64 位，含字母与数字"
      />
      <p class="dialog-note muted">重置后该账号下次登录会被强制改密，同时清除失败计数与锁定。</p>
      <template #footer>
        <el-button @click="pwdDialog.visible = false">取消</el-button>
        <el-button
          type="primary"
          :disabled="!passwordValid(pwdDialog.password)"
          :loading="pwdDialog.saving"
          @click="submitPassword"
        >
          重置
        </el-button>
      </template>
    </el-dialog>

    <section class="card note">
      <strong>说明</strong>
      <span>
        平台账号与业务租户解绑，挂在保留租户「平台运营」下，只能登录平台管理入口；
        租户管理员与租户员工在各自的租户内维护（租户管理 → 管理员口令 / 租户内用户管理）。
      </span>
    </section>
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
  max-width: 660px;
  line-height: 1.7;
}

.actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.search {
  width: 200px;
}

.body {
  flex: 1;
  min-height: 220px;
  overflow: hidden;
  padding: 8px;
}

.badge {
  margin-left: 6px;
}

.note {
  display: flex;
  gap: 10px;
  align-items: baseline;
  padding: 12px 16px;
  font-size: 12px;
  color: #5b6d7f;
  line-height: 1.7;
}

.note strong {
  color: var(--ink);
  white-space: nowrap;
}

.dialog-hint {
  margin: 0 0 10px;
  font-size: 13px;
  color: var(--ink);
}

.dialog-note {
  margin: 10px 0 0;
  font-size: 11.5px;
  line-height: 1.6;
}
</style>
