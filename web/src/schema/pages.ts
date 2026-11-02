import { registerPage } from './registry.ts'
import type { PageSchema } from './types.ts'

/**
 * 首批生产页面。
 *
 * 原则：页面只组合“已经存在的真实能力”（数据对象列表 / 平台页 / 设计器），
 * 不为了演示造没有接口的假页面。objectCode 必须存在于当前租户目录。
 */

export const workbenchPage: PageSchema = registerPage({
  code: 'workbench',
  title: '数据看板',
  kind: 'dashboard',
  description: '今日待办、基础资料规模与常用入口',
  dashboard: {
    cards: [
      { key: 'brand', label: '品牌', objectCode: 'md.brand', icon: 'PriceTag', to: '/object/md.brand' },
      {
        key: 'brandcontact',
        label: '品牌联系人',
        objectCode: 'md.brandcontact',
        icon: 'User',
        to: '/object/md.brandcontact'
      },
      {
        key: 'partner',
        label: '往来单位',
        objectCode: 'md.partner',
        icon: 'OfficeBuilding',
        to: '/object/md.partner'
      },
      {
        key: 'menus',
        label: '功能菜单',
        value: '菜单',
        hint: '侧边栏已启用',
        icon: 'Grid',
        to: '/page/master-data'
      }
    ],
    shortcuts: [
      { label: '基础资料中心', to: '/page/master-data', icon: 'Files' },
      { label: '品牌管理', to: '/object/md.brand', icon: 'PriceTag' },
      { label: '往来单位', to: '/object/md.partner', icon: 'OfficeBuilding' },
      { label: '设计器中心', to: '/design', icon: 'SetUp' }
    ],
    recentObjectCodes: ['md.brand', 'md.brandcontact', 'md.partner']
  },
  permissions: []
})

export const masterDataPage: PageSchema = registerPage({
  code: 'master-data',
  title: '基础资料中心',
  kind: 'tabs',
  description: '品牌、联系人、往来单位在同一屏内切换；每个页签都是真实数据对象页面',
  tabs: [
    { key: 'brand', label: '品牌', icon: 'PriceTag', objectCode: 'md.brand' },
    { key: 'brandcontact', label: '品牌联系人', icon: 'User', objectCode: 'md.brandcontact' },
    { key: 'partner', label: '往来单位', icon: 'OfficeBuilding', objectCode: 'md.partner' }
  ],
  permissions: []
})

export const localPages: PageSchema[] = [workbenchPage, masterDataPage]
