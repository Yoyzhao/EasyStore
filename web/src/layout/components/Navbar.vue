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
  <div class="h-16 flex items-center justify-between px-4 transition-colors duration-300 shrink-0" style="background-color: var(--el-bg-color); border-bottom: 1px solid var(--el-border-color-light);">
    <div class="flex items-center gap-4">
      <!-- 折叠按钮 -->
      <div 
        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer transition-colors"
        @click="appStore.toggleSidebar"
      >
        <el-icon :size="20">
          <component :is="appStore.sidebarCollapsed ? 'Expand' : 'Fold'" />
        </el-icon>
      </div>

      <!-- 面包屑 (仅在大屏显示) -->
      <el-breadcrumb class="hidden sm:block">
        <el-breadcrumb-item v-for="item in breadcrumbs" :key="item.path">
          {{ item.meta.title }}
        </el-breadcrumb-item>
      </el-breadcrumb>
      
      <!-- 移动端当前页面标题 -->
      <span class="sm:hidden font-medium text-sm truncate" style="color: var(--el-text-color-primary)">
        {{ route.meta.title }}
      </span>
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
