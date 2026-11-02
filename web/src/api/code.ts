import { request } from './http'

/** 编号引擎：规则维护 + 取号预览 */
export const codeRuleApi = {
  list: () => request<CodeRuleDto[]>('/api/admin/code-rules'),
  save: (body: CodeRuleSaveBody) =>
    request<{ id: number }>('/api/admin/code-rules', { method: 'POST', body }),
  statistics: (code: string) =>
    request<{
      code: string
      sample: string | null
      period: string
      currentValue: number
      next: string
      periods: { Period: string; CurrentValue: number; ModifiedAt: string | null }[]
    }>(`/api/admin/code-rules/${encodeURIComponent(code)}/statistics`),
  preview: (code: string) =>
    request<{ docNo: string }>(`/api/runtime/code/preview?code=${encodeURIComponent(code)}`),
  next: (code: string) =>
    request<{ docNo: string }>(`/api/runtime/code/next?code=${encodeURIComponent(code)}`, {
      method: 'POST'
    })
}

export interface CodeRuleDto {
  id: number
  code: string
  name: string | null
  objectType: string | null
  prefix: string | null
  datePattern: string | null
  separator: string | null
  digitCount: number
  resetCycle: number
  enabled: boolean
  sample: string | null
  remark: string | null
}

export interface CodeRuleSaveBody {
  id?: number | null
  code: string
  name?: string | null
  objectType?: string | null
  prefix: string
  datePattern: string
  separator: string
  digitCount: number
  resetCycle: number
  enabled: boolean
  remark?: string | null
}
