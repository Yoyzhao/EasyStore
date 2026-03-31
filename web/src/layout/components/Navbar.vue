<script setup lang="ts">
import { useDark, useToggle } from '@vueuse/core'
import { useAppStore } from '@/store/app'
import { useRoute } from 'vue-router'
import { computed } from 'vue'

const isDark = useDark()
const toggleDark = useToggle(isDark)
const appStore = useAppStore()
const route = useRoute()

const breadcrumbs = computed(() => {
  const matched = route.matched.filter(item => item.meta && item.meta.title)
  return matched
})
</script>

<template>
  <div class="h-16 flex items-center justify-between px-6 transition-colors duration-300 shrink-0 bg-transparent">
    <div class="flex items-center gap-4">
      <!-- 折叠按钮 -->
      <div 
        class="w-10 h-10 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer transition-colors text-[var(--text-muted)] hover:text-[var(--text-main)]"
        @click="appStore.toggleSidebar"
      >
        <el-icon :size="20">
          <component :is="appStore.sidebarCollapsed ? 'Expand' : 'Fold'" />
        </el-icon>
      </div>

      <!-- 面包屑 (仅在大屏显示) -->
      <el-breadcrumb class="hidden sm:block">
        <el-breadcrumb-item v-for="item in breadcrumbs" :key="item.path">
          <span class="font-medium text-[var(--text-muted)]">{{ item.meta.title }}</span>
        </el-breadcrumb-item>
      </el-breadcrumb>
      
      <!-- 移动端当前页面标题 -->
      <span class="sm:hidden font-bold text-lg truncate text-[var(--text-main)] font-display">
        {{ route.meta.title }}
      </span>
    </div>

    <div class="flex items-center gap-5">
      <!-- 通知/其他操作可放这里 -->
      <div class="w-10 h-10 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer transition-colors text-[var(--text-muted)] hover:text-[var(--text-main)]">
        <el-icon :size="20"><Bell /></el-icon>
      </div>
      
      <!-- 主题切换 -->
      <div class="flex items-center justify-center w-10 h-10 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer transition-colors" @click="toggleDark()">
        <el-icon :size="20" :class="isDark ? 'text-gray-200' : 'text-amber-500'">
          <component :is="isDark ? 'Moon' : 'Sunny'" />
        </el-icon>
      </div>
    </div>
  </div>
</template>

<style scoped>
:deep(.el-breadcrumb__inner) {
  color: var(--text-muted) !important;
  font-weight: 500;
}
:deep(.el-breadcrumb__item:last-child .el-breadcrumb__inner) {
  color: var(--text-main) !important;
  font-weight: 600;
}
</style>
