<script setup lang="ts">
import { onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/store/app'
import Sidebar from './components/Sidebar.vue'
import Navbar from './components/Navbar.vue'
import AppMain from './components/AppMain.vue'

const appStore = useAppStore()
const route = useRoute()

const handleResize = () => {
  const isMobile = window.innerWidth < 768
  appStore.setIsMobile(isMobile)
}

onMounted(() => {
  handleResize()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})

// 移动端路由跳转时自动关闭侧边栏
watch(() => route.path, () => {
  if (appStore.isMobile) {
    appStore.setSidebarCollapsed(true)
  }
})
</script>

<template>
  <div class="h-screen w-full flex overflow-hidden transition-colors duration-300 relative bg-[var(--page-bg)]">
    <!-- 移动端遮罩层 -->
    <div 
      v-if="!appStore.sidebarCollapsed && appStore.isMobile"
      class="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm transition-opacity duration-300"
      @click="appStore.setSidebarCollapsed(true)"
    ></div>

    <!-- 侧边栏容器：悬浮设计或全高设计 -->
    <div 
      class="flex-shrink-0 transition-all duration-300 z-50 fixed md:relative p-0 md:p-4 md:pr-0"
      :class="[
        appStore.sidebarCollapsed ? '-translate-x-full md:translate-x-0 md:w-24' : 'translate-x-0 w-64 md:w-72',
      ]"
    >
      <div class="h-full w-full rounded-none md:rounded-2xl overflow-hidden shadow-lg md:shadow-md border border-[var(--border-subtle)] bg-[var(--sidebar-bg)]">
        <Sidebar />
      </div>
    </div>
    
    <!-- 右侧内容区 -->
    <div 
      class="flex-1 flex flex-col min-w-0 overflow-hidden transition-all duration-300"
      style="scrollbar-gutter: stable;"
    >
      <!-- 顶部导航栏 -->
      <div class="px-0 md:px-6 pt-0 md:pt-4 flex-shrink-0">
        <div class="max-w-7xl mx-auto w-full rounded-none md:rounded-2xl border-b md:border border-[var(--border-subtle)] bg-[var(--sidebar-bg)] shadow-sm md:shadow-sm overflow-hidden">
          <Navbar />
        </div>
      </div>
      
      <!-- 主要内容区域 -->
      <div class="flex-1 overflow-y-auto px-0 md:px-6 py-4 md:py-6">
        <AppMain />
      </div>
    </div>
  </div>
</template>
