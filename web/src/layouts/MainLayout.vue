<script setup lang="ts">
import { computed, onMounted, ref, watch, type Component } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  ArrowDown,
  Close,
  Coin,
  Expand,
  Files,
  Fold,
  Goods,
  Grid,
  HomeFilled,
  Money,
  Present,
  Search,
  Sell,
  Setting,
  Shop,
  ShoppingCart,
  SwitchButton,
  Tickets,
  TrendCharts,
  Van
} from '@element-plus/icons-vue'
import type { SchemaGroup } from '../utils/schema'
import { SCHEMA_GROUPS, groupOf } from '../utils/schema'
import type { DataObjectDto } from '../api/types'
import type { MenuNode } from '../api/menu'
import type { TreeNavGroup } from '../components/treeNav'
import { catalog } from '../stores/catalog'
import { menus } from '../stores/menu'
import { session } from '../stores/session'
import { filterMenuTree, findMenuName } from '../utils/menu'
import MenuTree from '../components/MenuTree.vue'
import TreeNavRail from '../components/TreeNavRail.vue'
import AppearanceDrawer from '../components/AppearanceDrawer.vue'
import TopNav from '../components/TopNav.vue'
import { appearance } from '../stores/appearance'
import { tabsStore, type TabItem } from '../stores/tabs'
import { resolvePage } from '../schema/registry'
import { runtimeApi } from '../api/runtime'

const metaVersion = ref<{ version: number; gray: boolean }>({ version: 0, gray: false })
const route = useRoute()
const router = useRouter()

// ---------------------------------------------------------------- 外观偏好（导航模式）

const navMode = computed(() => appearance.state.navMode)
/** 顶栏导航用的根节点：平台管理单独走侧栏/图标入口，其余业务菜单横排 */
const topNodes = computed(() => menus.state.tree.filter((node) => node.code !== '90'))

function openMenuFromTop(node: MenuNode): void {
  openMenu(node)
}

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
const platformRoot = computed(() => menus.state.tree.find((node) => node.code === '90') ?? null)
const businessMenus = computed(() =>
  filterMenuTree(
    menus.state.tree.filter((node) => node.code !== '90'),
    menuKeyword.value
  )
)

const ROOT_ICONS: Record<string, Component> = {
  '01': Goods,
  '02': ShoppingCart,
  '03': Sell,
  '04': Shop,
  '05': Present,
  '06': Tickets,
  '07': Coin,
  '08': Van,
  '09': Money,
  '10': TrendCharts
}

const RAIL_LABELS: Record<string, string> = {
  '01': '主数据',
  '02': '采购',
  '03': '销售',
  '04': '零售',
  '05': '营销',
  '06': '全渠道',
  '07': '库存',
  '08': '运输',
  '09': '财务',
  '10': '计划'
}

let syntheticId = -1000

function leafNode(name: string, route: string, code: string): MenuNode {
  return {
    id: syntheticId--,
    parentId: null,
    code,
    name,
    route,
    icon: null,
    menuType: 2,
    moduleCode: null,
    children: []
  }
}

const workbenchNodes: MenuNode[] = [
  leafNode('工作台首页', '/', 'home'),
  leafNode('我的待办', '/todo', 'todo'),
  leafNode('流程中心', '/workflow', 'workflow')
]

const treeGroups = computed<TreeNavGroup[]>(() => {
  const groups: TreeNavGroup[] = [
    {
      key: 'workbench',
      title: '工作台',
      short: '工作台',
      icon: HomeFilled,
      nodes: workbenchNodes
    }
  ]

  if (platformRoot.value) {
    groups.push({
      key: 'platform',
      title: platformRoot.value.name,
      short: '平台',
      icon: Setting,
      nodes: platformRoot.value.children
    })
  }

  for (const root of menus.state.tree.filter((node) => node.code !== '90')) {
    const nodes = root.children.length ? root.children : root.route ? [root] : []
    if (!nodes.length) continue
    groups.push({
      key: root.code,
      title: root.name,
      short: RAIL_LABELS[root.code] ?? root.name,
      icon: ROOT_ICONS[root.code] ?? Grid,
      nodes
    })
  }

  groups.push({
    key: 'master-data',
    title: '基础资料',
    short: '资料',
    icon: Files,
    nodes: catalog.state.objects.map((object) => leafNode(object.name, `/object/${object.code}`, object.code))
  })

  return groups.filter((group) => group.nodes.length > 0)
})

function openTreeNode(node: MenuNode): void {
  openMenu(node)
}

onMounted(async () => {
  void catalog.load()
  void menus.load()
  // 刷新页面时已有登录态：把服务端偏好拉回来（登录页那条路径已经在登录成功后拉过）
  void appearance.loadRemote()
  try {
    metaVersion.value = await runtimeApi.metaVersion()
  } catch {
    // 版本信息拿不到不影响布局
  }
})

// ---------------------------------------------------------------- 标签页

const tabs = computed(() => tabsStore.state.tabs)
const cached = computed(() => tabsStore.state.cached)
const appearanceVisible = ref(false)

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
  if (route.name === 'forbidden' || route.name === 'not-found') return
  if (route.name === 'home') {
    tabsStore.add({ key: '/', label: '工作台', closable: false, cacheName: 'DashboardView' })
    return
  }
  if (route.name === 'object') {
    const code = currentCode()
    if (!code) return
    tabsStore.add({
      key: route.path,
      label: code,
      code,
      closable: true,
      cacheName: 'ObjectPageView'
    })
    return
  }
  if (route.name === 'page') {
    tabsStore.add({
      key: route.path,
      label: resolvePage(currentCode())?.title ?? route.meta.title ?? '业务页面',
      closable: true,
      cacheName: 'PageView'
    })
    return
  }
  if (route.name === 'menu-page') {
    tabsStore.add({
      key: route.path,
      label: menuName(),
      closable: true,
      cacheName: 'MenuPlaceholder'
    })
    return
  }
  tabsStore.add({
    key: route.path,
    label: route.meta.title ?? '页面',
    closable: true,
    cacheName: route.meta.cacheName
  })
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
  const next = tabsStore.remove(tab.key)
  if (!next) return
  if (tab.key === route.path) void router.push(next)
}

function onTabCommand(command: string): void {
  if (command === 'others') {
    tabsStore.removeOthers(route.path)
    return
  }
  if (command === 'all') {
    void router.push(tabsStore.closeAll())
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
  if (route.name === 'page') {
    const tab = tabsStore.state.tabs.find((item) => item.key === route.path)
    return [{ label: '工作台', to: '/' }, { label: '业务页面' }, { label: tab?.label ?? '页面' }]
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
  <div class="shell" :data-nav="navMode">
    <TreeNavRail
      v-if="navMode === 'tree'"
      :groups="treeGroups"
      :current-path="route.path"
      @select="openTreeNode"
    />

    <aside
      v-show="navMode === 'side'"
      class="sidebar"
      :class="{ 'is-collapsed': collapsed }"
    >
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
              <el-icon><HomeFilled /></el-icon>
              <span>工作台</span>
            </div>
            <router-link
              to="/todo"
              class="menu-item"
              :class="{ active: route.path === '/todo' }"
            >
              <span class="dot" />
              <span class="item-name">我的待办</span>
              <span class="item-code mono">todo</span>
            </router-link>
            <router-link
              to="/workflow"
              class="menu-item"
              :class="{ active: route.path === '/workflow' }"
            >
              <span class="dot" />
              <span class="item-name">流程中心</span>
              <span class="item-code mono">flow</span>
            </router-link>
          </div>

          <div v-if="platformRoot" class="menu-group">
            <div class="menu-group-label">
              <el-icon><Setting /></el-icon>
              <span>平台管理</span>
            </div>
            <MenuTree
              :nodes="platformRoot.children"
              :current-path="route.path"
              :force-expand="false"
              @select="openMenu"
            />
          </div>

          <div class="menu-group">
            <div class="menu-group-label">
              <el-icon><Grid /></el-icon>
              <span>业务菜单</span>
            </div>
            <el-input
              v-model="menuKeyword"
              class="menu-search"
              size="small"
              placeholder="搜索业务模块 / 功能"
              clearable
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <MenuTree
              :nodes="businessMenus"
              :current-path="route.path"
              :force-expand="menuKeyword.length > 0"
              @select="openMenu"
            />
            <div v-if="menus.state.loading" class="menu-hint">正在加载业务菜单…</div>
            <div v-else-if="menus.state.error" class="menu-hint is-error">
              {{ menus.state.error }}
            </div>
            <div v-else-if="!businessMenus.length" class="menu-hint">
              {{ menuKeyword ? '没有匹配的功能' : '尚无业务菜单' }}
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
          v-if="navMode === 'side'"
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

        <el-tooltip content="外观与偏好" placement="bottom">
          <button type="button" class="icon-btn" aria-label="外观与偏好" @click="appearanceVisible = true">
            <el-icon><Setting /></el-icon>
          </button>
        </el-tooltip>

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

      <TopNav v-if="navMode === 'top'" :nodes="topNodes" :current="route.path" @select="openMenuFromTop" />

      <div class="tabs" :class="`tabs-${appearance.state.tabStyle}`">
        <div class="tabs-list">
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
        <el-dropdown trigger="click" @command="onTabCommand">
          <button type="button" class="tab-more" aria-label="页签操作">
            <el-icon><ArrowDown /></el-icon>
          </button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="others">关闭其他</el-dropdown-item>
              <el-dropdown-item command="all">关闭全部</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>

      <main class="content">
        <router-view v-slot="{ Component, route: current }">
          <keep-alive :include="cached" :max="16">
            <component :is="Component" :key="current.path" />
          </keep-alive>
        </router-view>
      </main>
    </div>

    <AppearanceDrawer v-model="appearanceVisible" />
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
  padding: 0 8px 0 12px;
  background: #fbfcfe;
  border-bottom: 1px solid var(--line);
  flex: 0 0 auto;
  overflow: hidden;
}

.tabs-list {
  display: flex;
  align-items: center;
  gap: 4px;
  flex: 1;
  min-width: 0;
  overflow-x: auto;
  scrollbar-width: none;
}

.tabs-list::-webkit-scrollbar {
  height: 0;
}

.tab-more {
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: #7d8b9a;
  cursor: pointer;
  flex: 0 0 auto;
}

.tab-more:hover {
  background: #eef2f7;
  color: var(--brand-700);
}

.icon-btn {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: #5f7082;
  cursor: pointer;
}

.icon-btn:hover {
  background: #eef2f7;
  color: var(--brand-700);
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

/* ---------------------------------------------------------------- 标签栏形态 */

/* 梯形书签：上窄下宽的书签感 */
.tabs-trapezoid .tab {
  position: relative;
  border-radius: 0;
  border: 0;
  height: 30px;
  padding: 0 16px;
  color: #5f7082;
}
.tabs-trapezoid .tab > * {
  position: relative;
  z-index: 1;
}
.tabs-trapezoid .tab::before {
  content: '';
  position: absolute;
  inset: 3px 0 0;
  background: #e6ecf3;
  clip-path: polygon(8px 0, calc(100% - 8px) 0, 100% 100%, 0 100%);
  z-index: 0;
}
.tabs-trapezoid .tab.active {
  background: transparent;
  box-shadow: none;
  color: var(--brand-700);
  font-weight: 600;
}
.tabs-trapezoid .tab.active::before {
  background: var(--card);
  box-shadow: 0 -1px 0 var(--line);
}
.tabs-trapezoid .tabs-list { align-items: flex-end; }

/* 圆角卡片：每页签一张独立小卡 */
.tabs-card .tab {
  border-radius: 12px;
  border: 1px solid var(--line);
  background: var(--card);
  box-shadow: var(--shadow-sm);
}
.tabs-card .tab.active {
  background: var(--brand);
  border-color: var(--brand);
  color: #fff;
}
.tabs-card .tab.active .tab-close,
.tabs-card .tab.active .tab-icon { color: rgba(255, 255, 255, 0.85); }

/* 直角复古：无圆角 + 细边框 + 下压效果 */
.tabs-retro .tab {
  border-radius: 0;
  border: 1px solid var(--line);
  background: #f7f9fc;
}
.tabs-retro .tab.active {
  background: var(--brand-50);
  border-color: var(--brand);
  color: var(--brand-700);
  box-shadow: inset 0 -2px 0 var(--brand);
}

/* 下划线：无背景，仅底部指示条 */
.tabs-underline .tabs-list { gap: 10px; }
.tabs-underline .tab {
  border: 0;
  border-radius: 0;
  background: transparent;
  height: 32px;
  padding: 0 2px;
}
.tabs-underline .tab:hover { background: transparent; color: var(--brand-700); }
.tabs-underline .tab.active {
  background: transparent;
  border: 0;
  box-shadow: inset 0 -2px 0 var(--brand);
  color: var(--brand-700);
  font-weight: 600;
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
