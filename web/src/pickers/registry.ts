import type { Row } from '../api/types'

/**
 * 参照选择器的业务映射。
 *
 * schema/字段只声明 lookupSource（对象编码），具体“选中后回填哪些字段”是业务知识，
 * 统一放在这里，避免每个表单各写一份。
 */
export interface PickerDefinition {
  objectCode: string
  title: string
  displayField: string
  /** 选中行 → 表单字段。只回填调用方表单里实际存在的字段。 */
  mapTo?: (row: Row) => Record<string, unknown>
}

const registry = new Map<string, PickerDefinition>()

export function registerPicker(definition: PickerDefinition): PickerDefinition {
  registry.set(definition.objectCode, definition)
  return definition
}

export function pickerFor(objectCode: string): PickerDefinition {
  return (
    registry.get(objectCode) ?? {
      objectCode,
      title: '选择记录',
      displayField: 'Name'
    }
  )
}

registerPicker({
  objectCode: 'md.brand',
  title: '选择品牌',
  displayField: 'Name',
  mapTo: (row) => ({
    BrandId: row.Id,
    BrandName: row.Name,
    Name: row.Name,
    Code: row.Code
  })
})

registerPicker({
  objectCode: 'md.brandcontact',
  title: '选择品牌联系人',
  displayField: 'Name',
  mapTo: (row) => ({
    ContactId: row.Id,
    ContactName: row.Name,
    Name: row.Name
  })
})

registerPicker({
  objectCode: 'md.partner',
  title: '选择往来单位',
  displayField: 'Name',
  mapTo: (row) => ({
    PartnerId: row.Id,
    PartnerName: row.Name,
    SupplierId: row.Id,
    SupplierName: row.Name,
    CustomerId: row.Id,
    CustomerName: row.Name
  })
})
