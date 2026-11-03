<script setup lang="ts">
defineOptions({ name: 'PlatformOverview' })
import { computed, onMounted, ref } from 'vue'
import type { Component } from 'vue'
import { useRouter } from 'vue-router'
import {
  ArrowRight,
  Connection,
  Grid,
  Lock,
  Monitor,
  OfficeBuilding,
  SetUp,
  Setting,
  User
} from '@element-plus/icons-vue'
import { designApi } from '../../api/design'
import { listTenants } from '../../api/admin'
import type { TenantDto } from '../../api/admin'
import { fetchMenuTree } from '../../api/menu'
import type { MenuNode } from '../../api/menu'
import { countMenus } from '../../utils/menu'
import { formatNumber } from '../../utils/format'

const router = useRouter()
const loading = ref(true)
const stats = ref<Record<string, number>>({})
const tenants = ref<TenantDto[]>([])
const menuTree = ref<MenuNode[]>([])
const errors = ref<string[]>([])

onMounted(async () => {
  const [overview, tenantList, menus] = await Promise.allSettled([
    designApi.overview(),
    listTenants(),
    fetchMenuTree()
  ])
  if (overview.status === 'fulfilled') stats.value = overview.value
  else errors.value.push('设计器概览加载失败')
  if (tenantList.status === 'fulfilled') tenants.value = tenantList.value
  else errors.value.push('租户列表加载失败（需要平台管理员权限）')
  if (menus.status === 'fulfilled') menuTree.value = menus.value
  else errors.value.push('菜单树加载失败')
  loading.value = false
})

const menuTotal = computed(() => countMenus(menuTree.value))
const menuRoots = computed(() => menuTree.value.length)

const cards = computed<{ label: string; value: number; hint: string; icon: Component }[]>(() => [
  { label: '租户', value: tenants.value.length, hint: '平台内租户数', icon: OfficeBuilding },
  { label: '数据对象', value: stats.value.objects ?? 0, hint: '当前租户元数据对象', icon: Grid },
  { label: '菜单项', value: menuTotal.value, hint: `${menuRoots.value} 个一级域`, icon: Setting },
  { label: '元数据版本', value: stats.value.versions ?? 0, hint: '发布版本累计', icon: SetUp }
])

interface ModuleCard {
  code: string
  name: string
  desc: string
  route: string
  icon: Component
}

const modules: ModuleCard[] = [
  {
    code: '9002',
    name: '租户与组织',
    desc: '租户开通、组织架构、用户与角色权限',
    route: '/admin/tenants',
    icon: OfficeBuilding
  },
  {
    code: '9003',
    name: '元数据设计',
    desc: '数据对象/字段、子表关系、页面表单、菜单与发布',
    route: '/design',
    icon: Grid
  },
  {
    code: '9004',
    name: '规则与流程',
    desc: '业务规则、按钮动作、审批流与流程中心',
    route: '/design?tab=approval',
    icon: Connection
  },
  {
    code: '9005',
    name: '基础配置',
    desc: '数据字典、编号规则、业务参数、消息模板',
    route: '/m/9005',
    icon: SetUp
  },
  {
    code: '9006',
    name: '安全与审计',
    desc: '操作日志、登录日志、导出审计、数据备份',
    route: '/m/9006',
    icon: Lock
  },
  {
    code: '9007',
    name: '集成与开放',
    desc: 'OpenAPI、Webhook、单点登录、第三方应用',
    route: '/m/9007',
    icon: Connection
  },
  {
    code: '9008',
    name: '运维与监控',
    desc: '任务调度、缓存、附件、系统通知',
    route: '/m/9008',
    icon: Monitor
  },
  {
    code: '9001',
    name: '用户与权限',
    desc: '登录用户、角色矩阵、字段级权限',
    route: '/design?tab=permission',
    icon: User
  }
]

function open(path: string): void {
  void router.push(path)
}
</script>

<template>
  <div class="page">
    <section class="card hero">
      <div>
        <p class="eyebrow">PLATFORM ADMIN</p>
        <h1>平台管理</h1>
        <p class="muted hero-sub">
          租户、组织/用户、元数据、规则审批、发布、配置、审计与集成的统一入口；本页仅平台管理员可见。
        </p>
      </div>
      <div class="hero-actions">
        <el-button @click="open('/design')">设计器中心</el-button>
        <el-button type="primary" @click="open('/admin/tenants')">
          租户管理
          <el-icon><ArrowRight /></el-icon>
        </el-button>
      </div>
    </section>

    <el-alert v-if="errors.length" type="warning" :closable="false" show-icon class="card">
      <template #title>部分数据加载失败</template>
      <div class="errors">
        <div v-for="item in errors" :key="item">{{ item }}</div>
      </div>
    </el-alert>

    <section class="stats">
      <div v-for="card in cards" :key="card.label" class="stat card">
        <span class="stat-icon"><el-icon><component :is="card.icon" /></el-icon></span>
        <span class="stat-body">
          <span class="stat-value">{{ loading ? '—' : formatNumber(card.value, 0) }}</span>
          <span class="stat-label">{{ card.label }} · {{ card.hint }}</span>
        </span>
      </div>
    </section>

    <section class="card modules">
      <header class="section-head">
        <h2>平台模块</h2>
        <span class="muted">点击进入对应配置页面；未开通的显示占位页</span>
      </header>
      <div class="module-grid">
        <button
          v-for="module in modules"
          :key="module.code"
          type="button"
          class="module-card"
          @click="open(module.route)"
        >
          <span class="module-icon"><el-icon><component :is="module.icon" /></el-icon></span>
          <span class="module-main">
            <span class="module-name">{{ module.name }}</span>
            <span class="module-desc">{{ module.desc }}</span>
          </span>
          <span class="module-code mono">{{ module.code }}</span>
        </button>
      </div>
    </section>

    <section class="card quick">
      <header class="section-head">
        <h2>常用入口</h2>
      </header>
      <div class="quick-links">
        <el-button text @click="open('/admin/menus')">菜单总览</el-button>
        <el-button text @click="open('/design?tab=field')">数据对象与字段</el-button>
        <el-button text @click="open('/design?tab=permission')">角色与权限</el-button>
        <el-button text @click="open('/design?tab=publish')">发布与回滚</el-button>
        <el-button text @click="open('/system/code-rules')">编号规则</el-button>
        <el-button text @click="open('/system/terminals')">终端与功能</el-button>
      </div>
    </section>
  </div>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding-bottom: 8px;
}

.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 20px;
  padding: 22px 24px;
  background:
    radial-gradient(600px 200px at 0% 0%, rgba(31, 122, 92, 0.08), transparent 70%),
    #fff;
}

.hero h1 {
  margin: 4px 0 0;
  font-size: 24px;
  letter-spacing: -0.02em;
}

.hero-sub {
  margin: 8px 0 0;
  font-size: 12.5px;
  max-width: 720px;
  line-height: 1.7;
}

.hero-actions {
  display: flex;
  gap: 8px;
  flex: 0 0 auto;
}

.errors {
  display: grid;
  gap: 2px;
  font-size: 12px;
}

.stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.stat {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
}

.stat-icon {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border-radius: 10px;
  background: var(--brand-50);
  color: var(--brand);
  font-size: 18px;
}

.stat-body {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.stat-value {
  font-size: 19px;
  font-weight: 650;
  color: var(--ink);
}

.stat-label {
  font-size: 11.5px;
  color: var(--muted);
}

.modules {
  padding: 16px 18px 18px;
}

.section-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
}

.section-head h2 {
  font-size: 14px;
}

.section-head .muted {
  font-size: 11.5px;
}

.module-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 10px;
}

.module-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: #fff;
  text-align: left;
  cursor: pointer;
  transition: border-color 0.12s ease, box-shadow 0.12s ease, transform 0.12s ease;
}

.module-card:hover {
  border-color: var(--brand-100);
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}

.module-icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex: 0 0 auto;
  border-radius: 8px;
  background: #f2f7f4;
  color: var(--brand);
  font-size: 17px;
}

.module-main {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
  flex: 1;
}

.module-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
}

.module-desc {
  font-size: 11.5px;
  color: var(--muted);
  line-height: 1.5;
}

.module-code {
  flex: 0 0 auto;
  color: #9aa8b6;
  font-size: 10.5px;
}

.quick {
  padding: 16px 18px;
}

.quick-links {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

@media (max-width: 1100px) {
  .stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
