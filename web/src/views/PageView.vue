<script setup lang="ts">
import { computed, nextTick, onActivated, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft, Refresh } from '@element-plus/icons-vue'
import '../schema/pages'
import { loadPage } from '../schema/loader'
import type { PageSchema } from '../schema/types'
import PageTabs from '../components/PageTabs.vue'
import MetaListView from './MetaListView.vue'
import DashboardView from './DashboardView.vue'
import { tabsStore } from '../stores/tabs'
import { session } from '../stores/session'

defineOptions({ name: 'PageView' })

const route = useRoute()
const router = useRouter()
const props = defineProps<{ code?: string }>()
const code = computed(() => props.code ?? '')
const schema = ref<PageSchema | null>(null)
const loading = ref(true)

const allowed = computed(() => {
  const page = schema.value
  if (!page?.permissions?.length) return true
  return page.permissions.every((permission) => session.has(permission))
})

let requestId = 0

async function load(): Promise<void> {
  const current = ++requestId
  loading.value = true
  try {
    const page = await loadPage(code.value)
    if (current !== requestId) return
    schema.value = page ?? null
  } finally {
    if (current === requestId) loading.value = false
  }
}

watch(code, () => void load(), { immediate: true })

// 页面编排保存后会 invalidate 缓存；切回页签时重新取一次，缓存命中则没有网络开销。
onActivated(() => {
  if (schema.value) void load()
})

watch(
  schema,
  (page) => {
    if (!page) return
    document.title = `${page.title} · 阿申商链`
    // 页签在路由 afterEach 里先建好；等 DOM 更新后再改标题，避免被占位名覆盖。
    void nextTick(() => tabsStore.setTitle(route.path, page.title))
  },
  { immediate: true, flush: 'post' }
)
</script>

<template>
  <div class="page-view">
    <div v-if="loading && !schema" class="placeholder card">
      <el-skeleton :rows="5" animated />
    </div>

    <template v-else-if="schema">
      <div v-if="!allowed" class="placeholder card">
        <el-result icon="warning" title="无权访问该页面" sub-title="当前账号缺少页面入口权限，请联系管理员授权。">
          <template #extra>
            <el-button @click="router.push('/')">返回工作台</el-button>
          </template>
        </el-result>
      </div>
      <MetaListView v-else-if="schema.kind === 'object'" :object-code="schema.objectCode" />
      <PageTabs v-else-if="schema.kind === 'tabs'" :schema="schema" />
      <DashboardView v-else-if="schema.kind === 'dashboard'" :schema="schema" />
      <div v-else class="placeholder card">
        <el-empty :description="schema.description || '页面待接入'" :image-size="96">
          <el-button @click="router.push('/')">返回工作台</el-button>
        </el-empty>
      </div>
    </template>

    <div v-else class="placeholder card">
      <el-empty :description="`页面未配置：${code || '缺少页面编码'}`" :image-size="96">
        <template #default>
          <div class="placeholder-actions">
            <el-button @click="router.push('/')">
              <el-icon><ArrowLeft /></el-icon>
              返回工作台
            </el-button>
            <el-button type="primary" @click="router.go(0)">
              <el-icon><Refresh /></el-icon>
              重新加载
            </el-button>
          </div>
        </template>
      </el-empty>
    </div>
  </div>
</template>

<style scoped>
.page-view {
  height: 100%;
  min-height: 0;
}
.placeholder {
  margin: 16px;
  padding: 40px 0;
  background: var(--card);
}
.placeholder-actions {
  display: flex;
  gap: 8px;
  justify-content: center;
}
</style>
