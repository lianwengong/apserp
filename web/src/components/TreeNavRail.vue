<script setup lang="ts">
import type { MenuNode } from '../api/menu'
import type { TreeNavGroup } from './treeNav'
import TreeNavPanel from './TreeNavPanel.vue'

/**
 * 参考 ASWeb 的图标导航：
 * - 左侧 76px 图标轨，按“域”分组（工作台/平台管理/各业务根/基础资料）；
 * - 点某个域，右侧弹出该域的完整菜单树；
 * - 菜单树保留多级（域 → 模块 → 功能），默认展开模块，点模块再展开功能。
 */
defineOptions({ name: 'TreeNavRail' })

const props = defineProps<{
  groups: TreeNavGroup[]
  currentPath: string
}>()

const emit = defineEmits<{ select: [node: MenuNode] }>()

function shortTitle(title: string): string {
  return title.length > 4 ? title.slice(0, 4) : title
}

function isActive(node: MenuNode): boolean {
  if (!node.route) return false
  return props.currentPath === node.route || props.currentPath.startsWith(`${node.route}/`)
}

function hasActive(nodes: MenuNode[]): boolean {
  return nodes.some((node) => isActive(node) || hasActive(node.children))
}

function isGroupActive(group: TreeNavGroup): boolean {
  return hasActive(group.nodes)
}
</script>

<template>
  <div class="tree-nav">
    <div class="tree-brand">AS</div>
    <el-popover
      v-for="group in groups"
      :key="group.key"
      placement="right-start"
      trigger="click"
      :width="280"
      popper-class="aschain-tree-nav-popover"
    >
      <template #reference>
        <button
          type="button"
          class="rail-item"
          :class="{ 'is-active': isGroupActive(group) }"
          :title="group.title"
        >
          <el-icon><component :is="group.icon" /></el-icon>
          <span class="rail-label">{{ group.short ?? shortTitle(group.title) }}</span>
        </button>
      </template>

      <div class="nav-panel">
        <div class="panel-title">{{ group.title }}</div>
        <TreeNavPanel :nodes="group.nodes" :current-path="currentPath" @select="emit('select', $event)" />
      </div>
    </el-popover>
  </div>
</template>

<style scoped>
.tree-nav {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  width: 76px;
  flex: 0 0 76px;
  height: 100%;
  padding: 10px 6px;
  overflow-y: auto;
  background: linear-gradient(180deg, #16273a 0%, var(--sidebar) 55%, #0f1c2a 100%);
  scrollbar-width: thin;
  scrollbar-color: rgba(255, 255, 255, 0.18) transparent;
  z-index: 21;
}

.tree-brand {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  margin-bottom: 8px;
  border-radius: 9px;
  background: linear-gradient(135deg, #2fa37c, #1c6d51);
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  flex: 0 0 auto;
}

.rail-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  width: 64px;
  min-height: 50px;
  padding: 7px 2px;
  border: 0;
  border-left: 3px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: #aebccb;
  font-size: 11px;
  cursor: pointer;
  flex: 0 0 auto;
}

.rail-item:hover {
  background: rgba(255, 255, 255, 0.07);
  color: #fff;
}

.rail-item.is-active {
  background: rgba(47, 163, 124, 0.16);
  border-left-color: #3fbf92;
  color: #7fd3b0;
}

.rail-label {
  max-width: 60px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>

<style>
/* popover 被 teleport 到 body，不能放在 scoped 里 */
.aschain-tree-nav-popover {
  padding: 0 !important;
  border-radius: 10px !important;
}

.aschain-tree-nav-popover .nav-panel {
  max-height: 66vh;
  overflow-y: auto;
  padding: 6px;
}

.aschain-tree-nav-popover .panel-title {
  position: sticky;
  top: 0;
  z-index: 1;
  padding: 7px 8px 8px;
  margin-bottom: 4px;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  color: var(--muted);
  font-size: 12px;
  font-weight: 600;
}
</style>
