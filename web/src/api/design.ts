import { request, queryString } from './http'

/** 设计器接口：规则 / 按钮 / 审批 / 发布 / 权限。全部走 /api/design。 */
export const designApi = {
  overview: () => request<Record<string, number>>('/api/design/overview'),

  // ---------------- 子表关系
  relations: (objectCode?: string) =>
    request<RelationDto[]>(`/api/design/relations${queryString({ objectCode })}`),
  saveRelation: (body: RelationSaveBody) =>
    request<{ id: number }>('/api/design/relations', { method: 'POST', body }),
  deleteRelation: (id: number) =>
    request<void>(`/api/design/relations/${id}`, { method: 'DELETE' }),

  // ---------------- 规则
  rules: () => request<RuleDto[]>('/api/design/rules'),
  saveRule: (body: RuleSaveBody) =>
    request<{ id: number }>('/api/design/rules', { method: 'POST', body }),
  deleteRule: (code: string) =>
    request<void>(`/api/design/rules/${encodeURIComponent(code)}`, { method: 'DELETE' }),
  validateRule: (expression: string) =>
    request<{ valid: boolean; error: string | null; sample: unknown }>('/api/design/rules/validate', {
      method: 'POST',
      body: { expression }
    }),
  testRule: (objectCode: string, triggerEvent: number, data: Record<string, unknown>) =>
    request<RuleTestRow[]>('/api/design/rules/test', {
      method: 'POST',
      body: { objectCode, triggerEvent, data }
    }),
  bindings: (objectCode?: string) =>
    request<RuleBindingDto[]>(`/api/design/rules/bindings${queryString({ objectCode })}`),
  bind: (body: BindingSaveBody) =>
    request<{ id: number }>('/api/design/rules/bindings', { method: 'POST', body }),
  unbind: (id: number) =>
    request<void>(`/api/design/rules/bindings/${id}`, { method: 'DELETE' }),

  // ---------------- 按钮
  buttons: (objectCode?: string) =>
    request<ButtonDto[]>(`/api/design/buttons${queryString({ objectCode })}`),
  saveButton: (body: ButtonSaveBody) =>
    request<{ id: number }>('/api/design/buttons', { method: 'POST', body }),
  deleteButton: (code: string) =>
    request<void>(`/api/design/buttons/${encodeURIComponent(code)}`, { method: 'DELETE' }),
  buttonFunctions: (objectCode: string) =>
    request<{ id: number; code: string; name: string }[]>(
      `/api/design/buttons/functions${queryString({ objectCode })}`
    ),

  // ---------------- 审批
  approvals: () => request<ApprovalDefDto[]>('/api/design/approvals'),
  saveApproval: (body: ApprovalSaveBody) =>
    request<{ id: number }>('/api/design/approvals', { method: 'POST', body }),
  publishApproval: (code: string) =>
    request<void>(`/api/design/approvals/${encodeURIComponent(code)}/publish`, { method: 'POST' }),
  approvalDict: () => request<Record<string, Record<string, string>>>('/api/design/approvals/dictionaries'),
  approvalUsers: () =>
    request<{ id: number; userName: string; displayName: string }[]>('/api/design/approvals/users'),

  // ---------------- 发布
  currentVersion: () =>
    request<{ version: number; cache: Record<string, number> }>('/api/design/versions/current'),

  grayOf: (version: number) =>
    request<{ version: number; userIds: number[]; userNames: string[] }>(
      `/api/design/versions/${version}/gray`
    ),

  activate: (version: number, userIds: number[], remark?: string) =>
    request<{ version: number }>(`/api/design/versions/${version}/activate`, {
      method: 'POST',
      body: { userIds, remark: remark ?? '' }
    }),

  publish: (remark: string, grayUserIds: number[] = []) =>
    request<PublishResult>('/api/design/publish', { method: 'POST', body: { remark, grayUserIds } }),
  versions: () => request<VersionDto[]>('/api/design/versions'),
  version: (version: number) => request<Record<string, unknown>>(`/api/design/versions/${version}`),
  rollback: (version: number, remark?: string) =>
    request<PublishResult>(`/api/design/versions/${version}/rollback`, {
      method: 'POST',
      body: { remark: remark ?? '' }
    }),
  diff: (version: number) => request<DiffResult>(`/api/design/versions/${version}/diff`),

  // ---------------- 权限
  roles: () => request<RoleDto[]>('/api/design/permissions/roles'),
  resources: (keyword?: string) =>
    request<ResourceDto[]>(`/api/design/permissions/resources${queryString({ keyword })}`),
  roleMatrix: (roleId: number) =>
    request<{ roleId: number; grants: { resourceKey: string; granted: boolean }[] }>(
      `/api/design/permissions/roles/${roleId}/matrix`
    ),
  saveRoleMatrix: (roleId: number, resourceKeys: string[]) =>
    request<{ granted: number }>(`/api/design/permissions/roles/${roleId}/matrix`, {
      method: 'PUT',
      body: { resourceKeys }
    }),
  fieldMatrix: (roleId: number, objectCode: string) =>
    request<{ roleId: number; objectCode: string; fields: FieldAccessRow[] }>(
      `/api/design/permissions/fields${queryString({ roleId, objectCode })}`
    ),
  saveFieldMatrix: (roleId: number, objectCode: string, access: Record<string, number>) =>
    request<{ saved: number }>('/api/design/permissions/fields', {
      method: 'PUT',
      body: { roleId, objectCode, access }
    }),
  functionTree: () => request<ModuleNode[]>('/api/design/permissions/functions')
}

// ============================================================ 类型

export interface RuleDto {
  id: number
  code: string
  name: string
  ruleType: number
  expression: string
  errorMessage: string | null
  severity: number
  enabled: boolean
  remark: string | null
  bindingCount: number
}

export interface RuleSaveBody {
  id?: number | null
  code: string
  name: string
  ruleType?: number
  expression: string
  errorMessage?: string | null
  severity?: number
  enabled?: boolean
  remark?: string | null
}

export interface RuleTestRow {
  ruleCode: string
  name: string
  expression: string
  severity: number
  result: unknown
  passed: boolean
  message: string
  error: string | null
}

export interface RuleBindingDto {
  id: number
  ruleId: number
  ruleCode: string
  dataObjectId: number
  objectCode: string
  fieldName: string | null
  triggerEvent: number
  sort: number
  enabled: boolean
}

export interface BindingSaveBody {
  ruleId: number
  objectCode: string
  fieldName?: string | null
  triggerEvent: number
  sort: number
  enabled: boolean
}

export interface ActionDto {
  id: number
  seq: number
  actionType: number
  actionTypeName: string
  builtinCode: string | null
  target: string | null
  command: string | null
  paramJson: string | null
  confirmText: string | null
  successMessage: string | null
  needWorkflow: boolean
  enabled: boolean
}

export interface ButtonDto {
  id: number
  code: string
  name: string
  text: string | null
  icon: string | null
  buttonType: number
  sort: number
  style: string | null
  visibleExpr: string | null
  enabledExpr: string | null
  functionCode: string | null
  actions: ActionDto[]
}

export interface ButtonSaveBody {
  id?: number | null
  code: string
  name: string
  text?: string | null
  icon?: string | null
  buttonType: number
  functionId: number
  sort: number
  visible: boolean
  visibleExpr?: string | null
  enabledExpr?: string | null
  style?: string | null
  remark?: string | null
  actions: ActionForm[]
}

export interface ActionForm {
  actionType: number
  builtinCode: string | null
  target: string | null
  command: string | null
  paramJson: string | null
  confirmText: string | null
  successMessage: string | null
  needWorkflow: boolean
}

export interface ApproverDto {
  id: number
  approverType: number
  approverId: number | null
  approverName: string | null
  expression: string | null
  sort: number
}

export interface ApprovalNodeDto {
  id: number
  code: string
  name: string
  nodeType: number
  sort: number
  approveMode: number
  rejectMode: number
  conditionExpr: string | null
  allowAddSign: boolean
  nextNodeCode: string | null
  rejectNodeCode: string | null
  approvers: ApproverDto[]
  timeoutHours: number | null
  ccUserIds: number[]
}

export interface ApprovalDefDto {
  id: number
  code: string
  name: string
  objectCode: string | null
  version: number
  conditionExpr: string | null
  status: number
  isDefault: boolean
  remark: string | null
  nodes: ApprovalNodeDto[]
}

export interface ApprovalSaveBody {
  id?: number | null
  code: string
  name: string
  objectCode?: string | null
  conditionExpr?: string | null
  isDefault: boolean
  remark?: string | null
  nodes: {
    code: string
    name: string
    nodeType: number
    sort: number
    approveMode: number
    rejectMode: number
    conditionExpr?: string | null
    allowAddSign: boolean
    nextNodeCode?: string | null
    rejectNodeCode?: string | null
    timeoutHours?: number | null
    ccUserIds?: number[]
    approvers: { approverType: number; approverId?: number | null; expression?: string | null; sort: number }[]
  }[]
}

export interface VersionDto {
  id: number
  version: number
  scope: string
  contentHash: string
  publishedBy: number | null
  publishedByName: string | null
  publishedAt: string
  rollbackOf: number | null
  status: number
  remark: string | null
  sizeBytes: number
}

export interface PublishResult {
  version: number
  contentHash: string
  sizeBytes: number
}

export interface DiffResult {
  fromVersion: number | null
  toVersion: number | null
  items: { kind: string; action: string; code: string }[]
}

export interface RelationDto {
  id: number
  parentObjectCode: string
  childObjectCode: string
  childObjectName: string | null
  alias: string
  foreignKeyField: string
  displayName: string | null
  sort: number
  cascadeDelete: number
  maxRows: number
  enabled: boolean
}

export interface RelationSaveBody {
  id?: number | null
  parentObjectCode: string
  childObjectCode: string
  alias: string
  foreignKeyField: string
  displayName?: string | null
  sort: number
  cascadeDelete: number
  maxRows: number
  enabled: boolean
  remark?: string | null
}

export interface RoleDto {
  id: number
  code: string
  name: string
  roleType: number
  enabled: boolean
  userCount: number
}

export interface ResourceDto {
  id: number
  key: string
  type: number
  typeName: string
  name: string
  module: string
}

export interface FieldAccessRow {
  fieldName: string
  displayName: string
  access: number
}

export interface ModuleNode {
  id: number
  code: string
  name: string
  parentId: number | null
  children: ModuleNode[]
}
