<script setup lang="ts">
import { computed } from 'vue'
import type { FieldDto } from '../api/types'
import { formatCell, isBitField, isBlank } from '../utils/format'

const props = defineProps<{
  value: unknown
  field?: FieldDto
}>()

const isBit = computed(() => isBitField(props.field) && !isBlank(props.value))
const text = computed(() => formatCell(props.value, props.field))
const empty = computed(() => isBlank(props.value))
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
