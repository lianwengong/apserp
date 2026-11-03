import { request, queryString } from './http'

/** 平台账号（不含租户账号） */
export interface PlatformAccountRow {
  id: number
  userName: string
  displayName: string | null
  mobile: string | null
  email: string | null
  enabled: boolean
  mustChangePwd: boolean
  locked: boolean
  lastLoginAt: string | null
}

export function listPlatformAccounts(keyword?: string): Promise<PlatformAccountRow[]> {
  return request<PlatformAccountRow[]>(`/api/admin/users${queryString({ keyword })}`)
}

export function createPlatformAccount(body: {
  userName: string
  displayName: string
  password: string
}): Promise<PlatformAccountRow> {
  return request<PlatformAccountRow>('/api/admin/users', { method: 'POST', body })
}

export function setPlatformAccountEnabled(userId: number, enabled: boolean): Promise<void> {
  return request<void>(`/api/admin/users/${userId}/enabled`, {
    method: 'PUT',
    body: { enabled }
  })
}

export function resetPlatformAccountPassword(
  userId: number,
  newPassword: string
): Promise<{ userName: string }> {
  return request<{ userName: string }>(`/api/admin/users/${userId}/reset-password`, {
    method: 'POST',
    body: { newPassword }
  })
}
