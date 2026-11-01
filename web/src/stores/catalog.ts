import { reactive } from 'vue'
import { listObjects } from '../api/meta'
import type { DataObjectDto } from '../api/types'

/**
 * 数据对象目录：侧边栏菜单、工作台卡片、面包屑都从这里取。
 * 一次会话只拉一次，避免每个页面各自请求 /api/meta/objects。
 */
const state = reactive<{ objects: DataObjectDto[]; loading: boolean; loaded: boolean; error: string }>({
  objects: [],
  loading: false,
  loaded: false,
  error: ''
})

export const catalog = {
  state,

  async load(force = false): Promise<void> {
    if (state.loading) return
    if (state.loaded && !force) return
    state.loading = true
    state.error = ''
    try {
      state.objects = await listObjects()
      state.loaded = true
    } catch (ex) {
      state.error = ex instanceof Error ? ex.message : '数据对象加载失败'
    } finally {
      state.loading = false
    }
  },

  byCode(code: string): DataObjectDto | undefined {
    return state.objects.find((o) => o.code === code)
  }
}
