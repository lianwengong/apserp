import { request } from './http'
import type { LoginResult } from './types'

export interface LoginPayload {
  tenantCode: string
  userName: string
  password: string
}

export function login(payload: LoginPayload): Promise<LoginResult> {
  return request<LoginResult>('/api/auth/login', { method: 'POST', body: payload })
}
