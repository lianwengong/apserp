<script setup lang="ts">
import { computed, ref } from 'vue'
import type { PageSchema } from '../schema/types'
import { resolvePage } from '../schema/registry'
import MetaListView from '../views/MetaListView.vue'
import DashboardView from '../views/DashboardView.vue'

/**
 * 一屏多页签模板。
 *
 * 每个页签只引用一个已有的数据对象或 PageSchema，不在容器里复制查询/表格逻辑；
 * 懒加载 + 保持挂载：切走再切回不丢查询条件、滚动位置。
 */
const props = defineProps<{ schema: PageSchema }>()

defineOptions({ name: 'PageTabs' })

const tabs = computed(() => props.schema.tabs ?? [])
const active = ref(tabs.value[0]?.key ?? '')

function childOf(pageCode: string | undefined): PageSchema | undefined {
  return pageCode ? resolvePage(pageCode) : undefined
}

function objectOf(tab: { objectCode?: string }): string {
  return tab.objectCode ?? ''
}
</script>

<template>
  <div class="page-tabs">
    <el-tabs v-if="tabs.length" v-model="active" type="border-card" class="tabs">
      <el-tab-pane v-for="tab in tabs" :key="tab.key" :name="tab.key" :lazy="true">
        <template #label>
          <span class="tab-label">{{ tab.label }}</span>
        </template>

        <MetaListView v-if="tab.objectCode" :object-code="objectOf(tab)" />
        <DashboardView
          v-else-if="childOf(tab.pageCode)?.kind === 'dashboard'"
          :schema="childOf(tab.pageCode)"
        />
        <MetaListView
          v-else-if="childOf(tab.pageCode)?.kind === 'object'"
          :object-code="childOf(tab.pageCode)?.objectCode"
        />
        <el-empty
          v-else
          :description="`页签「${tab.label}」的页面未配置：${tab.pageCode ?? '缺少 pageCode'}`"
          :image-size="80"
        />
      </el-tab-pane>
    </el-tabs>
    <el-empty v-else description="这个页面还没有配置任何页签" />
  </div>
</template>

<style scoped>
.page-tabs {
  height: 100%;
  min-height: 0;
  padding: 10px 12px 0;
  background: var(--bg);
  display: flex;
  flex-direction: column;
}
.tabs {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}
.tabs :deep(.el-tabs__content) {
  flex: 1;
  min-height: 0;
  overflow: auto;
  padding: 0;
}
.tabs :deep(.el-tab-pane) {
  height: 100%;
  min-height: 0;
}
.tab-label { font-size: 13px; }
</style>
