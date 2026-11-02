import type { Component } from 'vue'
import type { MenuNode } from '../api/menu'

export interface TreeNavLeaf {
  key: string
  title: string
  route?: string
  crumb?: string
  node?: MenuNode
}

export interface TreeNavGroup {
  key: string
  title: string
  icon: Component
  leaves: TreeNavLeaf[]
}
