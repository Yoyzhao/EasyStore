<script setup lang="ts">
import { useDark, useToggle } from '@vueuse/core'
import { useAppStore } from '@/store/app'
import { useDashboardStore } from '@/store/dashboard'
import { useRoute } from 'vue-router'
import { computed, onMounted } from 'vue'

const isDark = useDark()
const toggleDark = useToggle(isDark)
const appStore = useAppStore()
const dashboardStore = useDashboardStore()
const route = useRoute()

const breadcrumbs = computed(() => {
  const matched = route.matched.filter(item => item.meta && item.meta.title)
  return matched
})

onMounted(() => {
  dashboardStore.fetchStats()
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
      <el-popover
        placement="bottom-end"
        :width="300"
        trigger="click"
        popper-class="notification-popover"
      >
        <template #reference>
          <div class="w-10 h-10 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer transition-colors text-[var(--text-muted)] hover:text-[var(--text-main)] relative">
            <el-icon :size="20"><Bell /></el-icon>
            <div v-if="dashboardStore.stats.low_stock_items > 0" class="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border-2 border-[var(--bg-main)]"></div>
          </div>
        </template>
        
        <div class="p-2">
          <div class="flex items-center justify-between mb-4 px-1">
            <span class="font-bold text-sm">系统通知</span>
            <el-tag v-if="dashboardStore.stats.low_stock_items > 0" size="small" type="danger" effect="plain" round>
              {{ dashboardStore.stats.low_stock_items }} 个提醒
            </el-tag>
          </div>
          
          <div v-if="dashboardStore.stats.low_stock_items > 0" class="flex flex-col gap-2">
            <div class="p-3 bg-red-50 dark:bg-red-900/20 rounded-xl border border-red-100 dark:border-red-900/30 flex gap-3">
              <el-icon class="text-red-500 mt-0.5" :size="16"><Warning /></el-icon>
              <div>
                <p class="text-xs font-bold text-red-700 dark:text-red-400">库存预警</p>
                <p class="text-xs text-red-600 dark:text-red-400/80 mt-1">
                  当前有 {{ dashboardStore.stats.low_stock_items }} 件商品低于安全库存水位，请及时补货。
                </p>
                <el-button 
                  link 
                  type="primary" 
                  size="small" 
                  class="mt-2 !text-xs !p-0"
                  @click="$router.push('/inventory')"
                >
                  去查看详情
                </el-button>
              </div>
            </div>
          </div>
          
          <div v-else class="py-8 flex flex-col items-center justify-center text-[var(--text-muted)]">
            <el-icon :size="32" class="opacity-20 mb-2"><ChatDotRound /></el-icon>
            <span class="text-xs">暂无新通知</span>
          </div>
        </div>
      </el-popover>
      
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
