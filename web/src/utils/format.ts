import type { FieldDto } from '../api/types'

/** 空值统一显示为破折号，表格里一眼区分“空”与“0/false”。 */
export function isBlank(value: unknown): boolean {
  return value === null || value === undefined || value === ''
}

/** 去掉 decimal(18,4) / datetime2(3) 这类精度后缀，只留基础类型名。 */
function baseType(field?: FieldDto): string {
  return (field?.dataType ?? '')
    .replace(/\(.*\)\s*$/, '')
    .trim()
    .toLowerCase()
}

export function isBitField(field?: FieldDto): boolean {
  return baseType(field) === 'bit'
}

export function isDateField(field?: FieldDto): boolean {
  return ['date', 'datetime', 'datetime2', 'smalldatetime', 'time'].includes(baseType(field))
}

export function isIntegerField(field?: FieldDto): boolean {
  return ['tinyint', 'smallint', 'int', 'bigint'].includes(baseType(field))
}

export function isNumberField(field?: FieldDto): boolean {
  return (
    isIntegerField(field) ||
    ['decimal', 'numeric', 'money', 'smallmoney', 'float', 'real'].includes(baseType(field))
  )
}

/** decimal(18,4) → 4，用于金额/数量的小数位。 */
export function decimalScale(field?: FieldDto): number {
  const matched = /^(?:decimal|numeric)\(\d+,(\d+)\)/i.exec(field?.dataType ?? '')
  return matched ? Number(matched[1]) : 0
}

function pad(value: number): string {
  return value < 10 ? `0${value}` : String(value)
}

function toDate(value: unknown): Date | null {
  if (value instanceof Date) return value
  if (typeof value === 'number') return new Date(value)
  if (typeof value === 'string') {
    const parsed = new Date(value)
    return Number.isNaN(parsed.getTime()) ? null : parsed
  }
  return null
}

export function formatDateTime(value: unknown, withTime = true): string {
  const date = toDate(value)
  if (!date) return String(value)
  const head = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
  return withTime ? `${head} ${pad(date.getHours())}:${pad(date.getMinutes())}` : head
}

export function formatNumber(value: unknown, scale = 0): string {
  const number = Number(value)
  if (!Number.isFinite(number)) return String(value)
  return number.toLocaleString('zh-CN', {
    minimumFractionDigits: scale,
    maximumFractionDigits: scale
  })
}

/** 列表/详情统一取字符串；布尔、日期、数字按字段类型格式化。 */
export function formatCell(value: unknown, field?: FieldDto): string {
  if (isBlank(value)) return '—'
  if (isBitField(field)) return value ? '是' : '否'
  if (isDateField(field)) return formatDateTime(value, field?.format?.includes('HH') ?? true)
  if (isNumberField(field)) return formatNumber(value, decimalScale(field))
  return String(value)
}

export function greeting(): string {
  const hour = new Date().getHours()
  if (hour < 6) return '夜深了'
  if (hour < 11) return '早上好'
  if (hour < 14) return '中午好'
  if (hour < 18) return '下午好'
  return '晚上好'
}

export function todayText(): string {
  const date = new Date()
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  return `${date.getFullYear()} 年 ${date.getMonth() + 1} 月 ${date.getDate()} 日 · 星期${weekdays[date.getDay()]}`
}
