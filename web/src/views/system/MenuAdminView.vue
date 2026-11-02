<template>
  <div class="menu-admin">
    <div class="head">
      <div>
        <h2>菜单设置</h2>
        <p class="sub">
          侧边栏渲染的就是这棵树：改完立即生效。绑定页面但没写路由时自动补
          <code>/m/菜单编码</code>；「终端」控制该菜单在哪些设备上出现。
        </p>
      </div>
      <div class="head-actions">
        <el-input
          v-model="keyword"
          size="small"
          placeholder="搜索编码/名称"
          clearable
          style="width: 160px"
          @change="loadTree"
        />
        <el-select
          v-model="moduleFilter"
          size="small"
          clearable
          filterable
          placeholder="按模块过滤"
          style="width: 200px"
          @change="loadTree"
        >
          <el-option v-for="m in options.modules" :key="m.id" :value="m.id" :label="`${m.code} ${m.name}`" />
        </el-select>
        <el-button size="small" type="primary" @click="newMenu(null)">新建一级菜单</el-button>
      </div>
    </div>

    <el-row :gutter="12">
      <el-col :span="11">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>菜单树（含停用/隐藏）</span>
              <span class="muted">共 {{ total }} 个节点</span>
            </div>
          </template>
          <el-scrollbar height="580px">
            <el-tree
              :data="tree"
              node-key="id"
              :props="{ label: 'name', children: 'children' }"
              :expand-on-click-node="false"
              default-expand-all
              highlight-current
              @node-click="pick"
            >
              <template #default="{ data }">
                <div class="tree-node">
                  <span class="mono">{{ data.code }}</span>
                  <span class="node-name">{{ data.name }}</span>
                  <el-tag v-if="data.menuType === 1" size="small" type="info" effect="plain">目录</el-tag>
                  <el-tag v-if="!data.enabled" size="small" type="danger" effect="plain">停用</el-tag>
                  <el-tag v-else-if="!data.visible" size="small" type="warning" effect="plain">隐藏</el-tag>
                  <span v-if="data.pageCode" class="node-meta">页 {{ data.pageCode }}</span>
                  <span class="node-ops">
                    <el-button link size="small" @click.stop="newMenu(data)">加子</el-button>
                    <el-button link size="small" @click.stop="moveUp(data)">↑</el-button>
                    <el-button link size="small" @click.stop="moveDown(data)">↓</el-button>
                    <el-button link size="small" type="primary" @click.stop="editMenu(data)">改</el-button>
                    <el-button link size="small" type="danger" @click.stop="removeMenu(data)">删</el-button>
                  </span>
                </div>
              </template>
            </el-tree>
            <el-empty v-if="!tree.length" description="没有匹配的菜单" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="13">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>菜单详情</span>
              <el-button v-if="current" size="small" type="primary" @click="editMenu(current)">
                编辑此菜单
              </el-button>
            </div>
          </template>

          <div v-if="!current" class="empty-tip">先选左侧菜单查看详情，或直接新建</div>

          <el-descriptions v-else :column="2" border size="small">
            <el-descriptions-item label="编码">
              <span class="mono">{{ current.code }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="名称">{{ current.name }}</el-descriptions-item>
            <el-descriptions-item label="类型">{{ menuTypeName(current.menuType) }}</el-descriptions-item>
            <el-descriptions-item label="路由">
              <span class="mono">{{ current.route || '—' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="模块">
              {{ current.moduleCode || '—' }}
            </el-descriptions-item>
            <el-descriptions-item label="页面">
              {{ current.pageCode || '—' }}
            </el-descriptions-item>
            <el-descriptions-item label="打开方式">{{ openModeName(current.openMode) }}</el-descriptions-item>
            <el-descriptions-item label="排序">{{ current.sort }}</el-descriptions-item>
            <el-descriptions-item label="可见">
              <el-tag size="small" :type="current.visible ? 'success' : 'info'">
                {{ current.visible ? '显示' : '隐藏' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="启用">
              <el-tag size="small" :type="current.enabled ? 'success' : 'danger'">
                {{ current.enabled ? '启用' : '停用' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="终端" :span="2">
              <el-tag
                v-for="t in currentTerminals"
                :key="t"
                size="small"
                effect="plain"
                style="margin-right: 6px"
              >
                {{ terminalName(t) }}
              </el-tag>
              <span v-if="!currentTerminals.length" class="muted">未限制（所有终端可见）</span>
            </el-descriptions-item>
            <el-descriptions-item label="角标表达式" :span="2">
              <span class="mono">{{ current.badgeExpr || '—' }}</span>
            </el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog v-model="formVisible" :title="form.id ? '编辑菜单' : '新建菜单'" width="620px">
      <el-form :model="form" label-width="96px" size="small">
        <el-form-item label="上级菜单">
          <el-tree-select
            v-model="form.parentId"
            :data="tree"
            node-key="id"
            :props="{ label: 'name', children: 'children' }"
            check-strictly
            clearable
            placeholder="不选=一级菜单"
            style="width: 100%"
          />
        </el-form-item>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="编码" required>
              <el-input v-model="form.code" placeholder="01.01.01" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="名称" required>
              <el-input v-model="form.name" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="类型">
              <el-select v-model="form.menuType">
                <el-option v-for="t in options.menuTypes" :key="t.value" :value="t.value" :label="t.label" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="排序">
              <el-input-number v-model="form.sort" :step="10" :controls="false" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="绑定模块">
              <el-select v-model="form.moduleId" clearable filterable placeholder="可不绑">
                <el-option
                  v-for="m in options.modules"
                  :key="m.id"
                  :value="m.id"
                  :label="`${m.code} ${m.name}`"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="绑定页面">
              <el-select v-model="form.pageId" clearable filterable placeholder="可不绑">
                <el-option
                  v-for="p in options.pages"
                  :key="p.id"
                  :value="p.id"
                  :label="`${p.code} ${p.name}`"
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="路由">
          <el-input v-model="form.route" placeholder="留空且绑了页面时自动生成 /m/编码" />
        </el-form-item>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="图标">
              <el-input v-model="form.icon" placeholder="Grid" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="打开方式">
              <el-select v-model="form.openMode">
                <el-option v-for="o in options.openModes" :key="o.value" :value="o.value" :label="o.label" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="角标表达式">
          <el-input v-model="form.badgeExpr" placeholder="ctx.PendingCount > 0" />
        </el-form-item>
        <el-form-item label="终端可见">
          <el-checkbox-group v-model="form.terminals">
            <el-checkbox v-for="t in options.terminalTypes" :key="t.value" :value="t.value">
              {{ t.label }}
            </el-checkbox>
          </el-checkbox-group>
          <div class="muted">不勾=所有终端可见</div>
        </el-form-item>
        <el-form-item label="显示">
          <el-switch v-model="form.visible" />
          <span class="muted" style="margin-left: 16px">启用</span>
          <el-switch v-model="form.enabled" style="margin-left: 8px" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { menuAdminApi, type MenuNode, type OptionDto } from '../../api/admin'

const tree = ref<MenuNode[]>([])
const current = ref<MenuNode | null>(null)
const currentTerminals = ref<number[]>([])
const keyword = ref('')
const moduleFilter = ref<number | null>(null)
const saving = ref(false)
const formVisible = ref(false)

const options = reactive<{
  modules: OptionDto[]
  pages: OptionDto[]
  menuTypes: { value: number; label: string }[]
  openModes: { value: number; label: string }[]
  terminalTypes: { value: number; label: string }[]
}>({
  modules: [],
  pages: [],
  menuTypes: [],
  openModes: [],
  terminalTypes: []
})

const form = reactive({
  id: null as number | null,
  parentId: null as number | null,
  code: '',
  name: '',
  menuType: 2,
  moduleId: null as number | null,
  pageId: null as number | null,
  route: '',
  icon: '',
  sort: 90,
  visible: true,
  openMode: 1,
  badgeExpr: '',
  enabled: true,
  remark: '',
  terminals: [] as number[]
})

const total = computed(() => countNodes(tree.value))

function countNodes(nodes: MenuNode[]): number {
  return nodes.reduce((sum, node) => sum + 1 + countNodes(node.children), 0)
}

function menuTypeName(type: number): string {
  const hit = options.menuTypes.find((t) => t.value === type)
  return hit ? hit.label : String(type)
}
function openModeName(mode: number): string {
  const hit = options.openModes.find((o) => o.value === mode)
  return hit ? hit.label : String(mode)
}
function terminalName(type: number): string {
  const hit = options.terminalTypes.find((t) => t.value === type)
  return hit ? hit.label : `终端${type}`
}

async function loadTree() {
  try {
    tree.value = await menuAdminApi.tree({
      keyword: keyword.value || undefined,
      moduleId: moduleFilter.value ?? undefined
    })
    if (current.value) {
      const found = findNode(tree.value, current.value.id)
      current.value = found
      if (found) currentTerminals.value = await menuAdminApi.terminals(found.id)
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function findNode(nodes: MenuNode[], id: number): MenuNode | null {
  for (const node of nodes) {
    if (node.id === id) return node
    const hit = findNode(node.children, id)
    if (hit) return hit
  }
  return null
}

async function pick(data: MenuNode) {
  current.value = data
  try {
    currentTerminals.value = await menuAdminApi.terminals(data.id)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function newMenu(parent: MenuNode | null) {
  Object.assign(form, {
    id: null,
    parentId: parent ? parent.id : null,
    code: '',
    name: '',
    menuType: parent ? 2 : 1,
    moduleId: parent?.moduleId ?? null,
    pageId: null,
    route: '',
    icon: '',
    sort: 90,
    visible: true,
    openMode: 1,
    badgeExpr: '',
    enabled: true,
    remark: '',
    terminals: []
  })
  formVisible.value = true
}

async function editMenu(data: MenuNode) {
  Object.assign(form, {
    id: data.id,
    parentId: data.parentId,
    code: data.code,
    name: data.name,
    menuType: data.menuType,
    moduleId: data.moduleId,
    pageId: data.pageId,
    route: data.route ?? '',
    icon: data.icon ?? '',
    sort: data.sort,
    visible: data.visible,
    openMode: data.openMode,
    badgeExpr: data.badgeExpr ?? '',
    enabled: data.enabled,
    remark: data.remark ?? '',
    terminals: await menuAdminApi.terminals(data.id).catch(() => [])
  })
  formVisible.value = true
}

async function save() {
  if (!form.code.trim()) return ElMessage.warning('菜单编码必填')
  if (!form.name.trim()) return ElMessage.warning('菜单名称必填')
  saving.value = true
  try {
    await menuAdminApi.save({ ...form, code: form.code.trim() })
    ElMessage.success('已保存，侧边栏立即生效')
    formVisible.value = false
    await loadTree()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

async function removeMenu(data: MenuNode) {
  try {
    await ElMessageBox.confirm(`删除菜单 ${data.code}？有子菜单时会被拒绝。`, '确认', {
      type: 'warning'
    })
    await menuAdminApi.remove(data.id)
    ElMessage.success('已删除')
    if (current.value?.id === data.id) current.value = null
    await loadTree()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

/** 上移/下移：与相邻兄弟交换 Sort，最多挪一位，避免手工算排序值。 */
async function moveUp(data: MenuNode) {
  await shift(data, -1)
}
async function moveDown(data: MenuNode) {
  await shift(data, 1)
}

async function shift(data: MenuNode, delta: number) {
  const siblings = data.parentId
    ? (findNode(tree.value, data.parentId)?.children ?? [])
    : tree.value
  const index = siblings.findIndex((s) => s.id === data.id)
  const target = index + delta
  if (index < 0 || target < 0 || target >= siblings.length) return
  const other = siblings[target]
  const selfSort = data.sort
  const otherSort = other.sort
  try {
    await menuAdminApi.move({ id: data.id, parentId: data.parentId, sort: otherSort })
    await menuAdminApi.move({ id: other.id, parentId: other.parentId, sort: selfSort })
    await loadTree()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

onMounted(async () => {
  try {
    const opt = await menuAdminApi.options()
    options.modules = opt.modules
    options.pages = opt.pages
    options.menuTypes = opt.menuTypes
    options.openModes = opt.openModes
    options.terminalTypes = opt.terminalTypes
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
  await loadTree()
})
</script>

<style scoped>
.menu-admin { padding: 4px 2px; }
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 10px; }
.head h2 { margin: 0; font-size: 18px; }
.sub { margin: 4px 0 0; font-size: 12px; color: var(--el-text-color-secondary); }
.head-actions { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; justify-content: flex-end; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.tree-node { display: flex; align-items: center; gap: 8px; width: 100%; font-size: 13px; }
.node-name { font-weight: 500; }
.node-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.node-ops { margin-left: auto; display: flex; gap: 2px; }
.mono { font-family: Consolas, monospace; font-size: 12px; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.empty-tip { color: var(--el-text-color-secondary); padding: 40px 0; text-align: center; }
</style>
