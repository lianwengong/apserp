import assert from 'node:assert/strict'
import { createServer } from 'vite'

/**
 * 前端纯逻辑单测（不依赖 jsdom）。
 *
 * 用 Vite 的 SSR 加载器直接执行 TS 模块：Node 20 的 CI 不需要额外的 tsx/ts-node，
 * 也不会因为 Node 版本不支持 TS type stripping 而失败。
 */
const server = await createServer({
  configFile: false,
  root: process.cwd(),
  server: { middlewareMode: true },
  appType: 'custom',
  logLevel: 'error',
  // 只做 SSR 模块加载，不需要扫描 index.html 的依赖，避免关闭时 dep-scan 竞态
  optimizeDeps: { noDiscovery: true }
})

try {
  const { assertPageSchema, isPageSchema } = await server.ssrLoadModule('/src/schema/types.ts')
  const { getPage, registerPage } = await server.ssrLoadModule('/src/schema/registry.ts')
  await server.ssrLoadModule('/src/schema/pages.ts')
  const { pickerFor } = await server.ssrLoadModule('/src/pickers/registry.ts')

  assert.throws(
    () => assertPageSchema({ code: 'bad.object', title: '坏页面', kind: 'object' }),
    /objectCode/
  )
  console.log('✔ PageSchema：object 必须有 objectCode')

  assert.throws(
    () => assertPageSchema({ code: 'bad.tabs', title: '坏页签', kind: 'tabs', tabs: [] }),
    /至少一个页签/
  )
  assert.throws(
    () =>
      assertPageSchema({
        code: 'bad.tabs2',
        title: '坏页签',
        kind: 'tabs',
        tabs: [
          { key: 'a', label: 'A', objectCode: 'md.brand' },
          { key: 'a', label: 'A2', objectCode: 'md.partner' }
        ]
      }),
    /key 重复/
  )
  console.log('✔ PageSchema：tabs 页签与 key 校验')

  const unique = { code: 'test.unique', title: '测试页面', kind: 'placeholder', description: '' }
  assert.equal(isPageSchema(unique), true)
  registerPage(unique)
  assert.equal(getPage('test.unique')?.title, '测试页面')
  assert.throws(() => registerPage(unique), /重复注册/)
  console.log('✔ PageSchema：重复注册立即失败')

  const master = getPage('master-data')
  const workbench = getPage('workbench')
  assert.ok(master && workbench)
  assert.equal(master.kind, 'tabs')
  assert.deepEqual(
    master.tabs?.map((tab) => tab.objectCode),
    ['md.brand', 'md.brandcontact', 'md.partner']
  )
  assert.equal(workbench.kind, 'dashboard')
  console.log('✔ 生产页面：基础资料中心 / 数据看板已注册')

  const picker = pickerFor('md.brand')
  assert.equal(picker.displayField, 'Name')
  assert.deepEqual(picker.mapTo?.({ Id: 7, Name: '测试品牌', Code: 'B007' }), {
    BrandId: 7,
    BrandName: '测试品牌',
    Name: '测试品牌',
    Code: 'B007'
  })
  console.log('✔ 参照选择：品牌 mapTo 回填 BrandId')
} finally {
  await server.close()
}
