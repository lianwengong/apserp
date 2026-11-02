import { pageSchemaApi } from '../api/page-schema'
import { resolvePage } from './registry'
import { assertPageSchema, isPageSchema, type PageSchema } from './types'

/**
 * PageSchema 加载：
 *   1. 先请求后端 /api/page-schema/{code}（可配置、立即生效）；
 *   2. 远程没有/被停用/JSON 不合法/请求失败 → 回退前端本地版本；
 *   3. 缓存 30 秒，后台保存后由页面编排器主动 invalidate。
 *
 * 这样远程配置坏了也不会白屏，前端版本始终是可用的安全网。
 */
const TTL_MS = 30_000
const cache = new Map<string, { page: PageSchema | null; at: number }>()

function parseRemote(code: string, configJson: string): PageSchema | null {
  try {
    const parsed: unknown = JSON.parse(configJson)
    if (!isPageSchema(parsed)) return null
    if (parsed.code !== code) return null
    assertPageSchema(parsed)
    return parsed
  } catch (ex) {
    console.warn(`[page-schema] 远程页面 ${code} 配置不合法，回退本地定义`, ex)
    return null
  }
}

export async function loadPage(code: string): Promise<PageSchema | undefined> {
  if (!code) return undefined
  const cached = cache.get(code)
  if (cached && Date.now() - cached.at < TTL_MS) {
    return cached.page ?? resolvePage(code)
  }

  let remote: PageSchema | null = null
  try {
    const dto = await pageSchemaApi.get(code)
    if (dto?.enabled) {
      remote = parseRemote(code, dto.configJson)
    }
  } catch {
    // 后端未部署 / 网络失败 / 无权限：静默回退，布局与页面不应因此打不开
  }

  cache.set(code, { page: remote, at: Date.now() })
  return remote ?? resolvePage(code)
}

export function invalidatePage(code?: string): void {
  if (code) cache.delete(code)
  else cache.clear()
}
