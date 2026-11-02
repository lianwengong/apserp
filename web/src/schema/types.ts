/**
 * PageSchema：页面组合层契约。
 *
 * 后端元数据负责“字段 / 视图 / 表单 / 权限”，这里负责“一个页面由哪些块组成”：
 * 列表、基础资料多页签、看板、占位页。模板只认这个契约，不再为每个业务页面手写布局。
 *
 * 约束：
 * - 只做可序列化的描述，函数/组件不进 schema（远程下发时不需要执行代码）；
 * - 所有 code 必须在 registry 里可解析，解析不到要给出明确失败，不静默白屏；
 * - 页面权限只控制“入口是否可见”，真正的数据权限仍由后端接口校验。
 */

export type PageKind = 'object' | 'tabs' | 'dashboard' | 'placeholder'

export interface PageTabSchema {
  key: string
  label: string
  icon?: string
  /** 数据对象页：直接渲染 MetaListView */
  objectCode?: string
  /** 组合页：递归解析另一个 PageSchema */
  pageCode?: string
  description?: string
}

export interface DashboardCardSchema {
  key: string
  label: string
  /** 统计该数据对象的行数；不填表示静态卡片 */
  objectCode?: string
  value?: string
  hint?: string
  icon?: string
  span?: number
  /** 点击跳转的站内路径 */
  to?: string
}

export interface DashboardShortcutSchema {
  label: string
  to: string
  icon?: string
}

export interface DashboardSchema {
  cards: DashboardCardSchema[]
  shortcuts?: DashboardShortcutSchema[]
  /** 最近对象区域展示哪些对象；为空时取卡片里的对象 */
  recentObjectCodes?: string[]
}

export interface PageSchema {
  code: string
  title: string
  kind: PageKind
  description?: string
  /** kind=object 时必填 */
  objectCode?: string
  /** kind=tabs 时必填 */
  tabs?: PageTabSchema[]
  /** kind=dashboard 时必填 */
  dashboard?: DashboardSchema
  /** 入口权限点；为空表示所有登录用户可见 */
  permissions?: string[]
}

export function isPageSchema(value: unknown): value is PageSchema {
  if (!value || typeof value !== 'object') return false
  const page = value as Partial<PageSchema>
  return (
    typeof page.code === 'string' &&
    page.code.length > 0 &&
    typeof page.title === 'string' &&
    page.title.length > 0 &&
    (page.kind === 'object' ||
      page.kind === 'tabs' ||
      page.kind === 'dashboard' ||
      page.kind === 'placeholder')
  )
}

/** 页面定义自检：注册时立刻失败，避免运行时才发现配置写错。 */
export function assertPageSchema(page: PageSchema): void {
  if (!isPageSchema(page)) {
    throw new Error('PageSchema 缺少 code/title/kind')
  }
  if (page.kind === 'object' && !page.objectCode) {
    throw new Error(`页面 ${page.code} 是 object 类型，必须配置 objectCode`)
  }
  if (page.kind === 'tabs') {
    if (!page.tabs?.length) throw new Error(`页面 ${page.code} 是 tabs 类型，必须配置至少一个页签`)
    const keys = new Set<string>()
    for (const tab of page.tabs) {
      if (!tab.key || !tab.label) throw new Error(`页面 ${page.code} 存在缺少 key/label 的页签`)
      if (keys.has(tab.key)) throw new Error(`页面 ${page.code} 的页签 key 重复：${tab.key}`)
      keys.add(tab.key)
      if (!tab.objectCode && !tab.pageCode) {
        throw new Error(`页面 ${page.code} 的页签 ${tab.key} 必须配置 objectCode 或 pageCode`)
      }
    }
  }
  if (page.kind === 'dashboard' && !page.dashboard?.cards?.length) {
    throw new Error(`页面 ${page.code} 是 dashboard 类型，必须配置 cards`)
  }
}
