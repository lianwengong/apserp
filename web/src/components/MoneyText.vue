<template>
  <span class="money" :style="style">
    <span v-if="showSymbol" class="symbol">¥</span>{{ text }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { appearance } from '../stores/appearance'
import { formatMoney, moneyTone } from '../utils/money'

defineOptions({ name: 'MoneyText' })

const props = withDefaults(
  defineProps<{
    value: number | string | null | undefined
    digits?: number
    showSymbol?: boolean
    /** 强制关闭面额着色（例如合计行需要统一颜色） */
    plain?: boolean
  }>(),
  { digits: 2, showSymbol: false, plain: false }
)

const text = computed(() => formatMoney(props.value, props.digits))

const style = computed(() => {
  if (props.plain || !appearance.state.moneyTone) return {}
  const tone = moneyTone(props.value)
  return tone.color ? { color: tone.color, fontWeight: '600' } : {}
})
</script>

<style scoped>
.money {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
.symbol {
  font-size: 0.9em;
  margin-right: 1px;
  opacity: 0.75;
}
</style>
