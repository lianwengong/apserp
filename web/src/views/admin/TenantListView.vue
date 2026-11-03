<script setup lang="ts">
defineOptions({ name: 'TenantListView' })
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Refresh, SwitchButton } from '@element-plus/icons-vue'
import { createTenant, listTenants, setTenantEnabled } from '../../api/admin'
import type { TenantDto } from '../../api/admin'
import type { FormInstance, FormRules } from 'element-plus'
import { formatDateTime } from '../../utils/format'

const loading = ref(false)
const error = ref('')
const tenants = ref<TenantDto[]>([])
const saving = ref(false)
const dialogVisible = ref(false)
const formRef = ref<FormInstance>()

const form = reactive({
  code: '',
  name: '',
  shortName: '',
  industry: '',
  adminUserName: 'admin',
  adminPassword: '',
  expireAt: ''
})

const rules: FormRules = {
  code: [
    { required: true, message: '请输入租户编码', trigger: 'blur' },
    {
      pattern: /^[A-Za-z][A-Za-z0-9_]{1,19}$/,
      message: '字母开头，2-20 位字母/数字/下划线',
      trigger: 'blur'
    }
  ],
  name: [{ required: true, message: '请输入租户名称', trigger: 'blur' }],
  adminUserName: [{ required: true, message: '请输入管理员用户名', trigger: 'blur' }],
  adminPassword: [
    { required: true, message: '请输入管理员初始口令', trigger: 'blur' },
    { min: 8, max: 64, message: '长度 8-64 位', trigger: 'blur' },
    {
      pattern: /^(?=.*[A-Za-z])(?=.*\d).+$/,
      message: '必须同时包含字母与数字',
      trigger: 'blur'
    }
  ]
}

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    tenants.value = await listTenants()
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '租户列表加载失败'
  } finally {
    loading.value = false
  }
}

function openCreate(): void {
  form.code = ''
  form.name = ''
  form.shortName = ''
  form.industry = ''
  form.adminUserName = 'admin'
  form.adminPassword = ''
  form.expireAt = ''
  dialogVisible.value = true
}

async function submit(): Promise<void> {
  if (saving.value) return
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  saving.value = true
  try {
    const result = await createTenant({
      code: form.code.trim().toUpperCase(),
      name: form.name.trim(),
      shortName: form.shortName.trim() || null,
      industry: form.industry.trim() || null,
      adminUserName: form.adminUserName.trim(),
      adminPassword: form.adminPassword,
      expireAt: form.expireAt || null
    })
    const copied = Object.entries(result.provisioned)
      .map(([key, value]) => `${key} ${value}`)
      .join(' / ')
    ElMessage.success(
      `租户 ${result.code} 已开通，管理员 ${result.adminUserName}（首次登录需改密）。克隆：${copied || '—'}`
    )
    dialogVisible.value = false
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '开通失败')
  } finally {
    saving.value = false
  }
}

async function toggle(row: TenantDto): Promise<void> {
  const next = !row.enabled
  try {
    await ElMessageBox.confirm(
      next
        ? `启用后，租户「${row.name}」的用户可以重新登录。`
        : `停用后，租户「${row.name}」的所有用户将立刻无法登录；数据保留，可随时启用。`,
      next ? '启用租户' : '停用租户',
      { type: 'warning', confirmButtonText: next ? '启用' : '停用', cancelButtonText: '取消' }
    )
  } catch {
    return
  }
  try {
    await setTenantEnabled(row.id, next)
    ElMessage.success(next ? '已启用' : '已停用')
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '操作失败')
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <section class="card head">
      <div>
        <p class="eyebrow">TENANTS</p>
        <h1>租户管理</h1>
        <p class="muted sub">
          平台内租户清单。开通会从当前租户克隆元数据（菜单/角色/权限/数据对象…）并建一个租户管理员；
          停用后该租户用户立即无法登录，数据保留，可随时启用。
        </p>
      </div>
      <div class="actions">
        <el-button type="primary" @click="openCreate">
          <el-icon><Plus /></el-icon>
          开通租户
        </el-button>
        <el-button :loading="loading" @click="load">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
    </section>

    <el-alert v-if="error" type="error" :title="error" :closable="false" show-icon />

    <section class="card body">
      <el-table v-loading="loading" :data="tenants" border height="100%" row-key="id">
        <el-table-column prop="id" label="#" width="64" align="right" />
        <el-table-column prop="code" label="租户编码" width="120">
          <template #default="{ row }"><span class="mono">{{ row.code }}</span></template>
        </el-table-column>
        <el-table-column prop="name" label="租户名称" min-width="200" />
        <el-table-column prop="shortName" label="简称" width="140">
          <template #default="{ row }">{{ row.shortName || '—' }}</template>
        </el-table-column>
        <el-table-column prop="industry" label="行业" width="120">
          <template #default="{ row }">{{ row.industry || '—' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'info'" size="small" effect="light">
              {{ row.enabled ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="160">
          <template #default="{ row }">{{ row.createdAt ? formatDateTime(row.createdAt) : '—' }}</template>
        </el-table-column>
        <el-table-column label="到期时间" width="160">
          <template #default="{ row }">{{ row.expireAt ? formatDateTime(row.expireAt) : '—' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="right">
          <template #default="{ row }">
            <el-button
              text
              :type="row.enabled ? 'danger' : 'primary'"
              :icon="SwitchButton"
              @click="toggle(row)"
            >
              {{ row.enabled ? '停用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="没有租户数据" :image-size="64" />
        </template>
      </el-table>
    </section>

    <el-dialog v-model="dialogVisible" title="开通租户" width="560px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="租户编码" prop="code">
          <el-input v-model="form.code" placeholder="如 T003（字母开头，2-20 位）" />
        </el-form-item>
        <el-form-item label="租户名称" prop="name">
          <el-input v-model="form.name" placeholder="如 杭州示例贸易有限公司" />
        </el-form-item>
        <el-form-item label="简称">
          <el-input v-model="form.shortName" placeholder="可选" />
        </el-form-item>
        <el-form-item label="行业">
          <el-input v-model="form.industry" placeholder="可选，如 批发 / 零售" />
        </el-form-item>
        <el-form-item label="管理员账号" prop="adminUserName">
          <el-input v-model="form.adminUserName" placeholder="默认 admin" />
        </el-form-item>
        <el-form-item label="初始口令" prop="adminPassword">
          <el-input
            v-model="form.adminPassword"
            type="password"
            show-password
            placeholder="8-64 位，含字母与数字；首次登录需改密"
          />
        </el-form-item>
        <el-form-item label="到期时间">
          <el-date-picker
            v-model="form.expireAt"
            type="datetime"
            value-format="YYYY-MM-DDTHH:mm:ss"
            placeholder="可选，留空表示不过期"
            style="width: 100%"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="submit">开通</el-button>
      </template>
    </el-dialog>

    <section class="card note">
      <strong>说明</strong>
      <span>
        开通 = 建租户 + 从当前租户克隆元数据（模块/菜单/页面/权限/角色/数据对象/编码规则/字典）+
        建租户管理员（绑定克隆出的 SYSADMIN，首次登录强制改密）。
        停用只改 <code>plat.Tenant.IsEnabled</code>，是可逆操作；当前平台账号所属租户不能停用。
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
  max-width: 720px;
  line-height: 1.7;
}

.actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.body {
  flex: 1;
  min-height: 240px;
  overflow: hidden;
  padding: 8px;
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

.note code {
  font-family: "Cascadia Code", Consolas, monospace;
  color: var(--brand-700);
}
</style>
