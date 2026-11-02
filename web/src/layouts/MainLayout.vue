<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  ArrowDown,
  Close,
  Expand,
  Fold,
  Grid,
  HomeFilled,
  Search,
  Setting,
  SwitchButton
} from '@element-plus/icons-vue'
import type { SchemaGroup } from '../utils/schema'
import { SCHEMA_GROUPS, groupOf } from '../utils/schema'
import type { DataObjectDto } from '../api/types'
import type { MenuNode } from '../api/menu'
import { catalog } from '../stores/catalog'
import { menus } from '../stores/menu'
import { session } from '../stores/session'
import { filterMenuTree, findMenuName } from '../utils/menu'
import MenuTree from '../components/MenuTree.vue'
import { runtimeApi } from '../api/runtime'

interface TabItem {
  key: string
  label: string
  /** 数据对象 tab 存对象编码，标题随目录加载实时取中文名 */
  code?: string
  closable: boolean
}

const metaVersion = ref<{ version: number; gray: boolean }>({ version: 0, gray: false })
const route = useRoute()
const router = useRouter()

// ---------------------------------------------------------------- 侧边栏

const collapsed = ref(localStorage.getItem('apserp.sidebar') === '1')

function toggleSidebar(): void {
  collapsed.value = !collapsed.value
  localStorage.setItem('apserp.sidebar', collapsed.value ? '1' : '0')
}

const groups = computed(() => {
  const buckets = new Map<string, DataObjectDto[]>()
  for (const object of catalog.state.objects) {
    const group = groupOf(object.code)
    const list = buckets.get(group.code) ?? []
    list.push(object)
    buckets.set(group.code, list)
  }
  const all: SchemaGroup[] = [...SCHEMA_GROUPS, { code: 'other', label: '其他', icon: Grid }]
  return all
    .filter((group) => buckets.has(group.code))
    .map((group) => ({ ...group, objects: buckets.get(group.code) ?? [] }))
})

const menuKeyword = ref('')
const filteredMenus = computed(() => filterMenuTree(menus.state.tree, menuKeyword.value))

onMounted(async () => {
  void catalog.load()
  void menus.load()
  try {
    metaVersion.value = await runtimeApi.metaVersion()
  } catch {
    // 版本信息拿不到不影响布局
  }
})

// ---------------------------------------------------------------- 标签页

function readTabs(): TabItem[] {
  try {
    const raw = sessionStorage.getItem('apserp.tabs')
    if (raw) {
      const parsed = JSON.parse(raw) as TabItem[]
      if (Array.isArray(parsed) && parsed.some((tab) => tab.key === '/')) return parsed
    }
  } catch {
    // 缓存损坏就回默认，不影响进入系统
  }
  return [{ key: '/', label: '工作台', closable: false }]
}

const tabs = ref<TabItem[]>(readTabs())

function saveTabs(): void {
  sessionStorage.setItem('apserp.tabs', JSON.stringify(tabs.value))
}

function currentCode(): string {
  return typeof route.params.code === 'string' ? route.params.code : ''
}

function menuName(): string {
  const queryName = route.query.name
  if (typeof queryName === 'string' && queryName) return queryName
  const code = String(route.params.code ?? '')
  return findMenuName(menus.state.tree, code) ?? (code || '功能页面')
}

function openMenu(node: MenuNode): void {
  const target = node.route
  if (!target) return
  if (target.startsWith('/m/')) {
    void router.push({
      name: 'menu-page',
      params: { code: node.code },
      query: { name: node.name, path: target }
    })
    return
  }
  const resolved = router.resolve(target)
  if (resolved.matched.length > 0 && resolved.name !== 'not-found') {
    void router.push(target)
    return
  }
  void router.push({
    name: 'menu-page',
    params: { code: node.code },
    query: { name: node.name, path: target }
  })
}

const activeKey = computed(() => (route.name === 'home' ? '/' : route.path))

function labelOf(tab: TabItem): string {
  if (tab.code) return catalog.byCode(tab.code)?.name ?? tab.code
  return tab.label
}

function ensureTab(): void {
  if (route.name === 'home') return
  if (route.name === 'object') {
    const code = currentCode()
    if (!code) return
    const existing = tabs.value.find((tab) => tab.key === route.path)
    if (existing) existing.code = code
    else tabs.value.push({ key: route.path, label: code, code, closable: true })
    saveTabs()
    return
  }
  if (route.name === 'menu-page') {
    const existing = tabs.value.find((tab) => tab.key === route.path)
    if (existing) existing.label = menuName()
    else tabs.value.push({ key: route.path, label: menuName(), closable: true })
    saveTabs()
    return
  }
  if (route.name === 'forbidden' || route.name === 'not-found') return
  if (!tabs.value.some((tab) => tab.key === route.path)) {
    tabs.value.push({ key: route.path, label: route.meta.title ?? '页面', closable: true })
    saveTabs()
  }
}

watch(() => route.fullPath, ensureTab, { immediate: true })

// 菜单树异步加载完成后，补全直接访问 /m/:code 时的 tab 标题
watch(
  () => menus.state.tree,
  () => {
    if (route.name === 'menu-page') ensureTab()
  }
)

function openTab(tab: TabItem): void {
  if (tab.key !== route.path) void router.push(tab.key)
}

function closeTab(tab: TabItem): void {
  if (!tab.closable) return
  const index = tabs.value.findIndex((item) => item.key === tab.key)
  tabs.value = tabs.value.filter((item) => item.key !== tab.key)
  saveTabs()
  if (tab.key === route.path) {
    const next = tabs.value[Math.max(index - 1, 0)] ?? tabs.value[0]
    void router.push(next ? next.key : '/')
  }
}

// ---------------------------------------------------------------- 面包屑 / 用户

const breadcrumb = computed<{ label: string; to?: string }[]>(() => {
  if (route.name === 'home') return [{ label: '工作台' }]
  if (route.name === 'object') {
    const code = currentCode()
    const object = catalog.byCode(code)
    return [
      { label: '工作台', to: '/' },
      { label: groupOf(code).label },
      { label: object?.name ?? code }
    ]
  }
  if (route.name === 'menu-page') {
    return [{ label: '工作台', to: '/' }, { label: '功能菜单' }, { label: menuName() }]
  }
  if (route.path.startsWith('/admin')) {
    return [
      { label: '工作台', to: '/' },
      { label: '平台管理' },
      { label: route.meta.title ?? '平台页面' }
    ]
  }
  return [{ label: '工作台', to: '/' }, { label: route.meta.title ?? '页面' }]
})

const user = computed(() => session.state.user)
const userInitial = computed(() => {
  const text = user.value?.displayName || user.value?.tenantCode || 'U'
  return text.slice(0, 1).toUpperCase()
})

function onUserCommand(command: string): void {
  if (command === 'logout') {
    const redirect = route.fullPath
    session.logout()
    void router.replace({ name: 'login', query: { redirect } })
  }
}
</script>

<template>
  <div class="shell">
    <aside class="sidebar" :class="{ 'is-collapsed': collapsed }">
      <div class="brand">
        <div class="logo">APS</div>
        <div v-if="!collapsed" class="brand-text">
          <strong>APS ERP</strong>
          <span>进销存 V3 · 引擎驱动</span>
        </div>
      </div>

      <el-scrollbar class="menu-scroll">
        <nav v-if="!collapsed" class="menu">
          <div class="menu-group">
            <div class="menu-group-label">
              <el-icon><Setting /></el-icon>
              <span>平台</span>
            </div>
            <router-link to="/design" class="menu-item" :class="{ active: route.path === '/design' }">
              <span class="dot" />
              <span class="item-name">设计器中心</span>
              <span class="item-code mono">design</span>
            </router-link>
            <router-link to="/workflow" class="menu-item" :class="{ active: route.path === '/workflow' }">
              <span class="dot" />
              <span class="item-name">流程中心</span>
              <span class="item-code mono">flow</span>
            </router-link>
            <router-link
              to="/system/modules"
              class="menu-item"
              :class="{ active: route.path === '/system/modules' }"
            >
              <span class="dot" />
              <span class="item-name">功能模块管理</span>
              <span class="item-code mono">module</span>
            </router-link>
            <router-link
              to="/system/menus"
              class="menu-item"
              :class="{ active: route.path === '/system/menus' }"
            >
              <span class="dot" />
              <span class="item-name">菜单设置</span>
              <span class="item-code mono">menu</span>
            </router-link>
          </div>

          <div class="menu-group">
            <div class="menu-group-label">
              <el-icon><Grid /></el-icon>
              <span>功能菜单</span>
            </div>
            <el-input
              v-model="menuKeyword"
              class="menu-search"
              size="small"
              placeholder="搜索模块 / 功能"
              clearable
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <MenuTree
              :nodes="filteredMenus"
              :current-path="route.path"
              :force-expand="menuKeyword.length > 0"
              @select="openMenu"
            />
            <div v-if="menus.state.loading" class="menu-hint">正在加载功能菜单…</div>
            <div v-else-if="menus.state.error" class="menu-hint is-error">
              {{ menus.state.error }}
            </div>
            <div v-else-if="!filteredMenus.length" class="menu-hint">
              {{ menuKeyword ? '没有匹配的功能' : '尚无功能菜单' }}
            </div>
          </div>

          <div v-for="group in groups" :key="group.code" class="menu-group">
            <div class="menu-group-label">
              <el-icon><component :is="group.icon" /></el-icon>
              <span>{{ group.label }}</span>
            </div>
            <router-link
              v-for="object in group.objects"
              :key="object.code"
              :to="{ name: 'object', params: { code: object.code } }"
              class="menu-item"
              :class="{ active: currentCode() === object.code }"
            >
              <span class="dot" />
              <span class="item-name">{{ object.name }}</span>
              <span class="item-code mono">{{ object.code.split('.')[1] }}</span>
            </router-link>
          </div>
          <div v-if="catalog.state.loading" class="menu-hint">正在加载数据对象…</div>
          <div v-else-if="catalog.state.error" class="menu-hint is-error">
            {{ catalog.state.error }}
          </div>
          <div v-else-if="!groups.length" class="menu-hint">尚未配置数据对象</div>
        </nav>

        <nav v-else class="menu is-icon-only">
          <el-tooltip content="展开功能菜单" placement="right">
            <button type="button" class="menu-item icon-only" @click="collapsed = false">
              <el-icon><Expand /></el-icon>
            </button>
          </el-tooltip>
          <el-tooltip
            v-for="object in catalog.state.objects"
            :key="object.code"
            :content="object.name"
            placement="right"
          >
            <router-link
              :to="{ name: 'object', params: { code: object.code } }"
              class="menu-item icon-only"
              :class="{ active: currentCode() === object.code }"
            >
              <el-icon><component :is="groupOf(object.code).icon" /></el-icon>
            </router-link>
          </el-tooltip>
        </nav>
      </el-scrollbar>

      <div class="sidebar-foot">
        <span v-if="!collapsed">v0.1.0 · 第一周骨架</span>
        <span v-else>v0.1</span>
      </div>
    </aside>

    <div class="workspace">
      <header class="topbar">
        <el-button
          text
          circle
          class="collapse-btn"
          :title="collapsed ? '展开菜单' : '收起菜单'"
          @click="toggleSidebar"
        >
          <el-icon>
            <Expand v-if="collapsed" />
            <Fold v-else />
          </el-icon>
        </el-button>

        <el-breadcrumb separator="/">
          <el-breadcrumb-item v-for="item in breadcrumb" :key="item.label" :to="item.to">
            {{ item.label }}
          </el-breadcrumb-item>
        </el-breadcrumb>

        <div class="spacer" />

        <el-tooltip v-if="metaVersion.gray" content="你正在使用灰度版本的元数据配置" placement="bottom">
          <el-tag size="small" type="warning" effect="dark" class="gray-tag">
            灰度 v{{ metaVersion.version }}
          </el-tag>
        </el-tooltip>
        <el-tag v-if="user" size="small" effect="plain" class="tenant-tag">
          {{ user.tenantCode }}
        </el-tag>

        <el-dropdown trigger="click" @command="onUserCommand">
          <button class="user-chip" type="button">
            <span class="avatar">{{ userInitial }}</span>
            <span class="user-name">{{ user?.displayName || '未登录' }}</span>
            <el-icon class="chev"><ArrowDown /></el-icon>
          </button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item disabled>
                <div class="user-meta">
                  <div class="user-meta-name">{{ user?.displayName }}</div>
                  <div class="muted">
                    {{ user?.tenantCode }} · 租户 #{{ user?.tenantId }} · 用户 #{{ user?.userId }}
                  </div>
                </div>
              </el-dropdown-item>
              <el-dropdown-item divided command="logout">
                <el-icon><SwitchButton /></el-icon>
                退出登录
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </header>

      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          type="button"
          class="tab"
          :class="{ active: tab.key === activeKey }"
          @click="openTab(tab)"
        >
          <el-icon class="tab-icon">
            <HomeFilled v-if="!tab.closable" />
            <Grid v-else />
          </el-icon>
          <span class="tab-label">{{ labelOf(tab) }}</span>
          <el-icon v-if="tab.closable" class="tab-close" @click.stop="closeTab(tab)">
            <Close />
          </el-icon>
        </button>
      </div>

      <main class="content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<style scoped>
.shell {
  display: flex;
  height: 100%;
  overflow: hidden;
}

/* ---------------------------------------------------------------- 侧边栏 */

.sidebar {
  display: flex;
  flex-direction: column;
  width: 228px;
  flex: 0 0 auto;
  background: linear-gradient(180deg, #16273a 0%, var(--sidebar) 55%, #0f1c2a 100%);
  color: var(--sidebar-text);
  transition: width 0.18s ease;
  z-index: 20;
}

.sidebar.is-collapsed {
  width: 64px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  height: 56px;
  padding: 0 14px;
  flex: 0 0 auto;
}

.logo {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: linear-gradient(135deg, #2fa37c, #1c6d51);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  box-shadow: 0 2px 8px rgba(31, 122, 92, 0.35);
  flex: 0 0 auto;
}

.brand-text {
  display: flex;
  flex-direction: column;
  line-height: 1.25;
  overflow: hidden;
}

.brand-text strong {
  color: #fff;
  font-size: 14px;
  letter-spacing: 0.02em;
}

.brand-text span {
  font-size: 10.5px;
  color: #8294a8;
  white-space: nowrap;
}

.menu-scroll {
  flex: 1;
  min-height: 0;
}

.menu {
  padding: 6px 10px 16px;
}

.menu-group {
  margin-top: 10px;
}

.menu-group-label {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 8px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.06em;
  color: #7e90a4;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 36px;
  padding: 0 10px;
  border-radius: 7px;
  color: var(--sidebar-text);
  font-size: 13px;
  transition: background 0.12s ease, color 0.12s ease;
}

.menu-item:hover {
  background: var(--sidebar-hover);
  color: #fff;
}

.menu-item.active {
  background: rgba(47, 163, 124, 0.16);
  color: #fff;
  box-shadow: inset 2px 0 0 #3fbf92;
}

.dot {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: #55677c;
  flex: 0 0 auto;
}

.menu-item.active .dot {
  background: #3fbf92;
}

.item-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-code {
  font-size: 10px;
  color: #63768c;
}

.menu-item.active .item-code {
  color: #7fd7b6;
}

.menu.is-icon-only {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 10px 0;
}

.menu-item.icon-only {
  justify-content: center;
  width: 40px;
  height: 40px;
  padding: 0;
}

.menu-item.icon-only .el-icon {
  font-size: 17px;
}

.menu-hint {
  padding: 12px 10px;
  font-size: 12px;
  color: #73879c;
}

.menu-hint.is-error {
  color: #e39a92;
}

.sidebar-foot {
  flex: 0 0 auto;
  padding: 10px 16px 12px;
  font-size: 10.5px;
  color: #5f7287;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
  white-space: nowrap;
  overflow: hidden;
}

/* ---------------------------------------------------------------- 顶部栏 */

.workspace {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
  background: var(--bg);
}

.gray-tag { margin-right: 6px; }
.topbar {
  display: flex;
  align-items: center;
  gap: 12px;
  height: 56px;
  padding: 0 16px;
  background: #fff;
  border-bottom: 1px solid var(--line);
  flex: 0 0 auto;
}

.collapse-btn {
  color: #5b6b7d;
}

.spacer {
  flex: 1;
}

.tenant-tag {
  color: var(--brand-700);
  border-color: var(--brand-100);
  background: var(--brand-50);
}

.user-chip {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 8px 4px 4px;
  border: 0;
  border-radius: 20px;
  background: transparent;
  cursor: pointer;
  color: var(--ink-2);
  font-size: 13px;
}

.user-chip:hover {
  background: #f4f7fa;
}

.avatar {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: linear-gradient(135deg, #2fa37c, #1c6d51);
  color: #fff;
  font-size: 12px;
  font-weight: 600;
}

.user-name {
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.chev {
  font-size: 12px;
  color: var(--muted);
}

.user-meta {
  line-height: 1.5;
  padding: 2px 0;
}

.user-meta-name {
  color: var(--ink);
  font-weight: 600;
}

.user-meta .muted {
  font-size: 11px;
}

/* ---------------------------------------------------------------- 标签页 */

.tabs {
  display: flex;
  align-items: center;
  gap: 4px;
  height: 38px;
  padding: 0 12px;
  background: #fbfcfe;
  border-bottom: 1px solid var(--line);
  overflow-x: auto;
  flex: 0 0 auto;
}

.tabs::-webkit-scrollbar {
  height: 0;
}

.tab {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 28px;
  padding: 0 10px;
  border: 1px solid transparent;
  border-radius: 7px;
  background: transparent;
  color: #5f7082;
  font-size: 12px;
  cursor: pointer;
  white-space: nowrap;
}

.tab:hover {
  background: #f0f4f8;
}

.tab.active {
  background: #fff;
  border-color: var(--line);
  color: var(--brand-700);
  box-shadow: var(--shadow-sm);
}

.tab-icon {
  font-size: 13px;
}

.tab-close {
  font-size: 11px;
  color: #9aa8b6;
  border-radius: 50%;
}

.tab-close:hover {
  color: #cf4a3e;
  background: #fdeceb;
}

/* ---------------------------------------------------------------- 内容区 */

.content {
  flex: 1;
  min-height: 0;
  overflow: auto;
  padding: 14px 16px 18px;
}

.menu-search {
  padding: 2px 4px 6px;
}

.menu-search :deep(.el-input__wrapper) {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: none;
}

.menu-search :deep(.el-input__wrapper.is-focus) {
  border-color: rgba(63, 191, 146, 0.45);
}

.menu-search :deep(.el-input__inner) {
  height: 26px;
  color: #d7e0ea;
  font-size: 12px;
}

.menu-search :deep(.el-input__inner::placeholder) {
  color: #6f8296;
}

.menu-search :deep(.el-input__prefix),
.menu-search :deep(.el-input__suffix) {
  color: #7e90a4;
}
</style>
