<template>
  <div class="terminal-admin">
    <div class="head">
      <div>
        <h2>终端与功能</h2>
        <p class="sub">
          先在这里给终端勾选<b>能用的功能模块</b>，菜单才有模块可选——菜单的功能模块必须属于它所在终端。
          摘掉模块时若该终端下还有菜单在用，会被拦下并列出菜单。
        </p>
      </div>
      <div class="head-actions">
        <el-checkbox v-model="onlyEnabled" size="small">只看已启用</el-checkbox>
        <el-input
          v-model="keyword"
          size="small"
          placeholder="搜索模块编码/名称"
          clearable
          style="width: 190px"
        />
        <el-button size="small" @click="reload">刷新</el-button>
      </div>
    </div>

    <el-row :gutter="12">
      <el-col :span="6">
        <el-card shadow="never" class="panel">
          <template #header><span>终端</span></template>
          <div
            v-for="t in terminals"
            :key="t.terminalType"
            class="term-item"
            :class="{ active: current === t.terminalType }"
            @click="selectTerminal(t.terminalType)"
          >
            <div class="term-top">
              <span class="term-name">{{ t.label }}</span>
              <el-tag size="small" effect="plain">{{ t.moduleCount }} 模块</el-tag>
            </div>
            <div class="term-meta">
              菜单 {{ t.menuCount }} · 功能点 {{ t.functionCount }}
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="18">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>
                <b>{{ terminalLabel(current) }}</b> 终端可用的功能模块
                <span class="muted">（勾选后保存；勾子模块会自动带上其上级）</span>
              </span>
              <div>
                <el-button size="small" @click="checkAll">全选可见</el-button>
                <el-button size="small" @click="uncheckAll">清空</el-button>
                <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
              </div>
            </div>
          </template>

          <el-scrollbar height="560px">
            <el-tree
              ref="treeRef"
              :data="treeData"
              node-key="id"
              show-checkbox
              :props="{ label: 'name', children: 'children' }"
              :default-expanded-keys="expandedKeys"
              :filter-node-method="filterNode"
              @check="onCheck"
            >
              <template #default="{ data }">
                <div class="tree-node">
                  <span class="mono">{{ data.code }}</span>
                  <span class="node-name">{{ data.name }}</span>
                  <el-tag v-if="data.level === 1" size="small" type="info" effect="plain">域</el-tag>
                  <span v-if="data.menuCount" class="node-meta">该终端菜单 {{ data.menuCount }}</span>
                  <span v-if="!data.enabled && data.menuCount" class="node-meta danger">未启用却有菜单</span>
                </div>
              </template>
            </el-tree>
          </el-scrollbar>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  terminalAdminApi,
  type TerminalDto,
  type TerminalModuleOption
} from '../../api/admin'

interface Node {
  id: number
  code: string
  name: string
  level: number
  menuCount: number
  enabled: boolean
  children: Node[]
}

const terminals = ref<TerminalDto[]>([])
const modules = ref<TerminalModuleOption[]>([])
const current = ref(1)
const keyword = ref('')
const onlyEnabled = ref(false)
const saving = ref(false)
const treeRef = ref()
const expandedKeys = ref<number[]>([])

const terminalLabel = (t: number) =>
  terminals.value.find((x) => x.terminalType === t)?.label ?? `终端${t}`

function buildTree(list: TerminalModuleOption[]): Node[] {
  const map = new Map<number, Node>()
  for (const m of list) {
    map.set(m.id, {
      id: m.id,
      code: m.code,
      name: m.name,
      level: m.level,
      menuCount: m.menuCount,
      enabled: m.enabled,
      children: []
    })
  }
  const roots: Node[] = []
  for (const m of list) {
    const node = map.get(m.id)!
    const parent = m.parentId ? map.get(m.parentId) : undefined
    if (parent) parent.children.push(node)
    else roots.push(node)
  }
  return roots
}

const treeData = computed<Node[]>(() => buildTree(modules.value))

async function loadTerminals() {
  try {
    const overview = await terminalAdminApi.overview()
    terminals.value = overview.terminals
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function loadModules() {
  try {
    modules.value = await terminalAdminApi.allModules(current.value)
    expandedKeys.value = modules.value.filter((m) => m.level <= 1).map((m) => m.id)
    // 回填勾选状态：只勾叶子/已启用节点，父节点交给 el-tree 自己算
    // 只勾叶子：勾父节点会级联把所有子模块一起勾上（那等于误开一堆功能）
    const parentIds = new Set(modules.value.map((m) => m.parentId).filter(Boolean) as number[])
    const leafIds = modules.value
      .filter((m) => m.enabled && !parentIds.has(m.id))
      .map((m) => m.id)
    await nextTick()
    treeRef.value?.setCheckedKeys(leafIds, false)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function selectTerminal(t: number) {
  if (saving.value) return
  current.value = t
  await loadModules()
}

async function reload() {
  await loadTerminals()
  await loadModules()
}

function filterNode(value: string, data: Node) {
  // 只看已启用：父节点由「子模块启用则父必启用」保证，禁用节点可以直接隐藏
  if (onlyEnabled.value && !data.enabled) return false
  if (!value) return true
  const key = value.toLowerCase()
  return data.code.toLowerCase().includes(key) || data.name.toLowerCase().includes(key)
}

watch([keyword, onlyEnabled], ([value]) => treeRef.value?.filter(value))

/** 勾选父节点时把子节点带上（el-tree 默认行为），这里只做提示性统计 */
function onCheck() {
  // 勾选状态由 el-tree 维护，保存时统一读取
}

function checkAll() {
  treeRef.value?.setCheckedKeys(modules.value.map((m) => m.id), false)
}

function uncheckAll() {
  treeRef.value?.setCheckedKeys([], false)
}

async function save() {
  const ids: number[] = treeRef.value?.getCheckedKeys(false) ?? []
  saving.value = true
  try {
    modules.value = await terminalAdminApi.saveModules(current.value, ids)
    await loadTerminals()
    ElMessage.success('已保存，该终端下的菜单只能选这些模块')
  } catch (e) {
    try {
      await ElMessageBox.alert((e as Error).message, '保存被拦下', { type: 'warning' })
    } catch {
      // 用户关闭弹窗即可
    }
  } finally {
    saving.value = false
  }
}

onMounted(reload)
</script>

<style scoped>
.terminal-admin { padding: 4px 2px; }
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 10px; }
.head h2 { margin: 0; font-size: 18px; }
.sub { margin: 4px 0 0; font-size: 12px; color: var(--el-text-color-secondary); max-width: 900px; }
.head-actions { display: flex; gap: 8px; align-items: center; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.term-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; margin-bottom: 6px; }
.term-item:hover { background: var(--el-fill-color-light); }
.term-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.term-top { display: flex; align-items: center; justify-content: space-between; }
.term-name { font-weight: 600; }
.term-meta { font-size: 11px; color: var(--el-text-color-secondary); margin-top: 2px; }
.tree-node { display: flex; align-items: center; gap: 8px; font-size: 13px; width: 100%; }
.node-name { font-weight: 500; }
.node-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.mono { font-family: Consolas, monospace; font-size: 12px; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.danger { color: var(--el-color-danger); }
</style>
