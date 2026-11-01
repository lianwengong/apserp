<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Lock } from '@element-plus/icons-vue'

const router = useRouter()

function backHome(): void {
  void router.push('/')
}
</script>

<template>
  <div class="state-page">
    <div class="card state-card">
      <span class="state-icon"><el-icon><Lock /></el-icon></span>
      <p class="eyebrow">403 · FORBIDDEN</p>
      <h1>没有访问权限</h1>
      <p class="muted">
        当前账号未被授予该数据对象（或页面）的权限。请联系管理员在「角色权限」中授权后再试。
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
  background: #fdf3f2;
  color: #cf4a3e;
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
