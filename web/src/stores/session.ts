import { computed, reactive } from 'vue'
import { getToken, setToken } from '../api/http'
import { me } from '../api/perm'
import type { LoginResult } from '../api/types'

const USER_KEY = 'aschain.user'
const TENANT_KEY = 'aschain.tenant'
/** 会话入口：1 平台管理 / 2 业务管理（刷新页面后仍要知道自己在哪个入口） */
const APP_KEY = 'aschain.app'

export interface SessionUser {
  userId: number
  tenantId: number
  tenantCode: string
  /** 租户名称：顶栏显示它，编码只在需要精确指代时出现 */
  tenantName: string
  displayName: string
  platformAdmin: boolean
  /** 首次登录未改密：前端据此强制弹改密框 */
  mustChangePassword: boolean
  resources: string[]
}

interface SessionState {
  token: string | null
  user: SessionUser | null
  /** 入口：1 平台管理 / 2 业务管理 */
  appType: number
  /** /api/perm/me 是否已加载（刷新页面后需要重新拉一次） */
  loaded: boolean
}

function readUser(): SessionUser | null {
  try {
    const raw = localStorage.getItem(USER_KEY)
    return raw ? (JSON.parse(raw) as SessionUser) : null
  } catch {
    return null
  }
}

function readApp(): number {
  return Number(localStorage.getItem(APP_KEY)) === 1 ? 1 : 2
}

const state = reactive<SessionState>({
  token: getToken(),
  user: readUser(),
  appType: readApp(),
  loaded: false
})

function persistUser(user: SessionUser | null): void {
  state.user = user
  if (user) localStorage.setItem(USER_KEY, JSON.stringify(user))
  else localStorage.removeItem(USER_KEY)
}

export const session = {
  state,

  isAuthenticated: computed(() => state.token !== null),

  lastTenantCode: (): string => localStorage.getItem(TENANT_KEY) ?? 'T001',

  /** 登录成功后：写入 token 与基础身份，权限点随后由 loadMe 拉取。 */
  setLogin(result: LoginResult, tenantCode: string): void {
    setToken(result.token)
    state.token = result.token
    state.loaded = false
    state.appType = result.appType === 1 ? 1 : 2
    localStorage.setItem(APP_KEY, String(state.appType))
    localStorage.setItem(TENANT_KEY, tenantCode)
    persistUser({
      userId: result.userId,
      tenantId: result.tenantId,
      tenantCode,
      tenantName: '',
      displayName: result.displayName,
      platformAdmin: false,
      mustChangePassword: result.mustChangePassword,
      resources: []
    })
  },

  /** 拉取权限视图：平台管理员（租户 SYSADMIN）服务端直通，前端视为拥有一切权限。 */
  async loadMe(): Promise<void> {
    const result = await me()
    const base = state.user
    persistUser({
      userId: result.userId,
      tenantId: result.tenantId,
      tenantCode: result.tenantCode || base?.tenantCode || '',
      tenantName: result.tenantName || base?.tenantName || '',
      displayName: base?.displayName ?? '',
      platformAdmin: result.platformAdmin,
      mustChangePassword: base?.mustChangePassword ?? false,
      resources: result.resources
    })
    state.loaded = true
  },

  /** 当前入口：1 平台管理 / 2 业务管理 */
  appType: computed(() => state.appType),

  /** 切换入口需要重新登录：清会话并把目标入口带回登录页 */
  switchApp(target: number): string {
    const next = target === 1 ? 1 : 2
    setToken(null)
    state.token = null
    state.loaded = false
    state.appType = next
    localStorage.setItem(APP_KEY, String(next))
    persistUser(null)
    return '/login?app=' + next
  },

  logout(): void {
    setToken(null)
    state.token = null
    state.loaded = false
    persistUser(null)
  },

  /** 是否拥有某个权限点（如 DATA:md.brand）。平台管理员直通。 */
  has(resource: string): boolean {
    const user = state.user
    if (!user) return false
    if (user.platformAdmin) return true
    return user.resources.includes(resource)
  }
}
