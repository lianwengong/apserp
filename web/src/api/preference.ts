import { request } from './http'

/** 用户偏好：跨设备同步（服务端只存 JSON 文本，不解释内容） */
export const preferenceApi = {
  all: () => request<Record<string, string>>('/api/preference'),
  get: (key: string) => request<Record<string, string>>(`/api/preference/${encodeURIComponent(key)}`),
  save: (key: string, value: string) =>
    request<void>(`/api/preference/${encodeURIComponent(key)}`, {
      method: 'PUT',
      body: { value }
    }),
  remove: (key: string) =>
    request<void>(`/api/preference/${encodeURIComponent(key)}`, { method: 'DELETE' })
}
