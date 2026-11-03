import { request, queryString } from './http'

export interface NotificationDto {
  id: number
  title: string
  content: string | null
  /** 1 提示 / 2 警告 / 3 错误 */
  msgType: number
  businessType: string | null
  businessId: number | null
  linkUrl: string | null
  read: boolean
  at: string | null
}

export function listNotifications(limit = 50): Promise<NotificationDto[]> {
  return request<NotificationDto[]>(`/api/notification${queryString({ limit })}`)
}

export function unreadCount(): Promise<{ count: number }> {
  return request<{ count: number }>('/api/notification/unread-count')
}

export function markRead(id: number): Promise<void> {
  return request<void>(`/api/notification/${id}/read`, { method: 'POST' })
}

export function markAllRead(): Promise<{ updated: number }> {
  return request<{ updated: number }>('/api/notification/read-all', { method: 'POST' })
}
