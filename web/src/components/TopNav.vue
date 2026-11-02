<template>
  <nav class="topnav">
    <router-link to="/" class="top-item" :class="{ active: current === '/' }">工作台</router-link>
    <el-dropdown
      v-for="node in nodes"
      :key="node.id"
      trigger="hover"
      placement="bottom-start"
      @command="(code: string) => pick(node, code)"
    >
      <button type="button" class="top-item" :class="{ active: isUnder(node) }">
        <span>{{ node.name }}</span>
        <el-icon class="caret"><ArrowDown /></el-icon>
      </button>
      <template #dropdown>
        <el-dropdown-menu class="topnav-menu">
          <el-dropdown-item
            v-if="node.route"
            :command="`self:${node.code}`"
            class="topnav-self"
          >
            {{ node.name }}（总览）
          </el-dropdown-item>
          <el-dropdown-item
            v-for="child in leaves(node)"
            :key="child.code"
            :command="child.code"
            :divided="child.level === 2"
            :class="{ 'topnav-sub': child.level > 2 }"
          >
            {{ child.name }}
          </el-dropdown-item>
        </el-dropdown-menu>
      </template>
    </el-dropdown>
  </nav>
</template>

<script setup lang="ts">
import { ArrowDown } from '@element-plus/icons-vue'
import type { MenuNode } from '../api/menu'

defineOptions({ name: 'TopNav' })

const props = defineProps<{ nodes: MenuNode[]; current: string }>()
const emit = defineEmits<{ select: [node: MenuNode] }>()

interface FlatLeaf extends MenuNode {
  level: number
}

function leaves(node: MenuNode, level = 2): FlatLeaf[] {
  const out: FlatLeaf[] = []
  for (const child of node.children ?? []) {
    out.push({ ...child, level })
    if (child.children?.length) out.push(...leaves(child, level + 1))
  }
  return out
}

function isUnder(node: MenuNode): boolean {
  return props.current.startsWith(node.route ?? '') || leaves(node).some((leaf) => leaf.route === props.current)
}

function pick(node: MenuNode, code: string): void {
  if (code.startsWith('self:')) {
    emit('select', node)
    return
  }
  const target = leaves(node).find((leaf) => leaf.code === code)
  if (target) emit('select', target)
}
</script>

<style scoped>
.topnav {
  display: flex;
  align-items: center;
  gap: 2px;
  height: 44px;
  padding: 0 14px;
  background: var(--card);
  border-bottom: 1px solid var(--line);
  overflow-x: auto;
  flex: 0 0 auto;
}
.top-item {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: 30px;
  padding: 0 12px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--ink-2);
  font-size: 13px;
  white-space: nowrap;
  cursor: pointer;
}
.top-item:hover { background: var(--brand-50); color: var(--brand-700); }
.top-item.active { background: var(--brand-50); color: var(--brand-700); font-weight: 600; }
.caret { font-size: 11px; opacity: 0.7; }
</style>

<style>
.topnav-menu .topnav-sub { padding-left: 26px !important; font-size: 12.5px; }
.topnav-menu .topnav-self { font-weight: 600; }
</style>
