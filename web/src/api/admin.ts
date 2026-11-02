import { request, queryString } from './http'

export interface TenantDto {
  id: number
  code: string
  name: string
  shortName: string | null
  industry: string | null
  enabled: boolean
  createdAt: string | null
  expireAt: string | null
}

/** 平台管理员：跨租户租户列表（只读）。 */
export function listTenants(): Promise<TenantDto[]> {
  return request<TenantDto[]>('/api/admin/tenants')
}

/** 系统功能模块管理（模块 → 功能点 → 动作链） */
export const moduleAdminApi = {
  overview: () => request<Record<string, number>>('/api/admin/modules/overview'),
  modelMap: () => request<ModelMap>('/api/admin/modules/model-map'),
  tree: (keyword?: string) =>
    request<ModuleNode[]>(`/api/admin/modules/tree${queryString({ keyword })}`),
  save: (body: ModuleSaveBody) =>
    request<{ id: number }>('/api/admin/modules', { method: 'POST', body }),
  remove: (id: number, force = false) =>
    request<void>(`/api/admin/modules/${id}${force ? '?force=true' : ''}`, { method: 'DELETE' }),
  functions: (moduleId: number) =>
    request<FunctionDto[]>(`/api/admin/modules/${moduleId}/functions`),
  saveFunction: (body: FunctionSaveBody) =>
    request<{ id: number }>('/api/admin/modules/functions', { method: 'POST', body }),
  removeFunction: (id: number) =>
    request<void>(`/api/admin/modules/functions/${id}`, { method: 'DELETE' }),
  saveActions: (functionId: number, body: ActionBody[]) =>
    request<ActionDto[]>(`/api/admin/modules/functions/${functionId}/actions`, {
      method: 'PUT',
      body
    })
}

/** 菜单设置管理（菜单树 / 终端归属） */
export const menuAdminApi = {
  tree: (params: { keyword?: string; moduleId?: number | null; terminalType?: number | null } = {}) =>
    request<MenuNode[]>(`/api/admin/menus/tree${queryString(params)}`),
  options: () =>
    request<{
      modules: OptionDto[]
      pages: OptionDto[]
      menuTypes: { value: number; label: string }[]
      openModes: { value: number; label: string }[]
      terminalTypes: { value: number; label: string }[]
    }>('/api/admin/menus/options'),
  save: (body: MenuSaveBody) =>
    request<{ id: number }>('/api/admin/menus', { method: 'POST', body }),
  move: (body: { id: number; parentId: number | null; sort: number }) =>
    request<void>('/api/admin/menus/move', { method: 'POST', body }),
  remove: (id: number) => request<void>(`/api/admin/menus/${id}`, { method: 'DELETE' })
}

/** 终端与功能模块：终端能用哪些模块（唯一来源） */
export const terminalAdminApi = {
  overview: () =>
    request<{ terminals: TerminalDto[]; moduleTotal: number }>('/api/admin/terminals/overview'),
  list: () => request<TerminalDto[]>('/api/admin/terminals'),
  allModules: (terminalType: number) =>
    request<TerminalModuleOption[]>(`/api/admin/terminals/${terminalType}/modules/all`),
  enabledModules: (terminalType: number) =>
    request<TerminalModuleOption[]>(`/api/admin/terminals/${terminalType}/modules`),
  saveModules: (terminalType: number, moduleIds: number[]) =>
    request<TerminalModuleOption[]>(`/api/admin/terminals/${terminalType}/modules`, {
      method: 'PUT',
      body: moduleIds
    }),
  enableModule: (terminalType: number, moduleId: number) =>
    request<TerminalModuleOption[]>(`/api/admin/terminals/${terminalType}/modules/${moduleId}`, {
      method: 'POST'
    }),
  disableModule: (terminalType: number, moduleId: number) =>
    request<TerminalModuleOption[]>(`/api/admin/terminals/${terminalType}/modules/${moduleId}`, {
      method: 'DELETE'
    })
}

export interface TerminalDto {
  terminalType: number
  label: string
  moduleCount: number
  menuCount: number
  functionCount: number
}

export interface TerminalModuleOption {
  id: number
  parentId: number | null
  code: string
  name: string
  level: number
  enabled: boolean
  menuCount: number
}

// ---------------------------------------------------------------- 类型

export interface ModelMap {
  modules: { total: number; level1: number; level2: number; level3: number }
  functions: { total: number; actions: number }
  menus: {
    total: number
    boundToModule: number
    unboundModule: number
    boundToPage: number
    placeholder: number
  }
  terminals: {
    menuTerminalRows: number
    moduleTerminalRows: number
    ruleViolations: number
    byType: { terminalType: number; menus: number }[]
  }
  permissions: { mod: number; fun: number; data: number; design: number }
  subsystem: { implemented: boolean; note: string }
  warnings: string[]
}

export interface ModuleNode {
  id: number
  parentId: number | null
  code: string
  name: string
  enCode: string | null
  level: number
  moduleType: number
  sort: number
  icon: string | null
  description: string | null
  enabled: boolean
  functionCount: number
  menuCount: number
  childCount: number
  children: ModuleNode[]
}

export interface ModuleSaveBody {
  id?: number | null
  parentId?: number | null
  code: string
  name: string
  enCode?: string | null
  moduleType: number
  sort: number
  icon?: string | null
  description?: string | null
  enabled: boolean
  createPermission: boolean
  remark?: string | null
}

export interface ActionDto {
  id: number
  seq: number
  phase: number
  actionType: number
  actionCode: string | null
  target: string | null
  command: string | null
  paramJson: string | null
  continueOnError: boolean
  errorMessage: string | null
  timeoutSeconds: number
  enabled: boolean
}

export interface ActionBody {
  phase: number
  actionType: number
  actionCode: string | null
  target: string | null
  command: string | null
  paramJson: string | null
  continueOnError: boolean
  errorMessage: string | null
  timeoutSeconds: number
  enabled: boolean
}

export interface FunctionDto {
  id: number
  moduleId: number
  code: string
  name: string
  funType: number
  sort: number
  permissionPoint: boolean
  confirmText: string | null
  successMessage: string | null
  icon: string | null
  hotKey: string | null
  enabled: boolean
  remark: string | null
  actions: ActionDto[]
}

export interface FunctionSaveBody {
  id?: number | null
  moduleId: number
  code: string
  name: string
  funType: number
  sort: number
  permissionPoint: boolean
  confirmText?: string | null
  successMessage?: string | null
  icon?: string | null
  hotKey?: string | null
  enabled: boolean
  remark?: string | null
}

export interface MenuNode {
  id: number
  parentId: number | null
  code: string
  name: string
  menuType: number
  moduleId: number | null
  moduleCode: string | null
  pageId: number | null
  pageCode: string | null
  route: string | null
  icon: string | null
  sort: number
  visible: boolean
  openMode: number
  badgeExpr: string | null
  enabled: boolean
  remark: string | null
  terminalType: number
  children: MenuNode[]
}

export interface MenuSaveBody {
  id?: number | null
  parentId?: number | null
  code: string
  name: string
  menuType: number
  moduleId?: number | null
  pageId?: number | null
  route?: string | null
  icon?: string | null
  sort: number
  visible: boolean
  openMode: number
  badgeExpr?: string | null
  enabled: boolean
  remark?: string | null
  terminalType: number
}

export interface OptionDto {
  id: number
  code: string
  name: string
  parentId: number | null
}
