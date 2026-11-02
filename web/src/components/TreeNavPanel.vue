<script setup lang="ts">
import { ref, watch } from 'vue'
import { ArrowRight } from '@element-plus/icons-vue'
import type { MenuNode } from '../api/menu'

/**
 * 图标导航的弹出菜单树。
 *
 * 与参考系统的“扁平叶子”不同，这里保留层级：
 *   域 → 模块 → 功能入口；
 * 默认只展开域下的模块，点模块再展开功能；当前路由的祖先自动展开。
 */
defineOptions({ name: 'TreeNavPanel' })

const props = withDefaults(
  defineProps<{
    nodes: MenuNode[]
    currentPath: string
    level?: number
  }>(),
  { level: 0 }
)

const emit = defineEmits<{ select: [node: MenuNode] }>()

const expanded = ref<Set<number>>(new Set())

function expandAncestors(nodes: MenuNode[], path: string, ancestors: number[]): boolean {
  for (const node of nodes) {
    if (node.route === path) {
      ancestors.forEach((id) => expanded.value.add(id))
      return true
    }
    if (node.children.length && expandAncestors(node.children, path, [...ancestors, node.id])) {
      return true
    }
  }
  return false
}

watch(
  () => [props.nodes, props.currentPath] as const,
  () => {
    expandAncestors(props.nodes, props.currentPath, [])
    // Set 是浅层响应式，重新赋值触发面板重绘
    expanded.value = new Set(expanded.value)
  },
  { immediate: true }
)

function toggle(node: MenuNode): void {
  const next = new Set(expanded.value)
  if (next.has(node.id)) next.delete(node.id)
  else next.add(node.id)
  expanded.value = next
}

function isOpen(node: MenuNode): boolean {
  return expanded.value.has(node.id)
}

function isActive(node: MenuNode): boolean {
  if (!node.route) return false
  return props.currentPath === node.route || props.currentPath.startsWith(`${node.route}/`)
}

function hasActiveChild(node: MenuNode): boolean {
  return node.children.some((child) => isActive(child) || hasActiveChild(child))
}
</script>

<template>
  <div class="nav-tree">
    <template v-for="node in nodes" :key="node.id">
      <button
        v-if="node.children.length"
        type="button"
        class="panel-branch"
        :class="{ 'has-active': hasActiveChild(node) }"
        :style="{ paddingLeft: `${8 + level * 14}px` }"
        @click="toggle(node)"
      >
        <el-icon class="chev" :class="{ 'is-open': isOpen(node) }"><ArrowRight /></el-icon>
        <span class="branch-title">{{ node.name }}</span>
        <span class="branch-count">{{ node.children.length }}</span>
      </button>

      <button
        v-else
        type="button"
        class="panel-leaf"
        :class="{ 'is-active': isActive(node) }"
        :style="{ paddingLeft: `${22 + level * 14}px` }"
        @click="emit('select', node)"
      >
        <span class="leaf-dot" />
        <span class="leaf-title">{{ node.name }}</span>
        <span v-if="node.code" class="leaf-code">{{ node.code }}</span>
      </button>

      <TreeNavPanel
        v-if="node.children.length && isOpen(node)"
        :nodes="node.children"
        :current-path="currentPath"
        :level="level + 1"
        @select="emit('select', $event)"
      />
    </template>
  </div>
</template>

<style scoped>
.nav-tree {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.panel-branch,
.panel-leaf {
  display: flex;
  align-items: center;
  gap: 7px;
  width: 100%;
  min-height: 30px;
  padding-top: 5px;
  padding-bottom: 5px;
  padding-right: 9px;
  border: 0;
  border-radius: 7px;
  background: transparent;
  color: var(--ink);
  text-align: left;
  cursor: pointer;
}

.panel-branch:hover,
.panel-leaf:hover {
  background: var(--brand-50);
}

.panel-branch.has-active {
  color: var(--brand-700);
  font-weight: 600;
}

.chev {
  color: var(--muted);
  font-size: 11px;
  transition: transform 0.14s ease;
  flex: 0 0 auto;
}

.chev.is-open {
  transform: rotate(90deg);
}

.branch-title {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12.5px;
}

.branch-count {
  color: var(--muted);
  font-size: 10px;
}

.panel-leaf.is-active {
  background: var(--brand-50);
  color: var(--brand-700);
  font-weight: 600;
}

.leaf-dot {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--muted);
  flex: 0 0 auto;
}

.panel-leaf.is-active .leaf-dot {
  background: var(--brand);
}

.leaf-title {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 13px;
}

.leaf-code {
  color: var(--muted);
  font-family: "Cascadia Code", Consolas, monospace;
  font-size: 10px;
  flex: 0 0 auto;
}
</style>
