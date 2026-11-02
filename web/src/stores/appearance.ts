import { reactive } from 'vue'
import { preferenceApi } from '../api/preference'

/** 导航模式：侧栏导航（完整菜单） / 图标导航（域图标 + 弹出菜单） / 顶栏导航（一级菜单横排） */
export type NavMode = 'side' | 'tree' | 'top'
/** 标签栏形态：经典 / 梯形书签 / 圆角卡片 / 直角复古 / 下划线 */
export type TabStyle = 'classic' | 'trapezoid' | 'card' | 'retro' | 'underline'
/** 视觉主题配色方案（11 套） */
export type ThemeKey =
  | 'emerald'
  | 'teal'
  | 'mist'
  | 'silver'
  | 'obsidian'
  | 'amber'
  | 'forest'
  | 'terracotta'
  | 'sand'
  | 'cyber'
  | 'rose'
export type ColorMode = 'light' | 'dark' | 'auto'
/** 字号：标准 / 大 / 特大 */
export type FontSize = 'standard' | 'large' | 'xlarge'
/** 圆角风格：直角 / 默认 / 圆润 */
export type RadiusStyle = 'square' | 'default' | 'round'

export interface AppearanceState {
  navMode: NavMode
  tabStyle: TabStyle
  theme: ThemeKey
  mode: ColorMode
  fontSize: FontSize
  radius: RadiusStyle
  /** 金额按人民币面额着色 */
  moneyTone: boolean
}

const STORAGE_KEY = 'apserp.appearance.v2'
const LEGACY_KEY = 'apserp.appearance'

const DEFAULTS: AppearanceState = {
  navMode: 'side',
  tabStyle: 'classic',
  theme: 'emerald',
  mode: 'light',
  fontSize: 'standard',
  radius: 'default',
  moneyTone: true
}

// ---------------------------------------------------------------- 主题预设

interface ThemePreset {
  key: ThemeKey
  label: string
  hint: string
  /** 主色（品牌色） */
  base: string
}

export const themePresets: ThemePreset[] = [
  { key: 'emerald', label: '墨绿·商务', hint: '默认', base: '#1f7a5c' },
  { key: 'teal', label: '青绿·现代', hint: '清爽', base: '#0f8b8d' },
  { key: 'mist', label: '雾蓝·沉静', hint: '稳重', base: '#4a6fa5' },
  { key: 'silver', label: '银灰·极简', hint: '克制', base: '#6b7785' },
  { key: 'obsidian', label: '曜石·质感', hint: '暗调', base: '#2f3a46' },
  { key: 'amber', label: '暖橙·亲和', hint: '零售', base: '#c9761f' },
  { key: 'forest', label: '森绿·权威', hint: '财务', base: '#2f6b3f' },
  { key: 'terracotta', label: '赤陶·复古', hint: '国风', base: '#a8532f' },
  { key: 'sand', label: '暖石·温润', hint: '柔和', base: '#8a7355' },
  { key: 'cyber', label: '赛博青·科技', hint: '科技', base: '#0aa5b5' },
  { key: 'rose', label: '玫瑰红·营销', hint: '活动', base: '#c2456a' }
]

/**
 * 人民币文化色系：按面额给金额上色。
 * 只在「金额按面额着色」开启时生效，避免所有数字都花花绿绿。
 */
export const rmbPalette: { value: number; label: string; name: string; color: string }[] = [
  { value: 100, label: '100', name: '朱砂', color: '#b93a32' },
  { value: 50, label: '50', name: '苍翠', color: '#6e8b3d' },
  { value: 20, label: '20', name: '赭石', color: '#8c5a2b' },
  { value: 10, label: '10', name: '靛青', color: '#3f5b8c' },
  { value: 5, label: '5', name: '藕荷', color: '#7a4e8c' },
  { value: 1, label: '1', name: '栗棕', color: '#6b4a2f' }
]

export const navModeOptions: { key: NavMode; label: string; hint: string }[] = [
  { key: 'side', label: '侧栏导航', hint: '完整菜单常驻左侧，可折叠' },
  { key: 'tree', label: '图标导航', hint: '窄图标栏按域分组，点图标弹出菜单' },
  { key: 'top', label: '顶栏导航', hint: '一级菜单横排，内容区更宽' }
]

export const tabStyleOptions: { key: TabStyle; label: string }[] = [
  { key: 'classic', label: '经典' },
  { key: 'trapezoid', label: '梯形书签' },
  { key: 'card', label: '圆角卡片' },
  { key: 'retro', label: '直角复古' },
  { key: 'underline', label: '下划线' }
]

export const fontSizeOptions: { key: FontSize; label: string; px: number }[] = [
  { key: 'standard', label: '标准', px: 13 },
  { key: 'large', label: '大', px: 14 },
  { key: 'xlarge', label: '特大', px: 16 }
]

export const radiusOptions: { key: RadiusStyle; label: string; px: number; small: number }[] = [
  { key: 'square', label: '直角', px: 2, small: 2 },
  { key: 'default', label: '默认', px: 10, small: 6 },
  { key: 'round', label: '圆润', px: 16, small: 10 }
]

// ---------------------------------------------------------------- 颜色计算

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value))
}

function parseHex(hex: string): [number, number, number] {
  const text = hex.replace('#', '')
  const full = text.length === 3 ? text.split('').map((c) => c + c).join('') : text
  return [
    parseInt(full.slice(0, 2), 16),
    parseInt(full.slice(2, 4), 16),
    parseInt(full.slice(4, 6), 16)
  ]
}

function toHex(rgb: [number, number, number]): string {
  return '#' + rgb.map((v) => clamp(Math.round(v), 0, 255).toString(16).padStart(2, '0')).join('')
}

/** 与白色/黑色混合：ratio=0 原色，1 目标色 */
function mix(hex: string, target: string, ratio: number): string {
  const a = parseHex(hex)
  const b = parseHex(target)
  return toHex([a[0] + (b[0] - a[0]) * ratio, a[1] + (b[1] - a[1]) * ratio, a[2] + (b[2] - a[2]) * ratio])
}

/** 由主色推导整套品牌色阶与 Element Plus 主题变量 */
function scaleOf(base: string): Record<string, string> {
  return {
    '--brand-900': mix(base, '#000000', 0.45),
    '--brand-700': mix(base, '#000000', 0.22),
    '--brand': base,
    '--brand-400': mix(base, '#ffffff', 0.28),
    '--brand-100': mix(base, '#ffffff', 0.82),
    '--brand-50': mix(base, '#ffffff', 0.93),
    '--el-color-primary': base,
    '--el-color-primary-light-3': mix(base, '#ffffff', 0.3),
    '--el-color-primary-light-5': mix(base, '#ffffff', 0.5),
    '--el-color-primary-light-7': mix(base, '#ffffff', 0.7),
    '--el-color-primary-light-8': mix(base, '#ffffff', 0.8),
    '--el-color-primary-light-9': mix(base, '#ffffff', 0.92),
    '--el-color-primary-dark-2': mix(base, '#000000', 0.2)
  }
}

export function presetOf(key: ThemeKey): ThemePreset {
  return themePresets.find((item) => item.key === key) ?? themePresets[0]
}

// ---------------------------------------------------------------- 状态与读写

function pick<T extends string>(value: unknown, allowed: readonly T[], fallback: T): T {
  return typeof value === 'string' && (allowed as readonly string[]).includes(value)
    ? (value as T)
    : fallback
}

function read(): AppearanceState {
  const fallback = { ...DEFAULTS }
  try {
    const raw = localStorage.getItem(STORAGE_KEY) ?? localStorage.getItem(LEGACY_KEY)
    if (!raw) return fallback
    const parsed = JSON.parse(raw) as Partial<AppearanceState> & { mode?: string }
    return {
      navMode: pick(parsed.navMode, ['side', 'tree', 'top'], DEFAULTS.navMode),
      tabStyle: pick(parsed.tabStyle, ['classic', 'trapezoid', 'card', 'retro', 'underline'], DEFAULTS.tabStyle),
      theme: pick(parsed.theme, themePresets.map((t) => t.key), DEFAULTS.theme),
      mode: parsed.mode === 'dark' || parsed.mode === 'auto' ? parsed.mode : 'light',
      fontSize: pick(parsed.fontSize, ['standard', 'large', 'xlarge'], DEFAULTS.fontSize),
      radius: pick(parsed.radius, ['square', 'default', 'round'], DEFAULTS.radius),
      moneyTone: parsed.moneyTone !== false
    }
  } catch {
    return fallback
  }
}

const state = reactive<AppearanceState>(read())

/**
 * 把偏好写到 <html> 上：
 * - data-* 供 CSS 选择器使用（布局、标签栏、字号、圆角、导航模式）
 * - 内联 CSS 变量承载主题色阶（11 套主题不必写 11 段 CSS）
 * - dark 类供 Element Plus 官方暗色变量接管
 */
const darkQuery = typeof window !== 'undefined' && window.matchMedia
  ? window.matchMedia('(prefers-color-scheme: dark)')
  : null

/** 系统是否深色：用响应式对象承载，界面（如抽屉提示）才能跟着系统切换重绘 */
export const systemDark = reactive({ value: darkQuery?.matches ?? false })

/** 实际生效的明暗：auto 时跟随系统 */
export function effectiveMode(): 'light' | 'dark' {
  if (state.mode !== 'auto') return state.mode
  return systemDark.value ? 'dark' : 'light'
}

export function applyAppearance(): void {
  if (typeof document === 'undefined') return
  const root = document.documentElement
  const mode = effectiveMode()
  root.dataset.theme = state.theme
  root.dataset.mode = mode
  root.dataset.modePreference = state.mode
  root.dataset.nav = state.navMode
  root.dataset.tabs = state.tabStyle
  root.dataset.font = state.fontSize
  root.dataset.radius = state.radius
  root.dataset.moneyTone = state.moneyTone ? 'on' : 'off'
  root.classList.toggle('dark', mode === 'dark')
  root.style.colorScheme = mode

  for (const [name, value] of Object.entries(scaleOf(presetOf(state.theme).base))) {
    root.style.setProperty(name, value)
  }
  const radius = radiusOptions.find((item) => item.key === state.radius) ?? radiusOptions[1]
  root.style.setProperty('--radius', `${radius.px}px`)
  root.style.setProperty('--el-border-radius-base', `${radius.small}px`)
  const font = fontSizeOptions.find((item) => item.key === state.fontSize) ?? fontSizeOptions[0]
  root.style.setProperty('--app-font-size', `${font.px}px`)
  root.style.setProperty('--el-font-size-base', `${font.px}px`)
  for (const item of rmbPalette) {
    root.style.setProperty(`--rmb-${item.value}`, item.color)
  }
}

function persist(): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
  } catch {
    // 隐私模式下不影响使用
  }
}

export function patchAppearance(patch: Partial<AppearanceState>): void {
  Object.assign(state, patch)
  applyAppearance()
  persist()
  schedulePush()
}

export function resetAppearance(): void {
  Object.assign(state, DEFAULTS)
  applyAppearance()
  persist()
  schedulePush()
}

if (darkQuery) {
  darkQuery.addEventListener('change', (event) => {
    systemDark.value = event.matches
    if (state.mode === 'auto') applyAppearance()
  })
}

applyAppearance()

// ---------------------------------------------------------------- 跨设备同步

let syncing = false
let pushTimer: number | null = null

/** 登录后调用：把服务端偏好合并进来（没有或拉取失败就沿用本地值） */
export async function loadRemoteAppearance(): Promise<void> {
  try {
    const all = await preferenceApi.all()
    const raw = all.appearance
    if (!raw) return
    const parsed = JSON.parse(raw) as Partial<AppearanceState>
    syncing = true
    Object.assign(state, {
      navMode: pick(parsed.navMode, ['side', 'tree', 'top'], state.navMode),
      tabStyle: pick(parsed.tabStyle, ['classic', 'trapezoid', 'card', 'retro', 'underline'], state.tabStyle),
      theme: pick(parsed.theme, themePresets.map((t) => t.key), state.theme),
      mode: parsed.mode === 'dark' || parsed.mode === 'auto' ? parsed.mode : 'light',
      fontSize: pick(parsed.fontSize, ['standard', 'large', 'xlarge'], state.fontSize),
      radius: pick(parsed.radius, ['square', 'default', 'round'], state.radius),
      moneyTone: parsed.moneyTone !== false
    })
    applyAppearance()
    persist()
  } catch {
    // 未登录或网络失败：本地偏好照样生效
  } finally {
    syncing = false
  }
}

/** 防抖回写服务端：连点主题卡片不会打一串请求 */
function schedulePush(): void {
  if (syncing || typeof window === 'undefined') return
  if (pushTimer !== null) window.clearTimeout(pushTimer)
  pushTimer = window.setTimeout(() => {
    pushTimer = null
    void preferenceApi.save('appearance', JSON.stringify(state)).catch(() => undefined)
  }, 800)
}

export const appearance = {
  state,
  patch: patchAppearance,
  reset: resetAppearance,
  apply: applyAppearance,
  loadRemote: loadRemoteAppearance,
  effectiveMode,
  systemDark,
  defaults: DEFAULTS
}
