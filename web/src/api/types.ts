/** 与后端 ApiResult / DTO 一一对应。字段名以 Java record 为准，禁止在前端做二次发明。 */

export interface ApiEnvelope<T> {
  code: number
  message: string
  data: T
}

// ---------------------------------------------------------------- 认证 / 权限

export interface LoginResult {
  token: string
  userId: number
  tenantId: number
  displayName: string
  mustChangePassword: boolean
}

export interface MeResult {
  userId: number
  tenantId: number
  platformAdmin: boolean
  resources: string[]
  orgScope: number[]
}

/** 字段级权限：fieldName -> 0 不可见 / 1 只读 / 2 可写 */
export type FieldAccess = Record<string, number>

// ---------------------------------------------------------------- 元数据

export interface DataObjectDto {
  id: number
  code: string
  name: string
  objectType: number
  schemaName: string
  objectName: string
  primaryKey: string
  docNoField: string | null
  tenantField: string | null
  defaultOrder: string | null
  readOnly: boolean
}

export interface FieldDto {
  fieldName: string
  displayName: string
  dataType: string
  maxLength: number | null
  nullable: boolean
  primaryKey: boolean
  identity: boolean
  required: boolean
  lookupType: number
  lookupSource: string | null
  lookupDisplayField: string | null
  format: string | null
  sort: number
}

export interface ColumnDto {
  fieldName: string
  title: string | null
  width: number | null
  align: string | null
  sum: boolean
  visible: boolean
  sort: number
}

export interface ListViewDto {
  id: number
  code: string
  name: string
  pageSize: number
  defaultSort: string | null
  isDefault: boolean
  columns: ColumnDto[]
}

export interface FormFieldDto {
  fieldName: string
  label: string | null
  controlType: number
  row: number
  col: number
  span: number
  readOnly: boolean
  required: boolean
  hidden: boolean
  groupName: string | null
  sort: number
}

export interface FormLayoutDto {
  id: number
  code: string
  name: string
  mode: number
  columns: number
  isDefault: boolean
  fields: FormFieldDto[]
}

/** 列表查询结果：rows 是数据库引擎原样返回的字段值。 */
export interface PageResult {
  page: number
  size: number
  total: number
  rows: Row[]
}

export type Row = Record<string, unknown>

// ---------------------------------------------------------------- 前端列表状态

export type FilterOp = 'like' | 'eq' | 'neq' | 'gt' | 'gte' | 'lt' | 'lte'

export interface FilterCondition {
  f: string
  op: FilterOp
  v: string
}

export interface ListQuery {
  page: number
  size: number
  sort: string
  conditions: FilterCondition[]
}
