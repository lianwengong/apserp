import { request } from './http'

/** 功能模块菜单：由后端 plat.Menu 组树，前端只负责渲染。 */
export interface MenuNode {
  id: number
  parentId: number | null
  code: string
  name: string
  route: string | null
  icon: string | null
  menuType: number
  moduleCode: string | null
  children: MenuNode[]
}

export function fetchMenuTree(terminal = 1): Promise<MenuNode[]> {
  return request<MenuNode[]>(`/api/menu/tree?terminal=${terminal}`)
}
