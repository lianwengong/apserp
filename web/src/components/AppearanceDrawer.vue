<template>
  <el-drawer
    v-model="visible"
    title="外观与偏好设置"
    size="400px"
    class="appearance-drawer"
    :close-on-click-modal="true"
  >
    <div class="appearance">
      <!-- 导航模式 -->
      <section class="group">
        <h4>导航模式 <span class="hint">（管结构）</span></h4>
        <div class="grid grid-3">
          <button
            v-for="item in navModeOptions"
            :key="item.key"
            type="button"
            class="opt"
            :class="{ active: state.navMode === item.key }"
            :title="item.hint"
            @click="appearance.patch({ navMode: item.key })"
          >
            {{ item.label }}
          </button>
        </div>
        <p class="tip">{{ navHint }}</p>
      </section>

      <!-- 标签栏形态 -->
      <section class="group">
        <h4>标签栏形态 <span class="hint">（管形状）</span></h4>
        <div class="grid grid-3">
          <button
            v-for="item in tabStyleOptions"
            :key="item.key"
            type="button"
            class="opt"
            :class="{ active: state.tabStyle === item.key }"
            @click="appearance.patch({ tabStyle: item.key })"
          >
            {{ item.label }}
          </button>
        </div>
      </section>

      <!-- 视觉主题配色方案 -->
      <section class="group">
        <h4>视觉主题配色方案</h4>
        <div class="grid grid-2">
          <button
            v-for="item in themePresets"
            :key="item.key"
            type="button"
            class="opt theme"
            :class="{ active: state.theme === item.key }"
            @click="appearance.patch({ theme: item.key })"
          >
            <span class="dot-color" :style="{ background: item.base }" />
            <span class="theme-label">{{ item.label }}</span>
          </button>
        </div>
      </section>

      <!-- 人民币文化色系 -->
      <section class="group">
        <h4>人民币文化色系 <span class="hint">（国风雅致）</span></h4>
        <div class="rmb-row">
          <span
            v-for="item in rmbPalette"
            :key="item.value"
            class="rmb-chip"
            :style="{ background: item.color }"
            :title="`${item.value} 元 · ${item.name}`"
          >
            {{ item.label }}
          </span>
        </div>
        <div class="rmb-samples">
          <span v-for="sample in moneySamples" :key="sample" class="rmb-sample">
            <MoneyText :value="sample" :show-symbol="true" />
          </span>
        </div>
        <el-switch
          :model-value="state.moneyTone"
          size="small"
          active-text="金额按面额着色"
          @update:model-value="(value: string | number | boolean) => appearance.patch({ moneyTone: Boolean(value) })"
        />
      </section>

      <!-- 字号 -->
      <section class="group">
        <h4>字号 <span class="hint">（适老化）</span></h4>
        <div class="grid grid-3">
          <button
            v-for="item in fontSizeOptions"
            :key="item.key"
            type="button"
            class="opt font"
            :class="{ active: state.fontSize === item.key }"
            @click="appearance.patch({ fontSize: item.key })"
          >
            <span class="font-sample" :style="{ fontSize: `${item.px}px` }">Aa</span>
            <span>{{ item.label }}</span>
          </button>
        </div>
      </section>

      <!-- 明暗模式 -->
      <section class="group">
        <h4>明暗模式</h4>
        <div class="grid grid-3">
          <button
            type="button"
            class="opt mode"
            :class="{ active: state.mode === 'light' }"
            @click="appearance.patch({ mode: 'light' })"
          >
            <el-icon><Sunny /></el-icon>
            <span>亮色</span>
          </button>
          <button
            type="button"
            class="opt mode"
            :class="{ active: state.mode === 'dark' }"
            @click="appearance.patch({ mode: 'dark' })"
          >
            <el-icon><Moon /></el-icon>
            <span>暗色</span>
          </button>
          <button
            type="button"
            class="opt mode"
            :class="{ active: state.mode === 'auto' }"
            @click="appearance.patch({ mode: 'auto' })"
          >
            <el-icon><Monitor /></el-icon>
            <span>跟随系统</span>
          </button>
        </div>
        <p class="tip">
          {{ state.mode === 'auto' ? `当前系统为${appearance.effectiveMode() === 'dark' ? '暗色' : '亮色'}，切换系统主题会自动跟随。` : '偏好会跟随账号同步到其它设备（登录后生效）。' }}
        </p>
      </section>

      <!-- 圆角风格 -->
      <section class="group">
        <h4>圆角风格</h4>
        <div class="grid grid-3">
          <button
            v-for="item in radiusOptions"
            :key="item.key"
            type="button"
            class="opt"
            :class="{ active: state.radius === item.key }"
            @click="appearance.patch({ radius: item.key })"
          >
            {{ item.label }}
          </button>
        </div>
      </section>

      <div class="footer">
        <span class="tip">设置即时生效，并按浏览器记住</span>
        <el-button @click="appearance.reset()">
          <el-icon><Refresh /></el-icon>
          恢复默认
        </el-button>
      </div>
    </div>
  </el-drawer>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Monitor, Moon, Sunny, Refresh } from '@element-plus/icons-vue'
import {
  appearance,
  fontSizeOptions,
  navModeOptions,
  radiusOptions,
  rmbPalette,
  tabStyleOptions,
  themePresets
} from '../stores/appearance'
import MoneyText from './MoneyText.vue'

defineOptions({ name: 'AppearanceDrawer' })

const props = defineProps<{ modelValue: boolean }>()
const emit = defineEmits<{ 'update:modelValue': [value: boolean] }>()

const visible = computed({
  get: () => props.modelValue,
  set: (value: boolean) => emit('update:modelValue', value)
})

const state = appearance.state
const navHint = computed(
  () => navModeOptions.find((item) => item.key === state.navMode)?.hint ?? ''
)
const moneySamples = [1288.5, 520, 128, 66, 9.9]
</script>

<style scoped>
.appearance { display: flex; flex-direction: column; gap: 22px; padding-bottom: 8px; }
.group h4 { margin: 0 0 10px; font-size: 13px; color: var(--ink); font-weight: 600; }
.hint { font-weight: 400; font-size: 11px; color: var(--muted); }
.grid { display: grid; gap: 8px; }
.grid-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.grid-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.opt {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  min-height: 40px;
  padding: 8px 10px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--card);
  color: var(--ink-2);
  font-size: 12px;
  cursor: pointer;
  transition: border-color 0.12s ease, background 0.12s ease, color 0.12s ease;
}
.opt:hover { border-color: var(--brand-400); }
.opt.active {
  border-color: var(--brand);
  background: var(--brand-50);
  color: var(--brand-700);
  box-shadow: inset 0 0 0 1px var(--brand);
  font-weight: 600;
}
.theme { justify-content: flex-start; }
.dot-color { width: 14px; height: 14px; border-radius: 50%; flex: 0 0 auto; }
.theme-label { font-size: 12px; }
.mode, .font { flex-direction: column; min-height: 58px; gap: 2px; }
.font-sample { font-weight: 650; line-height: 1.2; }
.rmb-row { display: flex; gap: 8px; align-items: center; }
.rmb-chip {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.35);
}
.rmb-samples { display: flex; gap: 12px; flex-wrap: wrap; margin: 10px 0; font-variant-numeric: tabular-nums; }
.rmb-sample { font-size: 13px; }
.tip { margin: 8px 0 0; font-size: 11px; color: var(--muted); line-height: 1.6; }
.footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding-top: 12px;
  border-top: 1px solid var(--line);
}
</style>
