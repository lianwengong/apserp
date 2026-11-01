import { request } from './http'
import type { DataObjectDto, FieldDto, ListViewDto, FormLayoutDto } from './types'

/** 元数据定义只读清单：设计器用它给“对象/字段/视图/表单”做选择器。 */
export const metaApi = {
  objects: () => request<DataObjectDto[]>('/api/meta/objects'),
  object: (code: string) => request<DataObjectDto>(`/api/meta/objects/${encodeURIComponent(code)}`),
  fields: (code: string) =>
    request<FieldDto[]>(`/api/meta/objects/${encodeURIComponent(code)}/fields`),
  views: (code: string) =>
    request<ListViewDto[]>(`/api/meta/objects/${encodeURIComponent(code)}/views`),
  forms: (code: string) =>
    request<FormLayoutDto[]>(`/api/meta/objects/${encodeURIComponent(code)}/forms`)
}
