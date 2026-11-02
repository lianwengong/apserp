<script setup lang="ts">
import { computed } from 'vue'
import type { FieldDto } from '../api/types'
import { formatCell, isBitField, isBlank } from '../utils/format'
import MoneyText from './MoneyText.vue'

const props = defineProps<{
  value: unknown
  field?: FieldDto
}>()

const isBit = computed(() => isBitField(props.field) && !isBlank(props.value))
const text = computed(() => formatCell(props.value, props.field))
const empty = computed(() => isBlank(props.value))

/** 小数位取字段格式（format 里可能写 0.00），拿不到就按 2 位 */
const decimalDigits = computed(() => {
  const match = /\.(0+)$/.exec(props.field?.format ?? '')
  return match ? match[1].length : 2
})

/** 金额/数值列按人民币面额着色（外观偏好可关） */
const isMoney = computed(() => {
  const type = props.field?.dataType ?? ''
  return /^(decimal|numeric|money|smallmoney)$/i.test(type) && !isBlank(props.value)
})
</script>

<template>
  <el-tag
    v-if="isBit"
    :type="value ? 'success' : 'info'"
    size="small"
    effect="light"
    disable-transitions
  >
    {{ text }}
  </el-tag>
  <MoneyText
    v-else-if="isMoney"
    :value="value as number"
    :digits="decimalDigits"
    class="cell-text"
  />
  <span v-else class="cell-text" :class="{ 'is-empty': empty }">{{ text }}</span>
</template>

<style scoped>
.cell-text {
  color: var(--ink-2);
}

.cell-text.is-empty {
  color: #b3bfcb;
}
</style>
