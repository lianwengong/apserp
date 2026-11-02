import { request, queryString, getToken } from './http'

export interface AttachmentDto {
  id: number
  objectCode: string
  businessId: number
  fileName: string
  ext: string
  fileSize: number
  url: string
  uploadedAt: string
  uploadedBy: number | null
}

/** 附件接口：上传走 multipart，下载要带 token（不能直接用 a[href]）。 */
export const attachmentApi = {
  list: (objectCode: string, businessId: number) =>
    request<AttachmentDto[]>(`/api/runtime/attachments${queryString({ objectCode, businessId })}`),

  upload: (objectCode: string, businessId: number, file: File) => {
    const form = new FormData()
    form.append('objectCode', objectCode)
    form.append('businessId', String(businessId))
    form.append('file', file)
    return fetch('/api/runtime/attachments', {
      method: 'POST',
      headers: { Authorization: `Bearer ${getToken() ?? ''}` },
      body: form
    }).then(async (res) => {
      const json = await res.json().catch(() => null)
      if (!res.ok || (json && json.code !== 0)) {
        throw new Error(json?.message ?? `上传失败（HTTP ${res.status}）`)
      }
      return json.data as AttachmentDto
    })
  },

  remove: (id: number) => request<void>(`/api/runtime/attachments/${id}`, { method: 'DELETE' }),

  /** 带 token 下载：取 blob 再触发浏览器保存，文件名沿用原始名。 */
  async download(id: number, fileName: string): Promise<void> {
    const res = await fetch(`/api/runtime/attachments/${id}/download`, {
      headers: { Authorization: `Bearer ${getToken() ?? ''}` }
    })
    if (!res.ok) throw new Error(`下载失败（HTTP ${res.status}）`)
    const blob = await res.blob()
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = fileName
    link.click()
    URL.revokeObjectURL(link.href)
  }
}
