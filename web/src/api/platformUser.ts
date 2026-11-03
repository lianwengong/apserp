/* 平台管理：跨租户登录用户与权限 */
import { request } from './http'

export interface AdminUserRow {
  id: number
  tenantId: number
  tenantCode: string | null
  userName: string
  displayName: string | null
  mobile: string | null
  email: string | null
  enabled: boolean
  mustChangePwd: boolean
  locked: boolean
  platformAccount: boolean
  lastLoginAt: string | null
  roles: string[]
}

export interface AdminUserPage {
  items: AdminUserRow[]
  total: number
}

export interface AdminRole {
  id: number
  tenantId: number
  code: string
  name: string
  enabled: boolean
}

export function listAdminUsers(params: {
  keyword?: string
  tenantId?: number | null
  page?: number
  size?: number
}): Promise<AdminUserPage> {
  const search = new URLSearchParams()
  if (params.keyword) search.set('keyword', params.keyword)
  if (params.tenantId) search.set('tenantId', String(params.tenantId))
  search.set('page', String(params.page ?? 1))
  search.set('size', String(params.size ?? 20))
  return request<AdminUserPage>(`/api/admin/users?${search.toString()}`)
}

export function listAdminRoles(tenantId: number): Promise<AdminRole[]> {
  return request<AdminRole[]>(`/api/admin/users/roles?tenantId=${tenantId}`)
}

export function setAdminUserEnabled(userId: number, enabled: boolean): Promise<void> {
  return request<void>(`/api/admin/users/${userId}/enabled`, {
    method: 'PUT',
    body: { enabled }
  })
}

export function resetAdminUserPassword(userId: number, newPassword: string): Promise<void> {
  return request<void>(`/api/admin/users/${userId}/reset-password`, {
    method: 'POST',
    body: { newPassword }
  })
}

export function setAdminUserRoles(userId: number, roleIds: number[]): Promise<void> {
  return request<void>(`/api/admin/users/${userId}/roles`, {
    method: 'PUT',
    body: { roleIds }
  })
}
