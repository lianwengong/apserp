<script setup lang="ts">
defineOptions({ name: 'TenantListView' })
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Edit, Key, Plus, Refresh, SwitchButton } from '@element-plus/icons-vue'
import {
  createTenant,
  listTenants,
  resetTenantAdminPassword,
  setTenantEnabled,
  updateTenant
} from '../../api/admin'
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

// ---------------------------------------------------------------- 编辑租户（编码不可改）

const editDialog = reactive({
  visible: false,
  saving: false,
  tenant: null as TenantDto | null
})

const editForm = reactive({
  name: '',
  shortName: '',
  industry: '',
  contact: '',
  phone: '',
  maxUsers: null as number | null,
  remark: '',
  expireAt: ''
})

function openEdit(row: TenantDto): void {
  editDialog.tenant = row
  editForm.name = row.name
  editForm.shortName = row.shortName ?? ''
  editForm.industry = row.industry ?? ''
  editForm.contact = row.contact ?? ''
  editForm.phone = row.phone ?? ''
  editForm.maxUsers = row.maxUsers
  editForm.remark = row.remark ?? ''
  editForm.expireAt = row.expireAt ? row.expireAt.slice(0, 19) : ''
  editDialog.visible = true
}

async function saveEdit(): Promise<void> {
  if (!editDialog.tenant) return
  if (!editForm.name.trim()) {
    ElMessage.warning('租户名称不能为空')
    return
  }
  editDialog.saving = true
  try {
    await updateTenant(editDialog.tenant.id, {
      name: editForm.name.trim(),
      shortName: editForm.shortName.trim() || null,
      industry: editForm.industry.trim() || null,
      contact: editForm.contact.trim() || null,
      phone: editForm.phone.trim() || null,
      maxUsers: editForm.maxUsers,
      remark: editForm.remark.trim() || null,
      expireAt: editForm.expireAt || null
    })
    ElMessage.success('租户资料已保存')
    editDialog.visible = false
    await load()
  } catch (ex) {
    ElMessage.error(ex instanceof Error ? ex.message : '保存失败')
  } finally {
    editDialog.saving = false
  }
}

// ---------------------------------------------------------------- 租户管理员口令

const pwdDialog = reactive({
  visible: false,
  saving: false,
  tenant: null as TenantDto | null,
  password: ''
})

function openPassword(row: TenantDto): void {
  pwdDialog.tenant = row
  pwdDialog.password = ''
  pwdDialog.visible = true
}

const pwdValid = computed(
  () => /^(?=.*[A-Za-z])(?=.*\d).{8,64}$/.test(pwdDialog.password)
)

async function savePassword(): Promise<void> {
  if (!pwdDialog.tenant || !pwdValid.value) return
  pwdDialog.saving = true
  try {
    const result = await resetTenantAdminPassword(pwdDialog.tenant.id, pwdDialog.password)
    ElMessage.success(`已重置管理员 ${result.userName} 的口令，下次登录需改密`)
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
        <el-table-column prop="shortName" label="简称" width="110">
          <template #default="{ row }">{{ row.shortName || '—' }}</template>
        </el-table-column>
        <el-table-column prop="industry" label="行业" width="120">
          <template #default="{ row }">{{ row.industry || '—' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'info'" size="small" effect="light">
              {{ row.enabled ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="150">
          <template #default="{ row }">{{ row.createdAt ? formatDateTime(row.createdAt) : '—' }}</template>
        </el-table-column>
        <el-table-column label="到期时间" width="150">
          <template #default="{ row }">{{ row.expireAt ? formatDateTime(row.expireAt) : '—' }}</template>
        </el-table-column>
        <el-table-column label="管理员" width="90">
          <template #default="{ row }">
            <span class="mono">{{ row.adminUserName || '—' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="240" align="center" fixed="right">
          <template #default="{ row }">
            <el-button text :icon="Edit" @click="openEdit(row)">编辑</el-button>
            <el-button text :icon="Key" @click="openPassword(row)">管理员口令</el-button>
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

    <el-dialog v-model="editDialog.visible" title="编辑租户" width="560px" destroy-on-close>
      <el-form label-width="110px">
        <el-form-item label="租户编码">
          <el-input :model-value="editDialog.tenant?.code" disabled />
          <p class="field-hint">编码是唯一标识，创建后不可修改</p>
        </el-form-item>
        <el-form-item label="租户名称" required>
          <el-input v-model="editForm.name" placeholder="如 杭州示例贸易有限公司" />
        </el-form-item>
        <el-form-item label="简称">
          <el-input v-model="editForm.shortName" placeholder="可选" />
        </el-form-item>
        <el-form-item label="行业">
          <el-input v-model="editForm.industry" placeholder="可选，如 批发 / 零售" />
        </el-form-item>
        <el-form-item label="联系人">
          <el-input v-model="editForm.contact" placeholder="可选" />
        </el-form-item>
        <el-form-item label="联系电话">
          <el-input v-model="editForm.phone" placeholder="可选" />
        </el-form-item>
        <el-form-item label="用户上限">
          <el-input-number v-model="editForm.maxUsers" :min="0" :step="10" controls-position="right" />
          <p class="field-hint">留空表示不限制</p>
        </el-form-item>
        <el-form-item label="到期时间">
          <el-date-picker
            v-model="editForm.expireAt"
            type="datetime"
            value-format="YYYY-MM-DDTHH:mm:ss"
            placeholder="留空表示不过期"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="editForm.remark" type="textarea" :rows="2" placeholder="可选" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialog.visible = false">取消</el-button>
        <el-button type="primary" :loading="editDialog.saving" @click="saveEdit">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="pwdDialog.visible" title="维护租户管理员口令" width="460px">
      <p class="dialog-hint">
        {{ pwdDialog.tenant?.code }} · 管理员
        <strong>{{ pwdDialog.tenant?.adminUserName || '（无）' }}</strong>
      </p>
      <el-input
        v-model="pwdDialog.password"
        type="password"
        show-password
        placeholder="新口令 8-64 位，含字母与数字"
      />
      <p class="dialog-note muted">
        重置后该账号下次登录会被强制改密，同时清除失败计数与锁定。
        租户若还没有管理员账号，重置时会自动补建 admin 并绑定系统管理员角色。
      </p>
      <template #footer>
        <el-button @click="pwdDialog.visible = false">取消</el-button>
        <el-button type="primary" :disabled="!pwdValid" :loading="pwdDialog.saving" @click="savePassword">
          重置
        </el-button>
      </template>
    </el-dialog>

    <section class="card note">
      <strong>说明</strong>
      <span>
        开通 = 建租户 + 从当前租户克隆元数据（模块/菜单/页面/权限/角色/数据对象/编码规则/字典）+
        建租户管理员（绑定克隆出的 SYSADMIN，首次登录强制改密）。
        停用只改 <code>plat.Tenant.IsEnabled</code>，是可逆操作；平台账号归属「平台运营」保留租户，与业务租户解绑。
      </span>
    </section>
  </div>
</template>

<style scoped>
.field-hint {
  margin: 2px 0 0;
  font-size: 11px;
  color: var(--muted);
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
