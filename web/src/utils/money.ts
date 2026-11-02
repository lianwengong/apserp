/**
 * 金额渲染：整数部分按人民币面额着色（100/50/20/10/5/1），小数与符号保持中性。
 *
 * 设计边界：
 * - 只影响「显示」，不参与任何计算；千分位在显示时加，不回写数据；
 * - 面额色由外观偏好提供 CSS 变量（--rmb-100…--rmb-1），关闭「金额按面额着色」时退化为普通文本；
 * - 负数、零、空值不着色（避免红绿混淆语义，负数用统一的中性文本 + 前置负号）。
 */

/** 面额档位：从大到小，命中即返回 */
const DENOMINATIONS: { value: number; name: string }[] = [
  { value: 100, name: '朱砂' },
  { value: 50, name: '苍翠' },
  { value: 20, name: '赭石' },
  { value: 10, name: '靛青' },
  { value: 5, name: '藕荷' },
  { value: 1, name: '栗棕' }
]

export interface MoneyTone {
  /** 命中的面额（1/5/10/20/50/100），0 表示不着色 */
  value: number
  name: string
  color: string
}

/** 按金额绝对值挑面额色：≥100 用 100 元色，其余落到最近的低档 */
export function moneyTone(amount: number | string | null | undefined): MoneyTone {
  const value = typeof amount === 'string' ? Number(amount) : amount
  if (value == null || !Number.isFinite(value) || value <= 0) {
    return { value: 0, name: '', color: '' }
  }
  const hit = DENOMINATIONS.find((item) => value >= item.value)
  if (!hit) {
    return { value: 0, name: '', color: '' }
  }
  return { value: hit.value, name: hit.name, color: `var(--rmb-${hit.value})` }
}

/** 千分位 + 固定小数位（纯显示用，不做四舍五入规则之外的换算） */
export function formatMoney(amount: number | string | null | undefined, digits = 2): string {
  const value = typeof amount === 'string' ? Number(amount) : amount
  if (value == null || !Number.isFinite(value)) {
    return ''
  }
  return value.toLocaleString('zh-CN', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits
  })
}
