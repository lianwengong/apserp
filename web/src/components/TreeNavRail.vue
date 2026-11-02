<script setup lang="ts">
import type { TreeNavGroup, TreeNavLeaf } from './treeNav'

/**
 * 参考 ASWeb 的树形导航：
 * - 左侧 76px 图标轨，按“域”分组（工作台/平台管理/各业务根/基础资料）；
 * - 点某个域，右侧弹出该域下的**扁平叶子列表**（每条带所属模块面包屑）；
 * - 不再用“整块抽屉菜单”，避免点开后看不到自己在哪里。
 */
defineOptions({ name: 'TreeNavRail' })

const props = defineProps<{
  groups: TreeNavGroup[]
  currentPath: string
}>()

const emit = defineEmits<{ select: [leaf: TreeNavLeaf] }>()

function shortTitle(title: string): string {
  return title.length > 4 ? title.slice(0, 4) : title
}

function isActive(leaf: TreeNavLeaf): boolean {
  if (!leaf.route) return false
  return props.currentPath === leaf.route || props.currentPath.startsWith(`${leaf.route}/`)
}

function isGroupActive(group: TreeNavGroup): boolean {
  return group.leaves.some(isActive)
}

</script>

<template>
  <div class="tree-nav">
    <div class="tree-brand">APS</div>
    <el-popover
      v-for="group in groups"
      :key="group.key"
      placement="right-start"
      trigger="click"
      :width="260"
      popper-class="apserp-tree-nav-popover"
    >
      <template #reference>
        <button
          type="button"
          class="rail-item"
          :class="{ 'is-active': isGroupActive(group) }"
          :title="group.title"
        >
          <el-icon><component :is="group.icon" /></el-icon>
          <span class="rail-label">{{ shortTitle(group.title) }}</span>
        </button>
      </template>

      <div class="nav-panel">
        <div class="panel-title">{{ group.title }}</div>
        <button
          v-for="leaf in group.leaves"
          :key="leaf.key"
          type="button"
          class="panel-leaf"
          :class="{ 'is-active': isActive(leaf) }"
          @click="emit('select', leaf)"
        >
          <span class="leaf-title">{{ leaf.title }}</span>
          <span v-if="leaf.crumb" class="leaf-crumb">{{ leaf.crumb }}</span>
        </button>
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
.apserp-tree-nav-popover {
  padding: 0 !important;
  border-radius: 10px !important;
}

.apserp-tree-nav-popover .nav-panel {
  max-height: 62vh;
  overflow-y: auto;
  padding: 6px;
}

.apserp-tree-nav-popover .panel-title {
  padding: 7px 8px 8px;
  margin-bottom: 4px;
  border-bottom: 1px solid var(--line);
  color: var(--muted);
  font-size: 12px;
  font-weight: 600;
}

.apserp-tree-nav-popover .panel-leaf {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 1px;
  width: 100%;
  padding: 7px 9px;
  border: 0;
  border-radius: 7px;
  background: transparent;
  color: var(--ink);
  text-align: left;
  cursor: pointer;
}

.apserp-tree-nav-popover .panel-leaf:hover {
  background: var(--brand-50);
}

.apserp-tree-nav-popover .panel-leaf.is-active {
  background: var(--brand-50);
  color: var(--brand-700);
  font-weight: 600;
}

.apserp-tree-nav-popover .leaf-title {
  font-size: 13px;
}

.apserp-tree-nav-popover .leaf-crumb {
  color: var(--muted);
  font-size: 11px;
}
</style>
