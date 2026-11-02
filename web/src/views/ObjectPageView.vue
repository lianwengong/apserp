<script setup lang="ts">
import MetaListView from './MetaListView.vue'

/**
 * 数据对象路由宿主。
 *
 * code 由路由 props 固定注入（router 的 props 函数），不读全局 route：
 * keep-alive 下同一组件的多个实例会同时存活，读全局 route.params 会让隐藏的旧页签
 * 跟着新路由重新查询（曾出现 /page/master-data 去查数据对象 master-data 的 400）。
 */
defineOptions({ name: 'ObjectPageView' })

defineProps<{ code?: string }>()
</script>

<template>
  <MetaListView :object-code="code ?? ''" />
</template>
