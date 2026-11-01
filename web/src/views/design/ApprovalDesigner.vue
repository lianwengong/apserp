<template>
  <div class="approval-designer">
    <el-row :gutter="12">
      <el-col :span="7">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>审批流</span>
              <el-button size="small" type="primary" @click="newDef">新建</el-button>
            </div>
          </template>
          <el-scrollbar height="500px">
            <div
              v-for="d in defs"
              :key="d.code"
              class="def-item"
              :class="{ active: form.code === d.code }"
              @click="editDef(d)"
            >
              <div class="def-top">
                <span class="def-code">{{ d.code }}</span>
                <el-tag size="small" :type="d.status === 1 ? 'success' : 'info'" effect="plain">
                  {{ d.status === 1 ? '已发布' : '草稿' }} v{{ d.version }}
                </el-tag>
              </div>
              <div class="def-name">{{ d.name }}</div>
              <div class="def-meta">{{ d.objectCode ?? '未绑定对象' }} · {{ d.nodes.length }} 个节点</div>
            </div>
            <el-empty v-if="!defs.length" description="还没有审批流" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="17">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>{{ editing ? `编辑 ${form.code} v${form.version}` : '新建审批流' }}</span>
              <div>
                <el-button size="small" @click="preview">预览流程</el-button>
                <el-button size="small" type="primary" :loading="saving" @click="save">保存草稿</el-button>
                <el-button v-if="editing" size="small" type="success" @click="publish">发布</el-button>
              </div>
            </div>
          </template>

          <el-form :model="form" label-width="90px" size="small">
            <el-row :gutter="12">
              <el-col :span="8">
                <el-form-item label="编码" required>
                  <el-input v-model="form.code" :disabled="editing" placeholder="WF-XXX" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="名称">
                  <el-input v-model="form.name" />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="适用对象">
                  <el-select v-model="form.objectCode" clearable filterable>
                    <el-option v-for="o in objects" :key="o.code" :value="o.code" :label="`${o.code} ${o.name}`" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>
            <el-form-item label="适用条件">
              <el-input v-model="form.conditionExpr" placeholder="留空=所有单据都走此流程；否则按单据数据求值" />
            </el-form-item>
            <el-form-item label="默认流程">
              <el-switch v-model="form.isDefault" />
              <span class="hint-inline">同一对象多个流程时，条件不满足则按默认/版本降序取第一个</span>
            </el-form-item>
          </el-form>

          <el-divider content-position="left">节点（按 Sort 顺序执行）</el-divider>

          <div v-for="(node, idx) in form.nodes" :key="idx" class="node-card">
            <div class="node-head">
              <div class="node-title">
                <el-tag size="small" type="primary" effect="dark">{{ idx + 1 }}</el-tag>
                <span class="node-code">{{ node.code }}</span>
                <el-input v-model="node.name" size="small" placeholder="节点名称" style="width: 160px" />
              </div>
              <div>
                <el-button link size="small" @click="move(idx, -1)" :disabled="idx === 0">上移</el-button>
                <el-button link size="small" @click="move(idx, 1)" :disabled="idx === form.nodes.length - 1">下移</el-button>
                <el-button link size="small" type="danger" @click="form.nodes.splice(idx, 1)">删除</el-button>
              </div>
            </div>
            <el-row :gutter="8">
              <el-col :span="5">
                <el-form-item label="编码" label-width="48px">
                  <el-input v-model="node.code" size="small" />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="方式" label-width="48px">
                  <el-select v-model="node.approveMode" size="small">
                    <el-option :value="1" label="或签" />
                    <el-option :value="2" label="会签" />
                    <el-option :value="3" label="顺签" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="下一节点" label-width="66px">
                  <el-select v-model="node.nextNodeCode" size="small" clearable placeholder="按顺序">
                    <el-option v-for="n in form.nodes" :key="n.code" :value="n.code" :label="n.code" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="7">
                <el-form-item label="允许加签" label-width="66px">
                  <el-switch v-model="node.allowAddSign" />
                  <el-checkbox v-model="node.nodeTypeBool" style="margin-left: 12px">审批节点</el-checkbox>
                </el-form-item>
              </el-col>
            </el-row>
            <el-form-item label="节点条件" label-width="66px">
              <el-input v-model="node.conditionExpr" size="small" placeholder="留空=总是进入；否则按单据数据求值" />
            </el-form-item>
            <div class="approvers">
              <span class="approvers-label">审批人</span>
              <el-tag
                v-for="(a, ai) in node.approvers"
                :key="ai"
                closable
                size="small"
                :type="a.approverType === 1 ? 'primary' : 'success'"
                @close="node.approvers.splice(ai, 1)"
              >
                {{ approverLabel(a) }}
              </el-tag>
              <el-button link size="small" type="primary" @click="addApprover(node)">+ 审批人</el-button>
            </div>
          </div>

          <el-button plain size="small" @click="addNode">新增节点</el-button>

          <el-divider />
          <el-alert type="info" :closable="false" show-icon>
            保存只写草稿；<b>发布</b>后 Status=1、成为该 Code 的默认版本。已发布的流程不能被编辑，改版请新建。
            条件分支示例：N1 条件 <code>ctx.Sort &gt;= 100</code>，N2 条件 <code>ctx.Sort &lt; 100</code>，
            提交时按单据数据选中第一个满足条件的节点。
          </el-alert>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog v-model="previewVisible" title="流程预览" width="520px">
      <div class="preview">
        <div v-for="(n, i) in form.nodes" :key="i" class="preview-node">
          <div class="preview-dot">{{ i + 1 }}</div>
          <div class="preview-body">
            <div class="preview-name">{{ n.name || n.code }} <span class="muted">({{ modeName(n.approveMode) }})</span></div>
            <div class="preview-meta">
              条件：{{ n.conditionExpr || '总是进入' }} · 审批人：{{ n.approvers.map(approverLabel).join('、') || '未配置' }}
            </div>
          </div>
        </div>
        <el-empty v-if="!form.nodes.length" description="还没有节点" :image-size="50" />
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { designApi, type ApprovalDefDto } from '../../api/design'
import { metaApi } from '../../api/definition'
import type { DataObjectDto } from '../../api/types'

interface ApproverForm {
  approverType: number
  approverId: number | null
  expression: string | null
  sort: number
}
interface NodeForm {
  code: string
  name: string
  nodeType: number
  nodeTypeBool: boolean
  sort: number
  approveMode: number
  rejectMode: number
  conditionExpr: string
  allowAddSign: boolean
  nextNodeCode: string | null
  rejectNodeCode: string | null
  approvers: ApproverForm[]
}

const defs = ref<ApprovalDefDto[]>([])
const objects = ref<DataObjectDto[]>([])
const users = ref<{ id: number; userName: string; displayName: string }[]>([])
const editing = ref(false)
const saving = ref(false)
const previewVisible = ref(false)

const form = reactive({
  id: null as number | null,
  code: '',
  name: '',
  objectCode: '',
  version: 0,
  conditionExpr: '',
  isDefault: true,
  remark: '',
  nodes: [] as NodeForm[]
})

function modeName(m: number) {
  return m === 2 ? '会签' : m === 3 ? '顺签' : '或签'
}
function approverLabel(a: ApproverForm) {
  if (a.approverType === 1) {
    const u = users.value.find((x) => x.id === a.approverId)
    return u ? u.displayName || u.userName : `用户#${a.approverId}`
  }
  if (a.approverType === 3) return '部门负责人'
  if (a.approverType === 4) return '发起人'
  return '角色'
}

function newDef() {
  editing.value = false
  Object.assign(form, {
    id: null,
    code: '',
    name: '',
    objectCode: '',
    version: 0,
    conditionExpr: '',
    isDefault: true,
    remark: '',
    nodes: []
  })
  addNode()
}

function editDef(d: ApprovalDefDto) {
  editing.value = true
  Object.assign(form, {
    id: d.id,
    code: d.code,
    name: d.name,
    objectCode: d.objectCode ?? '',
    version: d.version,
    conditionExpr: d.conditionExpr ?? '',
    isDefault: d.isDefault,
    remark: d.remark ?? '',
    nodes: d.nodes.map((n) => ({
      code: n.code,
      name: n.name,
      nodeType: n.nodeType,
      nodeTypeBool: n.nodeType === 2,
      sort: n.sort,
      approveMode: n.approveMode,
      rejectMode: n.rejectMode,
      conditionExpr: n.conditionExpr ?? '',
      allowAddSign: n.allowAddSign,
      nextNodeCode: n.nextNodeCode,
      rejectNodeCode: n.rejectNodeCode,
      approvers: n.approvers.map((a) => ({
        approverType: a.approverType,
        approverId: a.approverId,
        expression: a.expression,
        sort: a.sort
      }))
    }))
  })
}

function addNode() {
  const n = form.nodes.length + 1
  form.nodes.push({
    code: `N${n}`,
    name: `审批节点 ${n}`,
    nodeType: 2,
    nodeTypeBool: true,
    sort: n * 10,
    approveMode: 1,
    rejectMode: 1,
    conditionExpr: '',
    allowAddSign: true,
    nextNodeCode: null,
    rejectNodeCode: null,
    approvers: []
  })
}

function move(idx: number, delta: number) {
  const target = idx + delta
  if (target < 0 || target >= form.nodes.length) return
  const [item] = form.nodes.splice(idx, 1)
  form.nodes.splice(target, 0, item)
  form.nodes.forEach((n, i) => (n.sort = (i + 1) * 10))
}

async function addApprover(node: NodeForm) {
  if (!users.value.length) return ElMessage.warning('没有可选用户')
  try {
    const { value } = await ElMessageBox.prompt('选择审批用户（输入显示名或用户名序号）', '加审批人', {
      inputPlaceholder: users.value.map((u, i) => `${i + 1}.${u.displayName || u.userName}`).join(' '),
      inputValidator: (v: string) => {
        const idx = Number(v)
        return Number.isInteger(idx) && idx >= 1 && idx <= users.value.length ? true : '请输入序号'
      }
    })
    const u = users.value[Number(value) - 1]
    node.approvers.push({ approverType: 1, approverId: u.id, expression: null, sort: (node.approvers.length + 1) * 10 })
  } catch {
    /* 取消 */
  }
}

function preview() {
  previewVisible.value = true
}

async function load() {
  try {
    defs.value = await designApi.approvals()
    objects.value = await metaApi.objects()
    users.value = await designApi.approvalUsers()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function payload() {
  return {
    id: form.id,
    code: form.code.trim(),
    name: form.name,
    objectCode: form.objectCode || null,
    conditionExpr: form.conditionExpr || null,
    isDefault: form.isDefault,
    remark: form.remark || null,
    nodes: form.nodes.map((n) => ({
      code: n.code,
      name: n.name,
      nodeType: n.nodeTypeBool ? 2 : 1,
      sort: n.sort,
      approveMode: n.approveMode,
      rejectMode: n.rejectMode,
      conditionExpr: n.conditionExpr || null,
      allowAddSign: n.allowAddSign,
      nextNodeCode: n.nextNodeCode,
      rejectNodeCode: n.rejectNodeCode,
      approvers: n.approvers.map((a, i) => ({ ...a, sort: (i + 1) * 10 }))
    }))
  }
}

async function save() {
  if (!form.code.trim()) return ElMessage.warning('编码必填')
  saving.value = true
  try {
    await designApi.saveApproval(payload())
    ElMessage.success('草稿已保存')
    editing.value = true
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

async function publish() {
  try {
    await ElMessageBox.confirm(`发布 ${form.code}？发布后该版本不可编辑。`, '确认', { type: 'warning' })
    await designApi.publishApproval(form.code)
    ElMessage.success('已发布')
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

onMounted(load)
</script>

<style scoped>
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.def-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.def-item:hover { background: var(--el-fill-color-light); }
.def-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.def-top { display: flex; justify-content: space-between; align-items: center; }
.def-code { font-family: Consolas, monospace; font-size: 13px; }
.def-name { font-size: 12px; margin: 2px 0; }
.def-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.node-card {
  border: 1px solid var(--el-border-color-light);
  border-radius: 8px;
  padding: 10px 12px;
  margin-bottom: 10px;
  background: var(--el-fill-color-blank);
}
.node-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.node-title { display: flex; align-items: center; gap: 8px; }
.node-code { font-family: Consolas, monospace; font-size: 12px; }
.approvers { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.approvers-label { font-size: 12px; color: var(--el-text-color-secondary); }
.hint-inline { font-size: 11px; color: var(--el-text-color-secondary); margin-left: 8px; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.preview-node { display: flex; gap: 10px; padding: 8px 0; border-bottom: 1px dashed var(--el-border-color-lighter); }
.preview-dot {
  width: 22px; height: 22px; border-radius: 50%;
  background: var(--el-color-primary); color: #fff;
  display: flex; align-items: center; justify-content: center; font-size: 12px; flex: none;
}
.preview-name { font-weight: 600; font-size: 13px; }
.preview-meta { font-size: 11px; color: var(--el-text-color-secondary); margin-top: 2px; }
</style>
