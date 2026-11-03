import { request } from './http'
import type { LoginResult } from './types'

export interface LoginPayload {
  tenantCode: string
  userName: string
  password: string
  /** 入口：1 平台管理 / 2 业务管理 */
  appType: number
}

export interface PlatformLoginPayload {
  userName: string
  password: string
}

/** 平台登录：没有租户名，令牌带平台作用域（可管理所有租户）。 */
export function platformLogin(payload: PlatformLoginPayload): Promise<LoginResult> {
  return request<LoginResult>('/api/auth/platform-login', { method: 'POST', body: payload })
}

export function login(payload: LoginPayload): Promise<LoginResult> {
  return request<LoginResult>('/api/auth/login', { method: 'POST', body: payload })
}
