<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Refresh, Search } from '@element-plus/icons-vue'
import { fetchMenuTree } from '../../api/menu'
import type { MenuNode } from '../../api/menu'
import { countMenus, filterMenuTree } from '../../utils/menu'
import { formatNumber } from '../../utils/format'

const loading = ref(false)
const error = ref('')
const tree = ref<MenuNode[]>([])
const keyword = ref('')

const filtered = computed(() => filterMenuTree(tree.value, keyword.value))
const total = computed(() => countMenus(tree.value))
const roots = computed(() => tree.value.length)
const modes = computed(() => {
  let groups = 0
  let leaves = 0
  const walk = (nodes: MenuNode[]): void => {
    for (const node of nodes) {
      if (node.children.length) {
        groups += 1
        walk(node.children)
      } else {
        leaves += 1
      }
    }
  }
  walk(tree.value)
  return { groups, leaves }
})

const treeProps = { children: 'children', label: 'name' }

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    tree.value = await fetchMenuTree()
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '菜单树加载失败'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <section class="card head">
      <div>
        <p class="eyebrow">MENUS</p>
        <h1>菜单总览</h1>
        <p class="muted sub">
          平台与业务菜单的只读视图（{{ formatNumber(total, 0) }} 个节点 / {{ roots }} 个一级域）。
          结构与排序的增删改在设计器中心的菜单/模块设计器里完成。
        </p>
      </div>
      <el-button :loading="loading" @click="load">
        <el-icon><Refresh /></el-icon>
        刷新
      </el-button>
    </section>

    <section class="stats">
      <div class="stat card">
        <span class="stat-value">{{ formatNumber(total, 0) }}</span>
        <span class="stat-label">菜单节点</span>
      </div>
      <div class="stat card">
        <span class="stat-value">{{ roots }}</span>
        <span class="stat-label">一级域</span>
      </div>
      <div class="stat card">
        <span class="stat-value">{{ modes.groups }}</span>
        <span class="stat-label">目录模块</span>
      </div>
      <div class="stat card">
        <span class="stat-value">{{ modes.leaves }}</span>
        <span class="stat-label">功能入口</span>
      </div>
    </section>

    <el-alert v-if="error" type="error" :title="error" :closable="false" show-icon />

    <section class="card body">
      <el-input
        v-model="keyword"
        class="search"
        placeholder="搜索菜单名称 / 编码，例如：租户、9002、品牌"
        clearable
        :prefix-icon="Search"
      />
      <div v-loading="loading" class="tree-wrap">
        <el-tree
          v-if="!loading && filtered.length"
          :key="keyword"
          :data="filtered"
          :props="treeProps"
          node-key="id"
          :default-expand-all="keyword.length > 0"
          :expand-on-click-node="false"
        >
          <template #default="{ data }">
            <span class="node">
              <span class="node-name">{{ data.name }}</span>
              <span class="node-code mono">{{ data.code }}</span>
              <span v-if="data.route" class="node-route mono">{{ data.route }}</span>
            </span>
          </template>
        </el-tree>
        <el-empty
          v-else-if="!loading"
          description="没有匹配的菜单"
          :image-size="64"
        />
      </div>
    </section>

    <section class="card note">
      <strong>说明</strong>
      <span>
        本页读取租户已启用/可见的菜单（管理员可见全量）；新增菜单或调整排序请到
        「设计器中心 → 菜单/模块设计器」，改完即时生效，无需发版。
      </span>
    </section>
  </div>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 14px;
  height: 100%;
  min-height: 0;
}

.head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 20px;
}

.head h1 {
  margin: 4px 0 0;
  font-size: 22px;
}

.sub {
  margin: 6px 0 0;
  font-size: 12.5px;
  max-width: 780px;
}

.stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.stat {
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-value {
  font-size: 19px;
  font-weight: 650;
}

.stat-label {
  font-size: 11.5px;
  color: var(--muted);
}

.body {
  flex: 1;
  min-height: 320px;
  display: flex;
  flex-direction: column;
  padding: 12px 16px 16px;
}

.search {
  width: min(460px, 100%);
  margin-bottom: 10px;
}

.tree-wrap {
  flex: 1;
  min-height: 0;
  overflow: auto;
  border-top: 1px solid var(--line);
  padding-top: 10px;
}

.node {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.node-name {
  font-size: 12.5px;
  color: var(--ink);
}

.node-code {
  font-size: 10.5px;
  color: #98a5b3;
}

.node-route {
  font-size: 10.5px;
  color: #b3bfcb;
}

.note {
  display: flex;
  gap: 10px;
  align-items: baseline;
  padding: 12px 16px;
  font-size: 12px;
  color: #5b6d7f;
  line-height: 1.7;
}

.note strong {
  color: var(--ink);
  white-space: nowrap;
}

@media (max-width: 1100px) {
  .stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
