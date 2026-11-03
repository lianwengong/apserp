import { request } from './http'

export interface PlatformRole {
  id: number
  code: string
  name: string
  enabled: boolean
  memberCount: number
  /** 成员账号（用户名），列表直接展示 */
  members: string[]
  permissions: string[]
}

export interface PlatformPermission {
  resourceKey: string
  name: string
  parentKey: string | null
}

export interface SaveRoleBody {
  id?: number | null
  code?: string | null
  name: string
  enabled: boolean
  permissions: string[]
}

export function listPlatformRoles(): Promise<PlatformRole[]> {
  return request<PlatformRole[]>('/api/admin/roles')
}

export function listPlatformPermissions(): Promise<PlatformPermission[]> {
  return request<PlatformPermission[]>('/api/admin/roles/permissions')
}

export function savePlatformRole(body: SaveRoleBody): Promise<{ id: number }> {
  return request<{ id: number }>('/api/admin/roles', { method: 'POST', body })
}

export function listRoleMembers(roleId: number): Promise<number[]> {
  return request<number[]>(`/api/admin/roles/${roleId}/members`)
}

export function setRoleMembers(roleId: number, userIds: number[]): Promise<void> {
  return request<void>(`/api/admin/roles/${roleId}/members`, {
    method: 'PUT',
    body: { userIds }
  })
}
