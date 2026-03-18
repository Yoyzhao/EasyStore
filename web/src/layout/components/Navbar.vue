<script setup lang="ts">
import { useDark, useToggle } from '@vueuse/core'

const isDark = useDark()
const toggleDark = useToggle(isDark)
</script>

<template>
  <div class="h-16 flex items-center justify-between px-6 transition-colors duration-300" style="background-color: var(--el-bg-color); border-bottom: 1px solid var(--el-border-color-light);">
    <div class="flex items-center">
      <!-- 可以在这里放面包屑或折叠按钮 -->
    </div>

    <div class="flex items-center gap-4">
      <el-switch
        v-model="isDark"
        class="theme-switch"
        inline-prompt
        :active-icon="'Moon'"
        :inactive-icon="'Sunny'"
        @change="toggleDark"
      />
    </div>
  </div>
</template>

<style scoped>
/* 增强浅色模式下太阳图标的可见性 */
:deep(.theme-switch:not(.is-checked) .el-switch__core .el-switch__inner .el-icon) {
  color: #E6A23C; /* 橙色太阳 */
}

/* 深色模式下的月亮图标 */
:deep(.theme-switch.is-checked .el-switch__core .el-switch__inner .el-icon) {
  color: #F2F2F2; /* 浅色月亮 */
}
</style>
