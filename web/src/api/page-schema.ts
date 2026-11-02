import { request, queryString } from './http'

/** 后端 plat.PageSchema 的 DTO。ConfigJson 是完整 PageSchema JSON。 */
export interface PageSchemaDto {
  id: number
  code: string
  title: string
  kind: string
  configJson: string
  version: number
  enabled: boolean
  remark: string | null
  createdAt: string
  modifiedAt: string | null
}

export interface PageSchemaSaveBody {
  id?: number | null
  code: string
  title: string
  kind: string
  configJson: string
  enabled: boolean
  remark?: string | null
}

export const pageSchemaApi = {
  /** 运行时读取：data 为 null 表示没有远程定义，前端回退本地。 */
  get: (code: string) =>
    request<PageSchemaDto | null>(`/api/page-schema/${encodeURIComponent(code)}`),

  list: (keyword = '') =>
    request<PageSchemaDto[]>(`/api/admin/page-schemas${queryString({ keyword })}`),

  save: (body: PageSchemaSaveBody) =>
    request<{ id: number }>('/api/admin/page-schemas', { method: 'POST', body }),

  remove: (id: number) =>
    request<void>(`/api/admin/page-schemas/${id}`, { method: 'DELETE' })
}
