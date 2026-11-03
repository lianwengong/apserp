import { reactive } from 'vue'
import { fetchMenuTree } from '../api/menu'
import type { MenuNode } from '../api/menu'
import { session } from './session'

/**
 * 功能菜单树：侧边栏数据源。
 * 与数据对象目录分开：对象是“表”，菜单是“功能入口”，两者不是一一对应。
 *
 * <p>注意：这里的 state 是模块级的，跨登录不会自动清空。菜单内容由「入口」决定
 * （平台管理 / 业务管理），因此必须记住「这份树是给哪个入口加载的」：
 * 换了入口还复用旧树，侧边栏就会少内容，刷新后才正常——这是踩过的坑。</p>
 */
const state = reactive<{
  tree: MenuNode[]
  loading: boolean
  loaded: boolean
  /** 当前 tree 对应的入口；-1 表示未加载 */
  loadedApp: number
  error: string
}>({
  tree: [],
  loading: false,
  loaded: false,
  loadedApp: -1,
  error: ''
})

export const menus = {
  state,

  async load(force = false): Promise<void> {
    const app = session.state.appType
    // 入口变了就必须重查：菜单是按入口在服务端过滤的
    if (!force && state.loaded && state.loadedApp === app) return
    // 首次登录未改密时后端会拦掉菜单接口：这里静默跳过，
    // 否则侧边栏会挂一条「首次登录必须先修改口令」的错误提示，看起来像系统坏了
    if (session.state.user?.mustChangePassword) return
    if (state.loading) return
    state.loading = true
    state.error = ''
    try {
      state.tree = await fetchMenuTree()
      state.loaded = true
      state.loadedApp = app
    } catch (ex) {
      state.error = ex instanceof Error ? ex.message : '功能菜单加载失败'
    } finally {
      state.loading = false
    }
  },

  /** 退出登录 / 切换入口时清空，避免下个会话吃到上一份菜单树。 */
  reset(): void {
    state.tree = []
    state.loaded = false
    state.loadedApp = -1
    state.error = ''
    state.loading = false
  }
}
