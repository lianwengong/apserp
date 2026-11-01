<script setup lang="ts">
import { computed, onMounted, reactive } from 'vue'
import type { Component } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowRight, FolderOpened, Grid, Key, User } from '@element-plus/icons-vue'
import { catalog } from '../stores/catalog'
import { session } from '../stores/session'
import { listRows } from '../api/meta'
import { groupOf } from '../utils/schema'
import { formatNumber, greeting, todayText } from '../utils/format'

const router = useRouter()
const counts = reactive<Record<string, number | null>>({})

const user = computed(() => session.state.user)
const objects = computed(() => catalog.state.objects)
const firstObject = computed(() => objects.value[0])

const groupCount = computed(
  () => new Set(objects.value.map((object) => groupOf(object.code).code)).size
)

const stats = computed<{ label: string; value: string | number; icon: Component }[]>(() => [
  { label: '数据对象', value: objects.value.length, icon: FolderOpened },
  { label: '业务域', value: groupCount.value, icon: Grid },
  {
    label: '可见权限点',
    value: user.value?.platformAdmin ? '全量' : (user.value?.resources.length ?? 0),
    icon: Key
  },
  { label: '登录账号', value: user.value?.displayName || '—', icon: User }
])

onMounted(async () => {
  await catalog.load()
  void loadCounts()
})

async function loadCounts(): Promise<void> {
  const list = objects.value.slice(0, 16)
  await Promise.all(
    list.map(async (object) => {
      try {
        const result = await listRows(object.code, { page: 1, size: 1 })
        counts[object.code] = result.total
      } catch {
        counts[object.code] = null
      }
    })
  )
}

function refresh(): void {
  void catalog.load(true).then(() => loadCounts())
}

function openObject(code: string): void {
  void router.push({ name: 'object', params: { code } })
}
</script>

<template>
  <div class="home">
    <section class="hero card">
      <div class="hero-copy">
        <p class="eyebrow">工作台</p>
        <h1>{{ greeting() }}，{{ user?.displayName || '同事' }}</h1>
        <p class="hero-meta muted">{{ todayText() }} · 租户 {{ user?.tenantCode }}</p>
        <p class="hero-line">
          所有页面由元数据生成：选择数据对象进入列表，字段、视图、字段权限均取自后端配置。
        </p>
      </div>
      <div class="hero-actions">
        <el-button v-if="firstObject" type="primary" @click="openObject(firstObject.code)">
          打开 {{ firstObject.name }}
          <el-icon><ArrowRight /></el-icon>
        </el-button>
        <el-button @click="refresh">刷新目录</el-button>
      </div>
    </section>

    <section class="stats">
      <div v-for="item in stats" :key="item.label" class="stat card">
        <span class="stat-icon"><el-icon><component :is="item.icon" /></el-icon></span>
        <span class="stat-body">
          <span class="stat-value">{{ item.value }}</span>
          <span class="stat-label">{{ item.label }}</span>
        </span>
      </div>
    </section>

    <section class="columns">
      <div class="card objects">
        <header class="section-head">
          <h2>数据对象</h2>
          <span class="muted">共 {{ objects.length }} 个 · 点击进入列表</span>
        </header>

        <div v-if="catalog.state.loading" class="section-body">
          <el-skeleton :rows="3" animated />
        </div>
        <div v-else-if="catalog.state.error" class="section-body">
          <el-alert type="error" :title="catalog.state.error" :closable="false" show-icon />
        </div>
        <div v-else-if="!objects.length" class="section-body">
          <el-empty description="当前租户还没有配置数据对象" :image-size="72" />
        </div>
        <div v-else class="object-grid">
          <button
            v-for="object in objects"
            :key="object.code"
            type="button"
            class="object-card"
            @click="openObject(object.code)"
          >
            <span class="obj-icon">
              <el-icon><component :is="groupOf(object.code).icon" /></el-icon>
            </span>
            <span class="obj-main">
              <span class="obj-name">{{ object.name }}</span>
              <span class="obj-code mono">{{ object.code }}</span>
            </span>
            <span class="obj-side">
              <span class="obj-group">{{ groupOf(object.code).label }}</span>
              <span class="obj-count">
                {{ counts[object.code] === null || counts[object.code] === undefined ? '—' : `${formatNumber(counts[object.code], 0)} 条` }}
              </span>
            </span>
            <el-icon class="obj-arrow"><ArrowRight /></el-icon>
          </button>
        </div>
      </div>

      <aside class="side">
        <div class="card side-card">
          <header class="section-head">
            <h2>平台能力</h2>
          </header>
          <ul class="capabilities">
            <li>
              <strong>元数据驱动</strong>
              <span>列表与表单按对象、视图、布局定义渲染，新增对象不用改前端代码。</span>
            </li>
            <li>
              <strong>多租户隔离</strong>
              <span>连接级 SESSION_CONTEXT + 行级安全 RLS，租户之间互不可见。</span>
            </li>
            <li>
              <strong>字段级权限</strong>
              <span>不可见字段不下发，只读字段前端禁用，服务端仍二次校验。</span>
            </li>
            <li>
              <strong>审计留痕</strong>
              <span>保存走统一引擎，自动写 AuditLog，谁改了什么可追溯。</span>
            </li>
          </ul>
        </div>

        <div class="card side-card">
          <header class="section-head">
            <h2>当前会话</h2>
          </header>
          <dl class="session-list">
            <div>
              <dt>用户</dt>
              <dd>{{ user?.displayName || '—' }}</dd>
            </div>
            <div>
              <dt>租户</dt>
              <dd>{{ user?.tenantCode }}（#{{ user?.tenantId }}）</dd>
            </div>
            <div>
              <dt>权限</dt>
              <dd>{{ user?.platformAdmin ? '平台管理员 · 全量' : `${user?.resources.length ?? 0} 个权限点` }}</dd>
            </div>
          </dl>
        </div>
      </aside>
    </section>
  </div>
</template>

<style scoped>
.home {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding-bottom: 8px;
}

/* ---------------------------------------------------------------- Hero */

.hero {
  display: flex;
  align-items: flex-end;
  gap: 24px;
  padding: 22px 24px;
  background:
    radial-gradient(600px 200px at 0% 0%, rgba(31, 122, 92, 0.08), transparent 70%),
    #fff;
}

.hero-copy {
  flex: 1;
  min-width: 0;
}

.hero h1 {
  margin-top: 4px;
  font-size: 24px;
  letter-spacing: -0.02em;
}

.hero-meta {
  margin: 6px 0 0;
  font-size: 12px;
}

.hero-line {
  margin: 12px 0 0;
  font-size: 12.5px;
  color: #5b6d7f;
  max-width: 640px;
  line-height: 1.7;
}

.hero-actions {
  display: flex;
  gap: 8px;
  flex: 0 0 auto;
}

/* ---------------------------------------------------------------- 统计 */

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
  letter-spacing: -0.02em;
  color: var(--ink);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.stat-label {
  font-size: 11.5px;
  color: var(--muted);
}

/* ---------------------------------------------------------------- 两栏 */

.columns {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 300px;
  gap: 14px;
  align-items: start;
}

.objects {
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

.section-body {
  padding: 8px 0 16px;
}

.object-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 10px;
}

.object-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 11px 12px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: #fff;
  cursor: pointer;
  text-align: left;
  transition: border-color 0.12s ease, box-shadow 0.12s ease, transform 0.12s ease;
}

.object-card:hover {
  border-color: var(--brand-100);
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}

.obj-icon {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: #f2f7f4;
  color: var(--brand);
  flex: 0 0 auto;
}

.obj-main {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
  min-width: 0;
}

.obj-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.obj-code {
  font-size: 10.5px;
  color: var(--muted);
}

.obj-side {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 3px;
  flex: 0 0 auto;
}

.obj-group {
  font-size: 10.5px;
  color: #8b99a7;
}

.obj-count {
  font-size: 11px;
  color: var(--ink-2);
  font-variant-numeric: tabular-nums;
}

.obj-arrow {
  color: #b3bfcb;
  font-size: 12px;
  flex: 0 0 auto;
}

/* ---------------------------------------------------------------- 侧栏 */

.side {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.side-card {
  padding: 16px 18px;
}

.capabilities {
  margin: 0;
  padding: 0;
  list-style: none;
  display: grid;
  gap: 12px;
}

.capabilities li {
  display: grid;
  gap: 2px;
  padding-left: 10px;
  border-left: 2px solid var(--brand-100);
}

.capabilities strong {
  font-size: 12.5px;
  color: var(--ink);
}

.capabilities span {
  font-size: 11.5px;
  color: var(--muted);
  line-height: 1.6;
}

.session-list {
  margin: 0;
  display: grid;
  gap: 9px;
}

.session-list div {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 12px;
}

.session-list dt {
  color: var(--muted);
}

.session-list dd {
  margin: 0;
  color: var(--ink-2);
  text-align: right;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

@media (max-width: 1100px) {
  .stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .columns {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
