<script setup lang="ts">
import { useDark } from '@vueuse/core'
import { watchEffect, ref, onMounted } from 'vue'
import { ElLoading } from 'element-plus'

const isDark = useDark()
const isBackendReady = ref(false)
const isElectron = !!(window as any).electronAPI

// 同步深色模式到 html 标签上，以便 Element Plus 的暗黑模式生效
watchEffect(() => {
  if (isDark.value) {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
})

onMounted(async () => {
  if (isElectron) {
    const loading = ElLoading.service({
      lock: true,
      text: '正在启动后端服务，请稍候...',
      background: 'rgba(0, 0, 0, 0.7)'
    })

    // 监听后端日志输出到控制台
    ;(window as any).electronAPI.onBackendLog((log: string) => {
      console.log(`[Backend] ${log}`)
    })

    // 设置超时检查
    const timeout = setTimeout(() => {
      loading.setText('启动后端时间过长，请检查后端服务是否正常...')
    }, 10000)

    // 检查当前后端状态（防止错过了 ready 事件）
    const isReady = await (window as any).electronAPI.checkBackendStatus()
    if (isReady) {
      isBackendReady.value = true
      clearTimeout(timeout)
      loading.close()
    } else {
      ;(window as any).electronAPI.onBackendReady(() => {
        isBackendReady.value = true
        clearTimeout(timeout)
        loading.close()
      })
    }
  } else {
    isBackendReady.value = true
  }
})
</script>

<template>
  <el-config-provider v-if="isBackendReady">
    <router-view></router-view>
  </el-config-provider>
</template>

<style>
/* 适配 Element Plus 暗黑模式 */
html.dark {
  color-scheme: dark;
}
</style>
