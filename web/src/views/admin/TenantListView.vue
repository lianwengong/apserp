<script setup lang="ts">
defineOptions({ name: 'TenantListView' })
import { onMounted, ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { listTenants } from '../../api/admin'
import type { TenantDto } from '../../api/admin'
import { formatDateTime } from '../../utils/format'

const loading = ref(false)
const error = ref('')
const tenants = ref<TenantDto[]>([])

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

onMounted(load)
</script>

<template>
  <div class="page">
    <section class="card head">
      <div>
        <p class="eyebrow">TENANTS</p>
        <h1>租户管理</h1>
        <p class="muted sub">平台内租户清单（只读）；开通/停用走平台管理接口或租户开通向导。</p>
      </div>
      <el-button :loading="loading" @click="load">
        <el-icon><Refresh /></el-icon>
        刷新
      </el-button>
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
        <template #empty>
          <el-empty description="没有租户数据" :image-size="64" />
        </template>
      </el-table>
    </section>

    <section class="card note">
      <strong>说明</strong>
      <span>
        当前页面只做平台管理员视角的租户查看。开通租户已有后端接口
        <code>POST /api/admin/tenants/{id}/provision</code>（从模板租户复制元数据），
        前端开通向导与停用/到期管理还未接入。
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
