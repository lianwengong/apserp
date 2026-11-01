import type { Component } from 'vue'
import {
  Box,
  Calendar,
  Connection,
  FolderOpened,
  Grid,
  Money,
  Promotion,
  RefreshLeft,
  Sell,
  Setting,
  ShoppingCart,
  Van
} from '@element-plus/icons-vue'

export interface SchemaGroup {
  code: string
  label: string
  icon: Component
}

/** 业务域与中文名：菜单分组、面包屑、工作台共用这一份映射。 */
export const SCHEMA_GROUPS: SchemaGroup[] = [
  { code: 'md', label: '基础资料', icon: FolderOpened },
  { code: 'pur', label: '采购管理', icon: ShoppingCart },
  { code: 'sal', label: '销售管理', icon: Sell },
  { code: 'inv', label: '库存管理', icon: Box },
  { code: 'ret', label: '退货管理', icon: RefreshLeft },
  { code: 'fin', label: '财务管理', icon: Money },
  { code: 'mkt', label: '营销管理', icon: Promotion },
  { code: 'omn', label: '全渠道', icon: Connection },
  { code: 'tms', label: '运输管理', icon: Van },
  { code: 'pln', label: '计划管理', icon: Calendar },
  { code: 'plat', label: '平台设置', icon: Setting }
]

const GROUP_MAP = new Map(SCHEMA_GROUPS.map((group) => [group.code, group]))

const FALLBACK: SchemaGroup = { code: 'other', label: '其他', icon: Grid }

/** 数据对象编码为 `schema.object`，分组只看前缀。 */
export function schemaOf(objectCode: string): string {
  return objectCode.split('.')[0] ?? ''
}

export function groupOf(objectCode: string): SchemaGroup {
  return GROUP_MAP.get(schemaOf(objectCode)) ?? FALLBACK
}

export const SCHEMA_GROUP_ORDER = SCHEMA_GROUPS.map((group) => group.code)
