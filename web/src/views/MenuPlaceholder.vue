<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Promotion } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()

const menuName = computed(() => {
  const queryName = route.query.name
  if (typeof queryName === 'string' && queryName) return queryName
  return String(route.params.code ?? '功能页面')
})

const menuCode = computed(() => String(route.params.code ?? ''))
const menuPath = computed(() => {
  const queryPath = route.query.path
  return typeof queryPath === 'string' && queryPath ? queryPath : `/m/${menuCode.value}`
})

function openDesigner(): void {
  void router.push('/design')
}
</script>

<template>
  <div class="placeholder-page">
    <section class="card placeholder-card">
      <div class="placeholder-icon">
        <el-icon><Promotion /></el-icon>
      </div>
      <el-tag type="warning" effect="plain" size="small">菜单已登记 · 页面未绑定</el-tag>
      <h1>{{ menuName }}</h1>
      <p class="muted">
        这个功能入口已经在功能菜单里，但还没有绑定数据对象 / 页面配置，所以暂时打不开业务界面。
        在「设计器中心」里为菜单绑定页面，或先登记对应的数据对象后，这里就会自动变成可用的业务页面。
      </p>
      <dl class="meta">
        <div>
          <dt>菜单编码</dt>
          <dd class="mono">{{ menuCode }}</dd>
        </div>
        <div>
          <dt>目标路由</dt>
          <dd class="mono">{{ menuPath }}</dd>
        </div>
      </dl>
      <div class="actions">
        <el-button @click="router.push('/')">返回工作台</el-button>
        <el-button type="primary" @click="openDesigner">去设计器绑定</el-button>
      </div>
    </section>
  </div>
</template>

<style scoped>
.placeholder-page {
  display: grid;
  place-items: center;
  min-height: 100%;
  padding: 24px;
}

.placeholder-card {
  width: min(560px, 100%);
  padding: 30px 32px 26px;
}

.placeholder-icon {
  display: grid;
  place-items: center;
  width: 46px;
  height: 46px;
  margin-bottom: 12px;
  border-radius: 12px;
  background: #fff7e8;
  color: #c98a1b;
  font-size: 22px;
}

.placeholder-card h1 {
  margin: 10px 0 8px;
  font-size: 22px;
  letter-spacing: -0.01em;
}

.placeholder-card .muted {
  margin: 0;
  font-size: 12.5px;
  line-height: 1.8;
}

.meta {
  display: grid;
  gap: 8px;
  margin: 20px 0 0;
  padding: 12px 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #fafcfe;
}

.meta div {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 12px;
}

.meta dt {
  color: var(--muted);
}

.meta dd {
  margin: 0;
  color: var(--ink-2);
}

.actions {
  display: flex;
  gap: 8px;
  margin-top: 22px;
}
</style>
