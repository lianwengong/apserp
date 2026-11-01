<template>
  <div class="designer-view">
    <div class="header">
      <div>
        <h2>设计器中心</h2>
        <p class="sub">配置即功能：这里的每一项都会在运行时生效，不需要改代码、不需要发版。</p>
      </div>
      <div class="overview" v-if="stats">
        <el-tag v-for="(v, k) in statLabels" :key="k" size="small" effect="plain">
          {{ v }} {{ stats[k] ?? 0 }}
        </el-tag>
      </div>
    </div>

    <el-tabs v-model="tab" type="border-card" class="tabs" @tab-change="onTab">
      <el-tab-pane label="字段设计器" name="field">
        <FieldDesigner />
      </el-tab-pane>
      <el-tab-pane label="规则设计器" name="rule">
        <RuleDesigner />
      </el-tab-pane>
      <el-tab-pane label="按钮/动作" name="button">
        <ButtonDesigner />
      </el-tab-pane>
      <el-tab-pane label="审批流" name="approval">
        <ApprovalDesigner />
      </el-tab-pane>
      <el-tab-pane label="权限设计器" name="permission">
        <PermissionDesigner />
      </el-tab-pane>
      <el-tab-pane label="发布与回滚" name="publish">
        <PublishDesigner />
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { designApi } from '../../api/design'
import FieldDesigner from './FieldDesigner.vue'
import RuleDesigner from './RuleDesigner.vue'
import ButtonDesigner from './ButtonDesigner.vue'
import ApprovalDesigner from './ApprovalDesigner.vue'
import PermissionDesigner from './PermissionDesigner.vue'
import PublishDesigner from './PublishDesigner.vue'

const TAB_KEYS = ['field', 'rule', 'button', 'approval', 'permission', 'publish'] as const
const route = useRoute()
const router = useRouter()
const tab = ref<string>('field')
const stats = ref<Record<string, number> | null>(null)

const statLabels: Record<string, string> = {
  objects: '对象',
  fields: '字段',
  rules: '规则',
  buttons: '按钮',
  workflows: '审批流',
  roles: '角色',
  versions: '版本'
}

function onTab(name: string | number) {
  router.replace({ query: { ...route.query, tab: String(name) } })
}

// 同一路由内切换 tab 不会重建组件，必须监听查询参数（菜单/外链都可能直接带 ?tab=）
watch(
  () => route.query.tab,
  (v) => {
    const q = String(v ?? '')
    if (TAB_KEYS.includes(q as (typeof TAB_KEYS)[number])) tab.value = q
  }
)

onMounted(async () => {
  const q = String(route.query.tab ?? '')
  if (TAB_KEYS.includes(q as (typeof TAB_KEYS)[number])) tab.value = q
  try {
    stats.value = await designApi.overview()
  } catch {
    // 概览失败不影响设计器本身
  }
})
</script>

<style scoped>
.designer-view { padding: 4px 2px; }
.header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 10px; gap: 16px; }
.header h2 { margin: 0; font-size: 18px; }
.sub { margin: 4px 0 0; font-size: 12px; color: var(--el-text-color-secondary); }
.overview { display: flex; gap: 6px; flex-wrap: wrap; justify-content: flex-end; }
.tabs :deep(.el-tabs__content) { padding: 10px; }
</style>
