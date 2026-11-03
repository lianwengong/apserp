import { reactive } from 'vue'
import { listObjects } from '../api/meta'
import type { DataObjectDto } from '../api/types'

/**
 * 数据对象目录：侧边栏菜单、工作台卡片、面包屑都从这里取。
 * 一次会话只拉一次，避免每个页面各自请求 /api/meta/objects。
 *
 * <p>切租户/重新登录后必须清空：对象目录是按租户隔离的，
 * 复用上一个会话的目录会让侧边栏「看起来少东西」。</p>
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

  /** 退出登录 / 切换租户时清空。 */
  reset(): void {
    state.objects = []
    state.loaded = false
    state.error = ''
    state.loading = false
  },

  byCode(code: string): DataObjectDto | undefined {
    return state.objects.find((o) => o.code === code)
  }
}
