<template>
  <div class="module-admin">
    <div class="head">
      <div>
        <h2>功能模块管理</h2>
        <p class="sub">
          维护「功能模块 → 功能点 → 动作链」。保存模块/功能点时会自动补权限点
          <code>MOD:编码</code> / <code>FUN:编码</code>，权限设计器里可直接授权。
        </p>
      </div>
      <div class="stats" v-if="stats">
        <el-tag size="small" effect="plain">模块 {{ stats.modules }}</el-tag>
        <el-tag size="small" effect="plain">功能点 {{ stats.functions }}</el-tag>
        <el-tag size="small" effect="plain">动作 {{ stats.actions }}</el-tag>
        <el-tag size="small" effect="plain">菜单 {{ stats.menus }}</el-tag>
        <el-tag size="small" effect="plain">权限点 {{ stats.permissions }}</el-tag>
      </div>
    </div>

    <el-row :gutter="12">
      <el-col :span="10">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>模块树</span>
              <div class="head-actions">
                <el-input
                  v-model="keyword"
                  size="small"
                  placeholder="搜索编码/名称"
                  clearable
                  style="width: 150px"
                  @change="loadTree"
                />
                <el-button size="small" type="primary" @click="newModule(null)">新建一级</el-button>
              </div>
            </div>
          </template>
          <el-scrollbar height="560px">
            <el-tree
              :data="tree"
              node-key="id"
              :props="{ label: 'name', children: 'children' }"
              :expand-on-click-node="false"
              :default-expanded-keys="expandedKeys"
              highlight-current
              @node-click="pickModule"
            >
              <template #default="{ data }">
                <div class="tree-node">
                  <span class="mono">{{ data.code }}</span>
                  <span class="node-name">{{ data.name }}</span>
                  <el-tag v-if="data.moduleType === 1" size="small" type="info" effect="plain">目录</el-tag>
                  <el-tag v-if="!data.enabled" size="small" type="danger" effect="plain">停用</el-tag>
                  <span class="node-meta">
                    功能 {{ data.functionCount }} · 菜单 {{ data.menuCount }}
                  </span>
                  <span class="node-ops">
                    <el-button link size="small" @click.stop="newModule(data)">加子</el-button>
                    <el-button link size="small" type="primary" @click.stop="editModule(data)">改</el-button>
                    <el-button link size="small" type="danger" @click.stop="removeModule(data)">删</el-button>
                  </span>
                </div>
              </template>
            </el-tree>
            <el-empty v-if="!tree.length" description="没有匹配的模块" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="14">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span v-if="currentModule">
                功能点 · <b class="mono">{{ currentModule.code }}</b> {{ currentModule.name }}
              </span>
              <span v-else>功能点</span>
              <el-button v-if="currentModule" size="small" type="primary" @click="newFunction">
                新建功能点
              </el-button>
            </div>
          </template>

          <div v-if="!currentModule" class="empty-tip">先选左侧模块</div>

          <template v-else>
            <el-table :data="functions" size="small" border empty-text="该模块还没有功能点">
              <el-table-column label="编码" width="180">
                <template #default="{ row }"><span class="mono">{{ row.code }}</span></template>
              </el-table-column>
              <el-table-column prop="name" label="名称" width="120" />
              <el-table-column label="类型" width="90" align="center">
                <template #default="{ row }">{{ funTypeName(row.funType) }}</template>
              </el-table-column>
              <el-table-column label="权限点" width="80" align="center">
                <template #default="{ row }">
                  <el-tag v-if="row.permissionPoint" size="small" type="success" effect="plain">有</el-tag>
                  <span v-else class="muted">—</span>
                </template>
              </el-table-column>
              <el-table-column label="动作" width="70" align="center">
                <template #default="{ row }">{{ row.actions.length }}</template>
              </el-table-column>
              <el-table-column label="操作" width="200" align="center">
                <template #default="{ row }">
                  <el-button link size="small" @click="openActions(row)">动作链</el-button>
                  <el-button link size="small" type="primary" @click="editFunction(row)">改</el-button>
                  <el-button link size="small" type="danger" @click="removeFunction(row)">删</el-button>
                </template>
              </el-table-column>
            </el-table>
          </template>
        </el-card>
      </el-col>
    </el-row>

    <!-- 模块表单 -->
    <el-dialog v-model="moduleVisible" :title="moduleForm.id ? '编辑模块' : '新建模块'" width="560px">
      <el-form :model="moduleForm" label-width="90px" size="small">
        <el-form-item label="上级模块">
          <el-tree-select
            v-model="moduleForm.parentId"
            :data="tree"
            node-key="id"
            :props="{ label: 'name', children: 'children' }"
            check-strictly
            clearable
            placeholder="不选=一级模块"
            style="width: 100%"
          />
        </el-form-item>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="编码" required>
              <el-input v-model="moduleForm.code" placeholder="01 / 01.01" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="名称" required>
              <el-input v-model="moduleForm.name" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="类型">
              <el-select v-model="moduleForm.moduleType">
                <el-option :value="1" label="目录" />
                <el-option :value="2" label="功能菜单" />
                <el-option :value="3" label="虚拟菜单" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="排序">
              <el-input-number v-model="moduleForm.sort" :step="10" :controls="false" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="英文名">
              <el-input v-model="moduleForm.enCode" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="图标">
              <el-input v-model="moduleForm.icon" placeholder="Grid" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="说明">
          <el-input v-model="moduleForm.description" />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="moduleForm.enabled" />
        </el-form-item>
        <el-form-item label="建权限点">
          <el-switch v-model="moduleForm.createPermission" />
          <span class="muted" style="margin-left: 10px">
            勾选后会补一条 <code>MOD:{{ moduleForm.code || '编码' }}</code>
          </span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="moduleVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveModule">保存</el-button>
      </template>
    </el-dialog>

    <!-- 功能点表单 -->
    <el-dialog v-model="functionVisible" :title="functionForm.id ? '编辑功能点' : '新建功能点'" width="560px">
      <el-form :model="functionForm" label-width="90px" size="small">
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="编码" required>
              <el-input v-model="functionForm.code" placeholder="01.01.VIEW" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="名称" required>
              <el-input v-model="functionForm.name" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="类型">
              <el-select v-model="functionForm.funType">
                <el-option :value="1" label="内置动作" />
                <el-option :value="2" label="自定义动作" />
                <el-option :value="3" label="脚本" />
                <el-option :value="4" label="接口" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="排序">
              <el-input-number v-model="functionForm.sort" :step="10" :controls="false" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="确认文案">
              <el-input v-model="functionForm.confirmText" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="成功提示">
              <el-input v-model="functionForm.successMessage" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="权限点">
          <el-switch v-model="functionForm.permissionPoint" />
          <span class="muted" style="margin-left: 10px">
            勾选后会补一条 <code>FUN:{{ functionForm.code || '编码' }}</code>
          </span>
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="functionForm.enabled" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="functionVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveFunction">保存</el-button>
      </template>
    </el-dialog>

    <!-- 动作链 -->
    <el-dialog v-model="actionsVisible" title="动作链" width="880px">
      <div class="muted" style="margin-bottom: 8px">
        功能点 <b class="mono">{{ actionFunction?.code }}</b> 的动作按顺序执行；整表保存即整体替换。
      </div>
      <el-table :data="actionRows" size="small" border>
        <el-table-column label="阶段" width="90">
          <template #default="{ row }">
            <el-input-number v-model="row.phase" size="small" :min="1" :max="9" :controls="false" style="width: 100%" />
          </template>
        </el-table-column>
        <el-table-column label="类型" width="110">
          <template #default="{ row }">
            <el-select v-model="row.actionType" size="small">
              <el-option :value="1" label="内置" />
              <el-option :value="2" label="导航" />
              <el-option :value="3" label="命令" />
              <el-option :value="4" label="脚本" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="动作码" width="140">
          <template #default="{ row }">
            <el-input v-model="row.actionCode" size="small" placeholder="OPEN_FORM" />
          </template>
        </el-table-column>
        <el-table-column label="目标/命令" min-width="160">
          <template #default="{ row }">
            <el-input v-if="row.actionType === 2" v-model="row.target" size="small" placeholder="/object/md.brand" />
            <el-input v-else-if="row.actionType >= 3" v-model="row.command" size="small" placeholder="export.csv" />
            <span v-else class="muted">—</span>
          </template>
        </el-table-column>
        <el-table-column label="超时(秒)" width="90">
          <template #default="{ row }">
            <el-input-number v-model="row.timeoutSeconds" size="small" :min="1" :controls="false" style="width: 100%" />
          </template>
        </el-table-column>
        <el-table-column label="失败继续" width="80" align="center">
          <template #default="{ row }"><el-checkbox v-model="row.continueOnError" /></template>
        </el-table-column>
        <el-table-column label="" width="56" align="center">
          <template #default="{ $index }">
            <el-button link type="danger" size="small" @click="actionRows.splice($index, 1)">删</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-button size="small" plain style="margin-top: 8px" @click="addAction">新增动作</el-button>
      <template #footer>
        <el-button @click="actionsVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveActions">保存动作链</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  moduleAdminApi,
  type ActionBody,
  type FunctionDto,
  type ModuleNode
} from '../../api/admin'

const tree = ref<ModuleNode[]>([])
const functions = ref<FunctionDto[]>([])
const currentModule = ref<ModuleNode | null>(null)
const keyword = ref('')
const stats = ref<Record<string, number> | null>(null)
const saving = ref(false)
const expandedKeys = ref<number[]>([])

const moduleVisible = ref(false)
const functionVisible = ref(false)
const actionsVisible = ref(false)
const actionFunction = ref<FunctionDto | null>(null)
const actionRows = ref<ActionBody[]>([])

const moduleForm = reactive({
  id: null as number | null,
  parentId: null as number | null,
  code: '',
  name: '',
  enCode: '',
  moduleType: 2,
  sort: 90,
  icon: '',
  description: '',
  enabled: true,
  createPermission: true,
  remark: ''
})

const functionForm = reactive({
  id: null as number | null,
  moduleId: 0,
  code: '',
  name: '',
  funType: 1,
  sort: 10,
  permissionPoint: true,
  confirmText: '',
  successMessage: '',
  icon: '',
  hotKey: '',
  enabled: true,
  remark: ''
})

function funTypeName(type: number): string {
  return ['', '内置动作', '自定义动作', '脚本', '接口'][type] ?? String(type)
}

async function loadTree() {
  try {
    tree.value = await moduleAdminApi.tree(keyword.value || undefined)
    stats.value = await moduleAdminApi.overview()
    if (currentModule.value) {
      const found = findNode(tree.value, currentModule.value.id)
      if (found) {
        currentModule.value = found
        functions.value = await moduleAdminApi.functions(found.id)
      }
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function findNode(nodes: ModuleNode[], id: number): ModuleNode | null {
  for (const node of nodes) {
    if (node.id === id) return node
    const hit = findNode(node.children, id)
    if (hit) return hit
  }
  return null
}

async function pickModule(data: ModuleNode) {
  currentModule.value = data
  expandedKeys.value = [data.id]
  try {
    functions.value = await moduleAdminApi.functions(data.id)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function newModule(parent: ModuleNode | null) {
  Object.assign(moduleForm, {
    id: null,
    parentId: parent ? parent.id : null,
    code: '',
    name: '',
    enCode: '',
    moduleType: parent ? 2 : 1,
    sort: 90,
    icon: '',
    description: '',
    enabled: true,
    createPermission: true,
    remark: ''
  })
  moduleVisible.value = true
}

function editModule(data: ModuleNode) {
  Object.assign(moduleForm, {
    id: data.id,
    parentId: data.parentId,
    code: data.code,
    name: data.name,
    enCode: data.enCode ?? '',
    moduleType: data.moduleType,
    sort: data.sort,
    icon: data.icon ?? '',
    description: data.description ?? '',
    enabled: data.enabled,
    createPermission: false,
    remark: ''
  })
  moduleVisible.value = true
}

async function saveModule() {
  if (!moduleForm.code.trim()) return ElMessage.warning('模块编码必填')
  if (!moduleForm.name.trim()) return ElMessage.warning('模块名称必填')
  saving.value = true
  try {
    await moduleAdminApi.save({ ...moduleForm, code: moduleForm.code.trim() })
    ElMessage.success('已保存')
    moduleVisible.value = false
    await loadTree()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

async function removeModule(data: ModuleNode) {
  try {
    await ElMessageBox.confirm(
      `删除模块 ${data.code}？若下面还有子模块/功能点会拒绝删除。`,
      '确认',
      { type: 'warning' }
    )
    await moduleAdminApi.remove(data.id)
    ElMessage.success('已删除')
    if (currentModule.value?.id === data.id) {
      currentModule.value = null
      functions.value = []
    }
    await loadTree()
  } catch (e) {
    if (e === 'cancel') return
    // 有引用时提示可用强制删除
    try {
      await ElMessageBox.confirm(`${(e as Error).message}。仍要强制删除吗？`, '强制删除', {
        type: 'warning'
      })
      await moduleAdminApi.remove(data.id, true)
      ElMessage.success('已强制删除')
      await loadTree()
    } catch (inner) {
      if (inner !== 'cancel') ElMessage.error((inner as Error).message)
    }
  }
}

function newFunction() {
  if (!currentModule.value) return
  Object.assign(functionForm, {
    id: null,
    moduleId: currentModule.value.id,
    code: '',
    name: '',
    funType: 1,
    sort: (functions.value.length + 1) * 10,
    permissionPoint: true,
    confirmText: '',
    successMessage: '',
    icon: '',
    hotKey: '',
    enabled: true,
    remark: ''
  })
  functionVisible.value = true
}

function editFunction(row: FunctionDto) {
  Object.assign(functionForm, {
    id: row.id,
    moduleId: row.moduleId,
    code: row.code,
    name: row.name,
    funType: row.funType,
    sort: row.sort,
    permissionPoint: row.permissionPoint,
    confirmText: row.confirmText ?? '',
    successMessage: row.successMessage ?? '',
    icon: row.icon ?? '',
    hotKey: row.hotKey ?? '',
    enabled: row.enabled,
    remark: row.remark ?? ''
  })
  functionVisible.value = true
}

async function saveFunction() {
  if (!functionForm.code.trim()) return ElMessage.warning('功能点编码必填')
  if (!functionForm.name.trim()) return ElMessage.warning('功能点名称必填')
  saving.value = true
  try {
    await moduleAdminApi.saveFunction({ ...functionForm, code: functionForm.code.trim() })
    ElMessage.success('已保存')
    functionVisible.value = false
    if (currentModule.value) {
      functions.value = await moduleAdminApi.functions(currentModule.value.id)
    }
    await loadTree()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

async function removeFunction(row: FunctionDto) {
  try {
    await ElMessageBox.confirm(`删除功能点 ${row.code}？`, '确认', { type: 'warning' })
    await moduleAdminApi.removeFunction(row.id)
    ElMessage.success('已删除')
    if (currentModule.value) {
      functions.value = await moduleAdminApi.functions(currentModule.value.id)
    }
    await loadTree()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

function openActions(row: FunctionDto) {
  actionFunction.value = row
  actionRows.value = row.actions.map((a) => ({
    phase: a.phase,
    actionType: a.actionType,
    actionCode: a.actionCode,
    target: a.target,
    command: a.command,
    paramJson: a.paramJson,
    continueOnError: a.continueOnError,
    errorMessage: a.errorMessage,
    timeoutSeconds: a.timeoutSeconds,
    enabled: a.enabled
  }))
  actionsVisible.value = true
}

function addAction() {
  actionRows.value.push({
    phase: 1,
    actionType: 1,
    actionCode: 'OPEN_FORM',
    target: null,
    command: null,
    paramJson: null,
    continueOnError: false,
    errorMessage: null,
    timeoutSeconds: 30,
    enabled: true
  })
}

async function saveActions() {
  if (!actionFunction.value) return
  saving.value = true
  try {
    await moduleAdminApi.saveActions(actionFunction.value.id, actionRows.value)
    ElMessage.success('动作链已保存')
    actionsVisible.value = false
    if (currentModule.value) {
      functions.value = await moduleAdminApi.functions(currentModule.value.id)
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

onMounted(loadTree)
</script>

<style scoped>
.module-admin { padding: 4px 2px; }
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 10px; }
.head h2 { margin: 0; font-size: 18px; }
.sub { margin: 4px 0 0; font-size: 12px; color: var(--el-text-color-secondary); }
.stats { display: flex; gap: 6px; flex-wrap: wrap; justify-content: flex-end; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.head-actions { display: flex; gap: 8px; align-items: center; }
.tree-node { display: flex; align-items: center; gap: 8px; width: 100%; font-size: 13px; }
.node-name { font-weight: 500; }
.node-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.node-ops { margin-left: auto; display: flex; gap: 2px; }
.mono { font-family: Consolas, monospace; font-size: 12px; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.empty-tip { color: var(--el-text-color-secondary); padding: 40px 0; text-align: center; }
</style>
