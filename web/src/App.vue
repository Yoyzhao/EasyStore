<script setup lang="ts">
import { useDark } from '@vueuse/core'
import { watchEffect } from 'vue'

const isDark = useDark()

// 同步深色模式到 html 标签上，以便 Element Plus 的暗黑模式生效
watchEffect(() => {
  if (isDark.value) {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
})
</script>

<template>
  <el-config-provider>
    <router-view></router-view>
  </el-config-provider>
</template>

<style>
/* 适配 Element Plus 暗黑模式 */
html.dark {
  color-scheme: dark;
}
</style>
