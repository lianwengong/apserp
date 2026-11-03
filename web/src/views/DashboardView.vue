<script setup lang="ts">
import { computed, onActivated, onMounted, reactive, ref } from 'vue'
import type { Component } from 'vue'
import { useRouter } from 'vue-router'
import {
  ArrowRight,
  Switch,
  Coin,
  Files,
  Grid,
  OfficeBuilding,
  PriceTag,
  Refresh,
  SetUp,
  User
} from '@element-plus/icons-vue'
import { catalog } from '../stores/catalog'
import { session } from '../stores/session'
import { menus } from '../stores/menu'
import { listRows } from '../api/meta'
import type { PageSchema } from '../schema/types'
import { workbenchPage } from '../schema/pages'
import { loadPage } from '../schema/loader'
import { countMenus } from '../utils/menu'
import { formatNumber, greeting, todayText } from '../utils/format'

const props = defineProps<{ schema?: PageSchema }>()

defineOptions({ name: 'DashboardView' })

const router = useRouter()
const remoteSchema = ref<PageSchema | null>(null)
const schema = computed(() => props.schema ?? remoteSchema.value ?? workbenchPage)
const cards = computed(() => schema.value.dashboard?.cards ?? [])
const shortcuts = computed(() => schema.value.dashboard?.shortcuts ?? [])
const counts = reactive<Record<string, number | null>>({})
const loading = ref(false)

const iconMap: Record<string, Component> = {
  PriceTag,
  User,
  OfficeBuilding,
  Grid,
  Files,
  SetUp,
  Coin
}

function iconOf(name: string | undefined): Component {
  return (name && iconMap[name]) || Grid
}

const user = computed(() => session.state.user)
const objectMap = computed(() => new Map(catalog.state.objects.map((item) => [item.code, item])))
const menuTotal = computed(() => countMenus(menus.state.tree))

const recentCodes = computed(() => {
  const configured = schema.value.dashboard?.recentObjectCodes
  if (configured?.length) return configured
  return cards.value.map((card) => card.objectCode).filter((code): code is string => Boolean(code))
})

const recentObjects = computed(() =>
  recentCodes.value
    .map((code) => objectMap.value.get(code))
    .filter((item): item is NonNullable<typeof item> => Boolean(item))
)

const maxCount = computed(() => {
  const values = Object.values(counts).filter((value): value is number => typeof value === 'number')
  return Math.max(1, ...values)
})

function valueOf(key: string): string {
  if (key === 'menus') return formatNumber(menuTotal.value, 0)
  const card = cards.value.find((item) => item.key === key)
  const code = card?.objectCode
  if (!code) return card?.value ?? '—'
  const count = counts[code]
  return count === undefined || count === null ? '—' : formatNumber(count, 0)
}

function hintOf(key: string): string {
  const card = cards.value.find((item) => item.key === key)
  if (key === 'menus') return `${menus.state.tree.length} 个一级域`
  if (card?.hint) return card.hint
  const code = card?.objectCode
  if (!code) return ''
  return counts[code] === null ? '暂不可用' : '点击进入列表'
}

async function load(): Promise<void> {
  loading.value = true
  try {
    await Promise.all([catalog.load(), menus.load()])
    const targets = [...new Set(cards.value.map((card) => card.objectCode).filter(Boolean))] as string[]
    await Promise.all(
      targets.map(async (code) => {
        try {
          const result = await listRows(code, { page: 1, size: 1 })
          counts[code] = result.total
        } catch {
          counts[code] = null
        }
      })
    )
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  // 首页直接渲染 DashboardView，没有经过 PageView；这里同样先取远程 workbench 定义。
  if (!props.schema) {
    const remote = await loadPage('workbench')
    if (remote) remoteSchema.value = remote
  }
  await load()
})

onActivated(async () => {
  if (props.schema) return
  const remote = await loadPage('workbench')
  if (remote) remoteSchema.value = remote
  await load()
})

function open(to: string | undefined): void {
  if (to) void router.push(to)
}

function openCard(key: string): void {
  const card = cards.value.find((item) => item.key === key)
  if (card?.to) {
    open(card.to)
    return
  }
  if (card?.objectCode) void router.push({ name: 'object', params: { code: card.objectCode } })
}

function openObject(code: string): void {
  void router.push({ name: 'object', params: { code } })
}
</script>

<template>
  <div class="dashboard">
    <section class="hero card">
      <div class="hero-copy">
        <p class="eyebrow">工作台</p>
        <h1>{{ greeting() }}，{{ user?.displayName || '同事' }}</h1>
        <p class="hero-meta muted">
          {{ todayText() }} · 租户 {{ user?.tenantCode }} · {{ schema.title }}
        </p>
        <p class="hero-line">
          {{ schema.description || '所有页面由元数据生成；数据权限、字段权限与操作权限仍由后端校验。' }}
        </p>
      </div>
      <div class="hero-actions">
        <el-button v-if="recentObjects[0]" type="primary" @click="openObject(recentObjects[0].code)">
          打开 {{ recentObjects[0].name }}
          <el-icon><ArrowRight /></el-icon>
        </el-button>
        <el-button :loading="loading" @click="load">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
    </section>

    <section class="stats">
      <button
        v-for="card in cards"
        :key="card.key"
        type="button"
        class="stat card"
        :class="{ clickable: Boolean(card.to || card.objectCode) }"
        @click="openCard(card.key)"
      >
        <span class="stat-icon"><el-icon><component :is="iconOf(card.icon)" /></el-icon></span>
        <span class="stat-body">
          <span class="stat-value">{{ valueOf(card.key) }}</span>
          <span class="stat-label">{{ card.label }}</span>
          <span class="stat-hint">{{ hintOf(card.key) }}</span>
        </span>
      </button>
    </section>

    <section class="columns">
      <div class="card recent">
        <header class="section-head">
          <h2>基础资料</h2>
          <span class="muted">共 {{ recentObjects.length }} 个对象 · 点击进入</span>
        </header>
        <div v-if="loading" class="section-body"><el-skeleton :rows="3" animated /></div>
        <div v-else-if="!recentObjects.length" class="section-body">
          <el-empty description="当前租户还没有可展示的数据对象" :image-size="64" />
        </div>
        <div v-else class="object-list">
          <button
            v-for="object in recentObjects"
            :key="object.code"
            type="button"
            class="object-row"
            @click="openObject(object.code)"
          >
            <span class="object-main">
              <span class="object-name">{{ object.name }}</span>
              <span class="object-code mono">{{ object.code }}</span>
            </span>
            <span class="object-count">
              {{ counts[object.code] === undefined || counts[object.code] === null ? '—' : formatNumber(counts[object.code]!, 0) }} 条
            </span>
            <el-icon class="object-arrow"><ArrowRight /></el-icon>
          </button>
        </div>
      </div>

      <div class="card side">
        <header class="section-head"><h2>快捷入口</h2></header>
        <div class="shortcut-list">
          <button
            v-for="item in shortcuts"
            :key="item.to"
            type="button"
            class="shortcut"
            @click="open(item.to)"
          >
            <el-icon><component :is="iconOf(item.icon)" /></el-icon>
            <span>{{ item.label }}</span>
            <el-icon class="shortcut-arrow"><ArrowRight /></el-icon>
          </button>
        </div>
        <template v-if="user?.platformAdmin">
          <el-divider />
          <header class="section-head"><h2>去平台管理</h2></header>
          <div class="shortcut-list">
            <button type="button" class="shortcut" @click="open('/login?app=1')">
              <el-icon><Switch /></el-icon><span>切换到平台管理入口</span>
            </button>
          </div>
          <p class="side-tip">平台管理与业务管理是两个独立入口，切换需要重新登录。</p>
        </template>
      </div>
    </section>

    <section class="card distribution">
      <header class="section-head">
        <h2>数据规模</h2>
        <span class="muted">按对象行数排序</span>
      </header>
      <div v-if="loading" class="section-body"><el-skeleton :rows="3" animated /></div>
      <div v-else class="bars">
        <div v-for="object in recentObjects" :key="object.code" class="bar-row">
          <span class="bar-label">{{ object.name }}</span>
          <span class="bar-track">
            <span
              class="bar-fill"
              :style="{ width: `${Math.max(4, ((counts[object.code] ?? 0) / maxCount) * 100)}%` }"
            />
          </span>
          <span class="bar-value">
            {{ counts[object.code] === undefined || counts[object.code] === null ? '—' : formatNumber(counts[object.code]!, 0) }}
          </span>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 16px;
  min-height: 100%;
  background: var(--bg);
}

.hero {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 24px 26px;
  background: linear-gradient(120deg, var(--card) 0%, var(--brand-50) 100%);
}

.hero h1 { margin: 4px 0 6px; font-size: 26px; color: var(--ink); }
.hero-meta { margin: 0 0 8px; font-size: 12px; }
.hero-line { margin: 0; color: var(--ink-2); line-height: 1.7; max-width: 720px; }
.hero-actions { display: flex; gap: 8px; flex: 0 0 auto; }

.stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  gap: 12px;
}

.stat {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  text-align: left;
  border: 1px solid var(--line);
  cursor: default;
}
.stat.clickable { cursor: pointer; }
.stat.clickable:hover { border-color: var(--brand-400); box-shadow: var(--shadow-md); }
.stat-icon {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: var(--brand-50);
  color: var(--brand);
  font-size: 18px;
  flex: 0 0 auto;
}
.stat-body { display: flex; flex-direction: column; min-width: 0; }
.stat-value { font-size: 24px; font-weight: 650; line-height: 1.15; color: var(--ink); }
.stat-label { font-size: 12px; color: var(--ink-2); margin-top: 2px; }
.stat-hint { font-size: 11px; color: var(--muted); margin-top: 4px; }

.columns {
  display: grid;
  grid-template-columns: minmax(0, 1.6fr) minmax(260px, 0.8fr);
  gap: 12px;
}

.card.recent, .card.side, .card.distribution { padding: 0; overflow: hidden; }
.section-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 14px 16px;
  border-bottom: 1px solid var(--line);
}
.section-head h2 { font-size: 14px; }
.section-head .muted { font-size: 11px; }
.section-body { padding: 16px; }

.object-list { display: flex; flex-direction: column; }
.object-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 13px 16px;
  border: 0;
  border-bottom: 1px solid var(--line);
  background: transparent;
  text-align: left;
  cursor: pointer;
}
.object-row:last-child { border-bottom: 0; }
.object-row:hover { background: var(--brand-50); }
.object-main { display: flex; flex-direction: column; gap: 2px; flex: 1; min-width: 0; }
.object-name { font-size: 13px; color: var(--ink); }
.object-code { font-size: 11px; color: var(--muted); }
.object-count { font-size: 12px; color: var(--ink-2); }
.object-arrow { color: var(--muted); }

.side-tip { margin: 8px 2px 0; font-size: 11px; color: var(--muted); line-height: 1.6; }

.shortcut-list { display: flex; flex-direction: column; padding: 8px; }
.shortcut {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 10px 8px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--ink-2);
  text-align: left;
  cursor: pointer;
}
.shortcut:hover { background: var(--brand-50); color: var(--brand-700); }
.shortcut span { flex: 1; }
.shortcut-arrow { color: var(--muted); }

.bars { display: flex; flex-direction: column; gap: 10px; padding: 16px; }
.bar-row { display: flex; align-items: center; gap: 12px; }
.bar-label { width: 110px; font-size: 12px; color: var(--ink-2); flex: 0 0 auto; }
.bar-track { flex: 1; height: 10px; border-radius: 999px; background: var(--brand-50); overflow: hidden; }
.bar-fill { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, var(--brand-400), var(--brand)); }
.bar-value { width: 64px; text-align: right; font-size: 12px; color: var(--ink-2); }

@media (max-width: 980px) {
  .columns { grid-template-columns: 1fr; }
  .hero { flex-direction: column; align-items: flex-start; }
}
</style>
