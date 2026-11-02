import { computed, reactive } from 'vue'

export interface TabItem {
  /** 路由 path（不含 query），作为页签唯一键 */
  key: string
  label: string
  closable: boolean
  /** 数据对象 tab 存对象编码，标题随目录加载实时取中文名 */
  code?: string
  /** keep-alive 的组件名；没有 name 的页面不缓存 */
  cacheName?: string
}

const STORAGE_KEY = 'aschain.tabs.v2'
const HOME: TabItem = { key: '/', label: '工作台', closable: false, cacheName: 'DashboardView' }

function read(): TabItem[] {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY)
    if (!raw) return [{ ...HOME }]
    const parsed = JSON.parse(raw) as unknown
    if (!Array.isArray(parsed)) return [{ ...HOME }]
    const tabs = parsed.filter((item): item is TabItem => {
      if (!item || typeof item !== 'object') return false
      const tab = item as Partial<TabItem>
      return typeof tab.key === 'string' && typeof tab.label === 'string'
    })
    if (!tabs.some((tab) => tab.key === HOME.key)) tabs.unshift({ ...HOME })
    const home = tabs.find((tab) => tab.key === HOME.key)
    if (home) {
      home.label = HOME.label
      home.closable = false
      home.cacheName = HOME.cacheName
    }
    return tabs
  } catch {
    return [{ ...HOME }]
  }
}

const state = reactive<{ tabs: TabItem[]; cached: string[] }>({
  tabs: read(),
  cached: []
})

function rebuildCache(): void {
  state.cached = [...new Set(state.tabs.map((tab) => tab.cacheName).filter((name): name is string => Boolean(name)))]
}

rebuildCache()

function persist(): void {
  try {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state.tabs))
  } catch {
    // 隐私模式/配额满时不影响使用
  }
}

function add(tab: TabItem): void {
  const existing = state.tabs.find((item) => item.key === tab.key)
  if (existing) {
    existing.label = tab.label || existing.label
    existing.code = tab.code ?? existing.code
    existing.cacheName = tab.cacheName ?? existing.cacheName
  } else {
    state.tabs.push({
      ...tab,
      closable: tab.key === HOME.key ? false : tab.closable
    })
  }
  rebuildCache()
  persist()
}

function remove(key: string): string | null {
  const index = state.tabs.findIndex((tab) => tab.key === key)
  if (index < 0) return null
  const removed = state.tabs[index]
  if (!removed?.closable) return null
  state.tabs.splice(index, 1)
  rebuildCache()
  persist()
  const next = state.tabs[index] ?? state.tabs[index - 1]
  return next?.key ?? HOME.key
}

function removeOthers(key: string): void {
  state.tabs = state.tabs.filter((tab) => tab.key === key || !tab.closable)
  rebuildCache()
  persist()
}

function closeAll(): string {
  state.tabs = state.tabs.filter((tab) => !tab.closable)
  rebuildCache()
  persist()
  return state.tabs[0]?.key ?? HOME.key
}

function setTitle(key: string, label: string): void {
  const tab = state.tabs.find((item) => item.key === key)
  if (tab && label && tab.label !== label) {
    tab.label = label
    persist()
  }
}

function reset(): void {
  state.tabs = [{ ...HOME }]
  state.cached = []
  sessionStorage.removeItem(STORAGE_KEY)
}

const tabCount = computed(() => state.tabs.length)

export const tabsStore = {
  state,
  tabCount,
  add,
  remove,
  removeOthers,
  closeAll,
  setTitle,
  reset
}
