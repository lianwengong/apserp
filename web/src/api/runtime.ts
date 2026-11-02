import { request, queryString } from './http'

export const runtimeApi = {
  children: (objectCode: string, id: number) =>
    request<ChildGroup[]>(`/api/runtime/children${queryString({ objectCode, id })}`),

  docStatusDefine: (objectCode: string) =>
    request<DocStatusDefine[]>(
      `/api/runtime/doc-status/define${queryString({ objectCode })}`
    ),

  docStatus: (objectCode: string, id: number) =>
    request<DocStatusCapability>(`/api/runtime/doc-status${queryString({ objectCode, id })}`),

  metaVersion: () =>
    request<{ version: number; gray: boolean }>('/api/runtime/meta-version'),

  executeAction: (body: {
    objectCode: string
    id?: number | null
    buttonCode: string
    params?: Record<string, unknown>
  }) => request<ExecuteResult>('/api/runtime/action/execute', { method: 'POST', body }),

  commands: () => request<string[]>('/api/runtime/action/commands'),

  buttons: (objectCode: string, id?: number) =>
    request<ResolvedButton[]>(`/api/runtime/buttons${queryString({ objectCode, id })}`),

  submit: (body: { objectCode: string; businessId: number; businessNo?: string | null; title?: string | null }) =>
    request<{ instanceId: number }>('/api/runtime/workflow/submit', { method: 'POST', body }),

  approve: (taskId: number, approved: boolean, opinion: string) =>
    request<void>(`/api/runtime/workflow/tasks/${taskId}/approve`, {
      method: 'POST',
      body: { approved, opinion }
    }),

  returnTo: (taskId: number, targetNodeCode: string, opinion: string) =>
    request<void>(`/api/runtime/workflow/tasks/${taskId}/return`, {
      method: 'POST',
      body: { targetNodeCode, opinion }
    }),

  addSign: (taskId: number, approverId: number, opinion: string) =>
    request<{ taskId: number }>(`/api/runtime/workflow/tasks/${taskId}/addsign`, {
      method: 'POST',
      body: { approverId, opinion }
    }),

  withdraw: (instanceId: number, opinion: string) =>
    request<void>(`/api/runtime/workflow/instances/${instanceId}/withdraw`, {
      method: 'POST',
      body: { opinion }
    }),

  todos: () => request<ApprovalInstance[]>('/api/runtime/workflow/todos'),

  ccs: () => request<ApprovalInstance[]>('/api/runtime/workflow/ccs'),

  unreadCc: () => request<{ count: number }>('/api/runtime/workflow/ccs/unread'),

  markCcRead: (instanceId: number) =>
    request<void>(`/api/runtime/workflow/instances/${instanceId}/cc-read`, { method: 'POST' }),

  overdue: () => request<ApprovalInstance[]>('/api/runtime/workflow/overdue'),

  remind: (taskId: number, opinion: string) =>
    request<{ reminded: number }>(`/api/runtime/workflow/tasks/${taskId}/remind`, {
      method: 'POST',
      body: { opinion }
    }),

  delegates: () => request<DelegateDto[]>('/api/runtime/workflow/delegates'),

  saveDelegate: (body: DelegateSaveBody) =>
    request<{ id: number }>('/api/runtime/workflow/delegates', { method: 'POST', body }),

  deleteDelegate: (id: number) =>
    request<void>(`/api/runtime/workflow/delegates/${id}`, { method: 'DELETE' }),

  instances: (objectCode: string, businessId: number) =>
    request<ApprovalInstance[]>(
      `/api/runtime/workflow/instances${queryString({ objectCode, businessId })}`
    ),

  instance: (instanceId: number) =>
    request<ApprovalInstance>(`/api/runtime/workflow/instances/${instanceId}`)
}

export interface ExecuteResult {
  kind: 'navigate' | 'download' | 'refresh' | 'message' | 'close' | 'print'
  message: string | null
  route: string | null
  downloadUrl: string | null
  data: Record<string, unknown>
  refresh: boolean
}

export interface DocStatusDefine {
  id: number
  objectCode: string
  statusValue: number
  statusName: string
  sort: number
  canEdit: boolean
  canDelete: boolean
  canSubmit: boolean
  isFinal: boolean
  colorType: string | null
  enabled: boolean
}

export interface DocTransition {
  id: number
  objectCode: string
  fromStatus: number
  fromStatusName: string
  toStatus: number
  toStatusName: string
  actionCode: string
  actionName: string
  sort: number
  enabled: boolean
}

export interface DocStatusCapability {
  objectCode: string
  statusField: string | null
  statusValue: number
  statusName: string | null
  colorType: string | null
  configured: boolean
  canEdit: boolean
  canDelete: boolean
  canSubmit: boolean
  isFinal: boolean
  transitions: DocTransition[]
}

export interface ChildGroup {
  alias: string
  childObjectCode: string
  childObjectName: string | null
  foreignKeyField: string
  cascadeDelete: boolean
  total: number
  rows: Record<string, unknown>[]
}

export interface ResolvedAction {
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

export interface ResolvedButton {
  code: string
  text: string
  icon: string | null
  buttonType: number
  style: string | null
  visible: boolean
  enabled: boolean
  disableReason: string | null
  actions: ResolvedAction[]
}

export interface DelegateDto {
  id: number
  userId: number
  userName: string | null
  delegateToId: number
  delegateToName: string | null
  startAt: string | null
  endAt: string | null
  enabled: boolean
  remark: string | null
}

export interface DelegateSaveBody {
  id?: number | null
  userId: number
  delegateToId: number
  startAt?: string | null
  endAt?: string | null
  enabled: boolean
  remark?: string | null
}

export interface ApprovalTask {
  id: number
  instanceId: number
  nodeCode: string
  nodeName: string
  approverId: number
  approverName: string | null
  status: number
  statusName: string
  opinion: string | null
  handledAt: string | null
  sort: number
  dueAt: string | null
  overdue: boolean
}

export interface ApprovalLog {
  action: string
  actionName: string
  operatorId: number | null
  operatorName: string | null
  opinion: string | null
  at: string
}

export interface ApprovalInstance {
  id: number
  defCode: string
  defName: string | null
  objectCode: string
  businessId: number
  businessNo: string | null
  title: string | null
  status: number
  statusName: string
  currentNodeCode: string | null
  currentNodeName: string | null
  startedBy: number | null
  startedByName: string | null
  startedAt: string
  finishedAt: string | null
  tasks: ApprovalTask[]
  logs: ApprovalLog[]
  canApprove: boolean
  canWithdraw: boolean
  canAddSign: boolean
  ccUsers: string[]
}
