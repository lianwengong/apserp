import { reactive } from 'vue'
import { fetchMenuTree } from '../api/menu'
import type { MenuNode } from '../api/menu'

/**
 * 功能菜单树：侧边栏数据源。
 * 与数据对象目录分开：对象是“表”，菜单是“功能入口”，两者不是一一对应。
 */
const state = reactive<{
  tree: MenuNode[]
  loading: boolean
  loaded: boolean
  error: string
}>({
  tree: [],
  loading: false,
  loaded: false,
  error: ''
})

export const menus = {
  state,

  async load(force = false): Promise<void> {
    if (state.loading) return
    if (state.loaded && !force) return
    state.loading = true
    state.error = ''
    try {
      state.tree = await fetchMenuTree()
      state.loaded = true
    } catch (ex) {
      state.error = ex instanceof Error ? ex.message : '功能菜单加载失败'
    } finally {
      state.loading = false
    }
  }
}
