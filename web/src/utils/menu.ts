import type { MenuNode } from '../api/menu'

/** 按名称/编码过滤菜单树；命中子节点时保留祖先链。 */
export function filterMenuTree(nodes: MenuNode[], keyword: string): MenuNode[] {
  const text = keyword.trim().toLowerCase()
  if (!text) return nodes
  const walk = (list: MenuNode[]): MenuNode[] => {
    const result: MenuNode[] = []
    for (const node of list) {
      const children = walk(node.children)
      const hit = node.name.toLowerCase().includes(text) || node.code.toLowerCase().includes(text)
      if (hit || children.length > 0) {
        result.push({ ...node, children })
      }
    }
    return result
  }
  return walk(nodes)
}

/** 直接刷新 /m/:code 时用编码找回菜单名，避免标题只有编码。 */
export function findMenuName(nodes: MenuNode[], code: string): string | null {
  for (const node of nodes) {
    if (node.code === code) return node.name
    const found = findMenuName(node.children, code)
    if (found) return found
  }
  return null
}

export function countMenus(nodes: MenuNode[]): number {
  let total = 0
  for (const node of nodes) {
    total += 1 + countMenus(node.children)
  }
  return total
}
