<template>
  <div class="print-designer">
    <el-alert type="info" :closable="false" show-icon class="tip">
      打印模板 = HTML + 占位符。<code v-pre>{{Field}}</code> 取主表字段，
      <code v-pre>{{#Contacts}}…{{/Contacts}}</code> 是子表区块（区块内字段先取子行）。
      占位符输出一律转义，模板里可以直接写 CSS；渲染结果在浏览器里打印或另存 PDF。
    </el-alert>

    <el-row :gutter="12">
      <el-col :span="7">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>模板</span>
              <el-button size="small" type="primary" @click="newTemplate">新建</el-button>
            </div>
          </template>
          <el-select v-model="objectCode" size="small" filterable style="width: 100%; margin-bottom: 8px" @change="loadTemplates">
            <el-option v-for="o in objects" :key="o.code" :value="o.code" :label="`${o.code} ${o.name}`" />
          </el-select>
          <el-scrollbar height="430px">
            <div
              v-for="t in templates"
              :key="t.id"
              class="tpl-item"
              :class="{ active: form.id === t.id }"
              @click="edit(t)"
            >
              <div class="tpl-top">
                <span class="mono">{{ t.code }}</span>
                <el-tag v-if="t.isDefault" size="small" type="success" effect="plain">默认</el-tag>
              </div>
              <div class="tpl-name">{{ t.name }}</div>
              <div class="tpl-meta">{{ t.paperSize }} · {{ t.enabled ? '启用' : '停用' }}</div>
            </div>
            <el-empty v-if="!templates.length" description="该对象还没有打印模板" :image-size="60" />
          </el-scrollbar>
        </el-card>
      </el-col>

      <el-col :span="17">
        <el-card shadow="never" class="panel">
          <template #header>
            <div class="panel-head">
              <span>{{ editing ? `编辑 ${form.code}` : '新建模板' }}</span>
              <div>
                <el-button size="small" @click="preview">预览（取一条真实单据）</el-button>
                <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
                <el-button v-if="editing" size="small" type="danger" plain @click="remove">删除</el-button>
              </div>
            </div>
          </template>

          <el-form :model="form" label-width="88px" size="small">
            <el-row :gutter="12">
              <el-col :span="9">
                <el-form-item label="编码" required>
                  <el-input v-model="form.code" :disabled="editing" placeholder="pt.brand" />
                </el-form-item>
              </el-col>
              <el-col :span="9">
                <el-form-item label="名称" required>
                  <el-input v-model="form.name" placeholder="品牌档案打印" />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="纸张">
                  <el-select v-model="form.paperSize">
                    <el-option value="A4" label="A4" />
                    <el-option value="A5" label="A5" />
                    <el-option value="A3" label="A3" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>
            <el-form-item label="默认模板">
              <el-switch v-model="form.isDefault" />
              <span class="muted" style="margin-left: 10px">同一对象只能有一个默认模板</span>
            </el-form-item>

            <el-form-item label="模板内容" required>
              <el-input v-model="form.content" type="textarea" :rows="16" spellcheck="false" class="mono-input" />
            </el-form-item>

            <el-form-item label="可用占位符">
              <el-space wrap>
                <el-tag
                  v-for="p in placeholders"
                  :key="p"
                  size="small"
                  effect="plain"
                  class="ph"
                  @click="insertPlaceholder(p)"
                >
                  {{ phLabel(p) }}
                </el-tag>
              </el-space>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog v-model="previewVisible" title="打印预览" width="820px" top="4vh">
      <iframe :srcdoc="previewHtml" class="preview-frame" />
      <template #footer>
        <el-button @click="previewVisible = false">关闭</el-button>
        <el-button type="primary" @click="printPreview">打印</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { designApi, type PrintTemplateDto } from '../../api/design'
import { metaApi } from '../../api/definition'
import { runtimeApi } from '../../api/runtime'
import type { DataObjectDto } from '../../api/types'

const objects = ref<DataObjectDto[]>([])
const templates = ref<PrintTemplateDto[]>([])
const placeholders = ref<string[]>([])
const objectCode = ref('')
const editing = ref(false)
const saving = ref(false)
const previewVisible = ref(false)
const previewHtml = ref('')

const form = reactive({
  id: null as number | null,
  code: '',
  name: '',
  content: '',
  paperSize: 'A4',
  isDefault: false,
  enabled: true,
  remark: ''
})

function newTemplate() {
  editing.value = false
  Object.assign(form, {
    id: null,
    code: '',
    name: '',
    content: '<!DOCTYPE html>\n<html lang="zh-CN"><head><meta charset="utf-8"><title>打印</title>\n<style>\n  body { font-family: "Microsoft YaHei", sans-serif; margin: 24px; }\n  table { border-collapse: collapse; width: 100%; }\n  th, td { border: 1px solid #ccc; padding: 6px 8px; }\n</style></head>\n<body>\n  <h1>{{Name}}</h1>\n  <table>\n    <tr><th>编码</th><td>{{Code}}</td></tr>\n  </table>\n</body></html>',
    paperSize: 'A4',
    isDefault: false,
    enabled: true,
    remark: ''
  })
}

function edit(t: PrintTemplateDto) {
  editing.value = true
  Object.assign(form, {
    id: t.id,
    code: t.code,
    name: t.name,
    content: t.content,
    paperSize: t.paperSize,
    isDefault: t.isDefault,
    enabled: t.enabled,
    remark: t.remark ?? ''
  })
}

function phLabel(p: string): string {
  return p.startsWith('#') ? '{{#' + p.slice(1) + '}} … {{/' + p.slice(1) + '}}' : '{{' + p + '}}'
}

function insertPlaceholder(p: string) {
  const text = p.startsWith('#') ? `{{#${p.slice(1)}}}\n\n{{/${p.slice(1)}}}` : `{{${p}}}`
  form.content = `${form.content}\n${text}`
}

async function loadTemplates() {
  try {
    templates.value = await designApi.printTemplates(objectCode.value)
    if (objectCode.value) {
      placeholders.value = await designApi.printPlaceholders(objectCode.value)
    }
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function load() {
  try {
    objects.value = await metaApi.objects()
    if (!objectCode.value && objects.value.length) objectCode.value = objects.value[0].code
    await loadTemplates()
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function save() {
  if (!form.code.trim()) return ElMessage.warning('编码必填')
  if (!form.name.trim()) return ElMessage.warning('名称必填')
  if (!form.content.trim()) return ElMessage.warning('模板内容不能为空')
  saving.value = true
  try {
    await designApi.savePrintTemplate({ ...form, objectCode: objectCode.value, code: form.code.trim() })
    ElMessage.success('已保存')
    editing.value = true
    await loadTemplates()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    saving.value = false
  }
}

async function remove() {
  if (!form.id) return
  try {
    await ElMessageBox.confirm(`删除模板 ${form.code}？`, '确认', { type: 'warning' })
    await designApi.deletePrintTemplate(form.id)
    ElMessage.success('已删除')
    newTemplate()
    await loadTemplates()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

/** 预览用一条真实单据（默认取第一条），没有数据时给出提示 */
async function preview() {
  if (!objectCode.value) return ElMessage.warning('先选数据对象')
  if (!form.id) return ElMessage.warning('先保存模板再预览')
  try {
    const page = await runtimeApi.docStatusDefine(objectCode.value).catch(() => [])
    void page
    const rows = await designApi.previewRows(objectCode.value)
    if (!rows.length) return ElMessage.warning('该对象还没有数据，无法预览')
    const id = Number(rows[0]['Id'] ?? 0)
    if (!id) return ElMessage.warning('单据缺少主键，无法预览')
    previewHtml.value = await designApi.renderPrint(objectCode.value, id, form.code)
    previewVisible.value = true
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

function printPreview() {
  const win = window.open('', '_blank')
  if (!win) return ElMessage.warning('浏览器拦截了新窗口')
  win.document.write(previewHtml.value)
  win.document.close()
  win.focus()
  win.print()
}

onMounted(load)
</script>

<style scoped>
.tip { margin-bottom: 12px; }
.panel { height: 100%; }
.panel-head { display: flex; align-items: center; justify-content: space-between; }
.tpl-item { padding: 8px 10px; border-radius: 6px; cursor: pointer; border: 1px solid transparent; }
.tpl-item:hover { background: var(--el-fill-color-light); }
.tpl-item.active { background: var(--el-color-primary-light-9); border-color: var(--el-color-primary-light-5); }
.tpl-top { display: flex; align-items: center; justify-content: space-between; }
.tpl-name { font-size: 12px; margin: 2px 0; }
.tpl-meta { font-size: 11px; color: var(--el-text-color-secondary); }
.mono { font-family: Consolas, monospace; font-size: 13px; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.mono-input :deep(textarea) { font-family: Consolas, "Courier New", monospace; font-size: 12px; }
.ph { cursor: pointer; }
.preview-frame { width: 100%; height: 62vh; border: 1px solid var(--el-border-color); border-radius: 4px; }
</style>
