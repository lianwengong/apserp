<template>
  <div v-if="businessId" class="attachment-panel">
    <div class="panel-head">
      <span class="title">附件</span>
      <span class="muted">{{ files.length }} 个 · 单个不超过 10MB</span>
      <el-upload
        :show-file-list="false"
        :http-request="doUpload"
        :disabled="uploading"
        class="uploader"
      >
        <el-button size="small" type="primary" plain :loading="uploading">上传附件</el-button>
      </el-upload>
    </div>

    <el-empty v-if="!files.length" description="还没有附件" :image-size="48" />

    <el-table v-else :data="files" size="small" border>
      <el-table-column prop="fileName" label="文件名" show-overflow-tooltip />
      <el-table-column prop="ext" label="类型" width="80" align="center" />
      <el-table-column label="大小" width="100" align="right">
        <template #default="{ row }">{{ sizeText(row.fileSize) }}</template>
      </el-table-column>
      <el-table-column prop="uploadedAt" label="上传时间" width="160" />
      <el-table-column label="操作" width="120" align="center">
        <template #default="{ row }">
          <el-button link size="small" type="primary" @click="download(row)">下载</el-button>
          <el-button link size="small" type="danger" @click="remove(row)">删</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { attachmentApi, type AttachmentDto } from '../api/attachment'

/**
 * 附件面板：挂在表单里，按「数据对象 + 单据 Id」维度列附件。
 * 上传/下载都走 api 层（下载要带 token，不能直接用 a[href]）。
 */
const props = defineProps<{
  objectCode: string
  businessId: number | null
}>()

const files = ref<AttachmentDto[]>([])
const uploading = ref(false)

async function load() {
  if (!props.businessId) {
    files.value = []
    return
  }
  try {
    files.value = await attachmentApi.list(props.objectCode, props.businessId)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function doUpload(options: { file: File }) {
  if (!props.businessId) return
  uploading.value = true
  try {
    await attachmentApi.upload(props.objectCode, props.businessId, options.file)
    ElMessage.success('已上传')
    await load()
  } catch (e) {
    ElMessage.error((e as Error).message)
  } finally {
    uploading.value = false
  }
}

async function download(row: AttachmentDto) {
  try {
    await attachmentApi.download(row.id, row.fileName)
  } catch (e) {
    ElMessage.error((e as Error).message)
  }
}

async function remove(row: AttachmentDto) {
  try {
    await ElMessageBox.confirm(`删除附件「${row.fileName}」？`, '确认', { type: 'warning' })
    await attachmentApi.remove(row.id)
    ElMessage.success('已删除')
    await load()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error((e as Error).message)
  }
}

function sizeText(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1024 / 1024).toFixed(2)} MB`
}

watch(() => props.businessId, load)
onMounted(load)
</script>

<style scoped>
.attachment-panel { margin-top: 14px; border-top: 1px dashed var(--el-border-color); padding-top: 10px; }
.panel-head { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.title { font-weight: 600; font-size: 13px; }
.muted { color: var(--el-text-color-secondary); font-size: 11px; }
.uploader { margin-left: auto; }
</style>
