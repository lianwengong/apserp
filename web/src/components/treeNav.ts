import type { Component } from 'vue'
import type { MenuNode } from '../api/menu'

export interface TreeNavGroup {
  key: string
  title: string
  /** 图标轨上的短标签；不填则取标题前 4 字 */
  short?: string
  icon: Component
  /** 该域下的完整菜单子树（不是扁平叶子），由 TreeNavPanel 递归渲染 */
  nodes: MenuNode[]
}
