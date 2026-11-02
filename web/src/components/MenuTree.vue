<script setup lang="ts">
import { ref, watch } from 'vue'
import { ArrowRight } from '@element-plus/icons-vue'
import type { MenuNode } from '../api/menu'

defineOptions({ name: 'MenuTree' })

const props = defineProps<{
  nodes: MenuNode[]
  currentPath: string
  forceExpand: boolean
}>()

const emit = defineEmits<{
  select: [node: MenuNode]
}>()

const expanded = ref<Set<number>>(new Set())

function allIds(nodes: MenuNode[]): number[] {
  const ids: number[] = []
  for (const node of nodes) {
    if (node.children.length) {
      ids.push(node.id, ...allIds(node.children))
    }
  }
  return ids
}

function expandAncestors(nodes: MenuNode[], path: string, ancestors: number[]): boolean {
  for (const node of nodes) {
    if (node.route === path) {
      ancestors.forEach((id) => expanded.value.add(id))
      return true
    }
    if (expandAncestors(node.children, path, [...ancestors, node.id])) return true
  }
  return false
}

watch(
  () => [props.nodes, props.currentPath] as const,
  () => {
    expandAncestors(props.nodes, props.currentPath, [])
    if (props.forceExpand) expanded.value = new Set(allIds(props.nodes))
  },
  { immediate: true }
)

function isExpanded(node: MenuNode): boolean {
  return props.forceExpand || expanded.value.has(node.id)
}

function toggle(node: MenuNode): void {
  const next = new Set(expanded.value)
  if (next.has(node.id)) next.delete(node.id)
  else next.add(node.id)
  expanded.value = next
}
</script>

<template>
  <div class="menu-tree">
    <template v-for="node in nodes" :key="node.id">
      <button
        v-if="node.children.length"
        type="button"
        class="tree-branch"
        :title="node.name"
        @click="toggle(node)"
      >
        <el-icon class="chev" :class="{ 'is-open': isExpanded(node) }">
          <ArrowRight />
        </el-icon>
        <span class="branch-name">{{ node.name }}</span>
        <span class="branch-count">{{ node.children.length }}</span>
      </button>

      <button
        v-else
        type="button"
        class="tree-leaf"
        :class="{ active: node.route === currentPath }"
        :title="node.route ?? node.code"
        @click="emit('select', node)"
      >
        <span class="dot" />
        <span class="item-name">{{ node.name }}</span>
        <span class="item-code mono">{{ node.code }}</span>
      </button>

      <MenuTree
        v-if="node.children.length && isExpanded(node)"
        :nodes="node.children"
        :current-path="currentPath"
        :force-expand="forceExpand"
        class="is-nested"
        @select="emit('select', $event)"
      />
    </template>
  </div>
</template>

<style scoped>
.menu-tree {
  display: flex;
  flex-direction: column;
}

.menu-tree.is-nested {
  margin-left: 9px;
  padding-left: 3px;
  border-left: 1px solid rgba(255, 255, 255, 0.06);
}

.tree-branch,
.tree-leaf {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  min-height: 30px;
  padding: 0 8px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: var(--sidebar-text);
  font-family: inherit;
  font-size: 12.5px;
  text-align: left;
  cursor: pointer;
}

.tree-branch:hover,
.tree-leaf:hover {
  background: var(--sidebar-hover);
  color: #fff;
}

.chev {
  flex: 0 0 auto;
  font-size: 10px;
  color: #6f8296;
  transition: transform 0.12s ease;
}

.chev.is-open {
  transform: rotate(90deg);
  color: #8fd2b8;
}

.branch-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.branch-count {
  flex: 0 0 auto;
  min-width: 16px;
  padding: 0 4px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.06);
  color: #7e90a4;
  font-size: 10px;
  text-align: center;
}

.tree-leaf .dot {
  width: 4px;
  height: 4px;
  flex: 0 0 auto;
  border-radius: 50%;
  background: #55677c;
}

.tree-leaf.active {
  background: rgba(47, 163, 124, 0.16);
  color: #fff;
  box-shadow: inset 2px 0 0 #3fbf92;
}

.tree-leaf.active .dot {
  background: #3fbf92;
}

.item-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-code {
  flex: 0 0 auto;
  color: #63768c;
  font-size: 10px;
}

.tree-leaf.active .item-code {
  color: #7fd7b6;
}
</style>
