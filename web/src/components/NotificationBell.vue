<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Bell, Check } from '@element-plus/icons-vue'
import {
  listNotifications,
  markAllRead,
  markRead,
  unreadCount
} from '../api/notification'
import type { NotificationDto } from '../api/notification'
import { formatDateTime } from '../utils/format'

const router = useRouter()
const visible = ref(false)
const loading = ref(false)
const items = ref<NotificationDto[]>([])
const unread = ref(0)
let timer: number | undefined

const badge = computed(() => (unread.value > 99 ? '99+' : String(unread.value)))

async function refreshCount(): Promise<void> {
  try {
    const result = await unreadCount()
    unread.value = result.count
  } catch {
    // 计数失败不影响页面，下次轮询再试
  }
}

async function load(): Promise<void> {
  loading.value = true
  try {
    items.value = await listNotifications(50)
    await refreshCount()
  } finally {
    loading.value = false
  }
}

async function open(): Promise<void> {
  visible.value = true
  await load()
}

async function readOne(item: NotificationDto): Promise<void> {
  if (!item.read) {
    try {
      await markRead(item.id)
      item.read = true
      unread.value = Math.max(0, unread.value - 1)
    } catch {
      // 标记失败保持原状
    }
  }
  if (item.linkUrl) {
    visible.value = false
    void router.push(item.linkUrl)
  }
}

async function readAll(): Promise<void> {
  try {
    await markAllRead()
    items.value.forEach((item) => {
      item.read = true
    })
    unread.value = 0
  } catch {
    // 忽略：下一次刷新会回到真实状态
  }
}

function levelOf(item: NotificationDto): 'info' | 'warning' | 'error' {
  if (item.msgType === 3) return 'error'
  if (item.msgType === 2) return 'warning'
  return 'info'
}

onMounted(() => {
  void refreshCount()
  // 60s 轮询一次未读数：通知不追求秒级，避免每个页面都开长连接
  timer = window.setInterval(() => void refreshCount(), 60_000)
})

onBeforeUnmount(() => {
  if (timer) window.clearInterval(timer)
})
</script>

<template>
  <div class="notify">
    <el-badge :value="unread ? badge : ''" :max="99" :hidden="unread === 0" class="badge">
      <button class="bell" type="button" title="通知" @click="open">
        <el-icon><Bell /></el-icon>
      </button>
    </el-badge>

    <el-drawer v-model="visible" title="通知" direction="rtl" size="420px" append-to-body>
      <div class="drawer-head">
        <span class="muted">{{ unread > 0 ? `${unread} 条未读` : '全部已读' }}</span>
        <el-button text size="small" :disabled="unread === 0" @click="readAll">
          <el-icon><Check /></el-icon>
          全部已读
        </el-button>
      </div>

      <div v-loading="loading" class="list">
        <button
          v-for="item in items"
          :key="item.id"
          type="button"
          class="item"
          :class="{ unread: !item.read }"
          @click="readOne(item)"
        >
          <div class="item-head">
            <el-tag :type="levelOf(item)" size="small" effect="light">
              {{ item.msgType === 3 ? '错误' : item.msgType === 2 ? '提醒' : '通知' }}
            </el-tag>
            <span class="item-title">{{ item.title }}</span>
            <span v-if="!item.read" class="dot" />
          </div>
          <p v-if="item.content" class="item-body">{{ item.content }}</p>
          <div class="item-foot">
            <span class="muted">{{ item.at ? formatDateTime(item.at) : '' }}</span>
            <span v-if="item.linkUrl" class="link">查看 ›</span>
          </div>
        </button>
        <el-empty v-if="!loading && !items.length" description="还没有通知" :image-size="60" />
      </div>
    </el-drawer>
  </div>
</template>

<style scoped>
.notify {
  display: flex;
  align-items: center;
}

.bell {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--card);
  color: var(--ink-2);
  cursor: pointer;
  transition: border-color 0.12s ease, color 0.12s ease;
}

.bell:hover {
  border-color: var(--brand-400);
  color: var(--brand-700);
}

.badge :deep(.el-badge__content) {
  transform: translate(6px, -2px);
}

.drawer-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 4px 10px;
  font-size: 12px;
}

.list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-height: 80px;
}

.item {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--card);
  text-align: left;
  cursor: pointer;
  transition: border-color 0.12s ease, background 0.12s ease;
}

.item:hover {
  border-color: var(--brand-400);
}

.item.unread {
  background: var(--brand-50);
  border-color: var(--brand-200, var(--brand-400));
}

.item-head {
  display: flex;
  align-items: center;
  gap: 8px;
}

.item-title {
  flex: 1;
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
  line-height: 1.45;
}

.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--brand);
  flex-shrink: 0;
}

.item-body {
  margin: 0;
  font-size: 12px;
  color: var(--ink-2);
  line-height: 1.6;
  white-space: pre-wrap;
}

.item-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 11px;
}

.link {
  color: var(--brand-700);
}
</style>
