import { request } from './http'
import type {
  DataObjectDto,
  FieldDto,
  FormLayoutDto,
  ListViewDto,
  PageResult,
  Row
} from './types'

export function listObjects(): Promise<DataObjectDto[]> {
  return request<DataObjectDto[]>('/api/meta/objects')
}

export function getObject(code: string): Promise<DataObjectDto> {
  return request<DataObjectDto>(`/api/meta/objects/${encodeURIComponent(code)}`)
}

export function listFields(code: string): Promise<FieldDto[]> {
  return request<FieldDto[]>(`/api/meta/objects/${encodeURIComponent(code)}/fields`)
}

export function listViews(code: string): Promise<ListViewDto[]> {
  return request<ListViewDto[]>(`/api/meta/objects/${encodeURIComponent(code)}/views`)
}

export function listFormLayouts(code: string): Promise<FormLayoutDto[]> {
  return request<FormLayoutDto[]>(`/api/meta/objects/${encodeURIComponent(code)}/forms`)
}

export interface ListRowsParams {
  page: number
  size: number
  sort?: string
  filters?: string
  signal?: AbortSignal
}

/** 列表查询：过滤、排序、分页全部交给数据库引擎，前端不拼 SQL、不二次过滤。 */
export function listRows(code: string, params: ListRowsParams): Promise<PageResult> {
  const search = new URLSearchParams()
  search.set('page', String(params.page))
  search.set('size', String(params.size))
  if (params.sort) search.set('sort', params.sort)
  if (params.filters) search.set('filters', params.filters)
  return request<PageResult>(`/api/meta/${encodeURIComponent(code)}?${search.toString()}`, {
    signal: params.signal
  })
}

/** 保存：提交给保存引擎的 JSON 原样透传（新增不含 Id，修改含 Id）。 */
export function saveRow(code: string, payload: Row): Promise<{ id: number }> {
  return request<{ id: number }>(`/api/meta/${encodeURIComponent(code)}`, {
    method: 'POST',
    rawBody: JSON.stringify(payload)
  })
}
