<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Compass } from '@element-plus/icons-vue'

const router = useRouter()

function backHome(): void {
  void router.push('/')
}
</script>

<template>
  <div class="state-page">
    <div class="card state-card">
      <span class="state-icon"><el-icon><Compass /></el-icon></span>
      <p class="eyebrow">404 · NOT FOUND</p>
      <h1>页面不存在</h1>
      <p class="muted">
        地址可能已经变更，或该页面尚未登记到菜单。回到工作台重新选择数据对象即可。
      </p>
      <div class="state-actions">
        <el-button type="primary" @click="backHome">返回工作台</el-button>
        <el-button @click="router.back()">返回上一页</el-button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.state-page {
  display: grid;
  place-items: center;
  height: 100%;
  padding: 32px;
}

.state-card {
  width: min(520px, 100%);
  padding: 36px 36px 32px;
  text-align: center;
}

.state-icon {
  display: inline-grid;
  place-items: center;
  width: 48px;
  height: 48px;
  margin-bottom: 14px;
  border-radius: 12px;
  background: var(--brand-50);
  color: var(--brand);
  font-size: 22px;
}

.state-card h1 {
  margin: 6px 0 10px;
  font-size: 22px;
}

.state-card .muted {
  font-size: 12.5px;
  line-height: 1.8;
}

.state-actions {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-top: 22px;
}
</style>
