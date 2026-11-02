import { computed, reactive } from 'vue'
import { getToken, setToken } from '../api/http'
import { me } from '../api/perm'
import type { LoginResult } from '../api/types'

const USER_KEY = 'aschain.user'
const TENANT_KEY = 'aschain.tenant'

export interface SessionUser {
  userId: number
  tenantId: number
  tenantCode: string
  displayName: string
  platformAdmin: boolean
  resources: string[]
}

interface SessionState {
  token: string | null
  user: SessionUser | null
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

const state = reactive<SessionState>({
  token: getToken(),
  user: readUser(),
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
    localStorage.setItem(TENANT_KEY, tenantCode)
    persistUser({
      userId: result.userId,
      tenantId: result.tenantId,
      tenantCode,
      displayName: result.displayName,
      platformAdmin: false,
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
      tenantCode: base?.tenantCode ?? '',
      displayName: base?.displayName ?? '',
      platformAdmin: result.platformAdmin,
      resources: result.resources
    })
    state.loaded = true
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
