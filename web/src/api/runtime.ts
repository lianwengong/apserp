import { request, queryString } from './http'

export const runtimeApi = {
  children: (objectCode: string, id: number) =>
    request<ChildGroup[]>(`/api/runtime/children${queryString({ objectCode, id })}`),

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

  instances: (objectCode: string, businessId: number) =>
    request<ApprovalInstance[]>(
      `/api/runtime/workflow/instances${queryString({ objectCode, businessId })}`
    ),

  instance: (instanceId: number) =>
    request<ApprovalInstance>(`/api/runtime/workflow/instances/${instanceId}`)
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
}
