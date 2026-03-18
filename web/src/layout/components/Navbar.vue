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
        inline-prompt
        :active-icon="'Moon'"
        :inactive-icon="'Sunny'"
        @change="toggleDark"
      />
    </div>
  </div>
</template>
