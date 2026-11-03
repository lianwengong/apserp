import { request } from './http'
import type { LoginResult } from './types'

export interface LoginPayload {
  tenantCode: string
  userName: string
  password: string
  /** 入口：1 平台管理 / 2 业务管理 */
  appType: number
}

export function login(payload: LoginPayload): Promise<LoginResult> {
  return request<LoginResult>('/api/auth/login', { method: 'POST', body: payload })
}
