import { request } from './http'
import type { FieldAccess, MeResult } from './types'

/** 当前用户的权限视图：菜单、按钮、字段可见性都以此为准。 */
export function me(): Promise<MeResult> {
  return request<MeResult>('/api/perm/me')
}

/** 字段级权限：Access=0 不可见，1 只读，2 可写。 */
export function fieldAccess(objectCode: string): Promise<FieldAccess> {
  return request<FieldAccess>(
    `/api/perm/fields?objectCode=${encodeURIComponent(objectCode)}`
  )
}
