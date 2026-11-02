import { assertPageSchema, type PageSchema } from './types.ts'

/**
 * 页面注册表。
 *
 * 当前页面组合由前端版本化定义（与后端元数据同仓发布），后续接后端下发时，
 * 只需要在 resolvePage 前加一层远程加载，模板层不用改。
 */
const registry = new Map<string, PageSchema>()

export function registerPage(page: PageSchema): PageSchema {
  assertPageSchema(page)
  if (registry.has(page.code)) {
    throw new Error(`PageSchema 重复注册：${page.code}`)
  }
  registry.set(page.code, page)
  return page
}

export function getPage(code: string): PageSchema | undefined {
  return registry.get(code)
}

export function listPages(): PageSchema[] {
  return [...registry.values()]
}

export function resolvePage(code: string): PageSchema | undefined {
  return registry.get(code)
}

export function pageExists(code: string): boolean {
  return registry.has(code)
}
