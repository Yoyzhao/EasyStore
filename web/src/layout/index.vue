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
  <div class="h-screen w-full flex overflow-hidden transition-colors duration-300 relative" style="background-color: var(--el-bg-color-page);">
    <!-- 移动端遮罩层 -->
    <div 
      v-if="!appStore.sidebarCollapsed && appStore.isMobile"
      class="fixed inset-0 z-40 bg-black/50 transition-opacity duration-300"
      @click="appStore.setSidebarCollapsed(true)"
    ></div>

    <!-- 侧边栏 -->
    <div 
      class="h-full flex-shrink-0 transition-all duration-300 z-50 fixed md:relative"
      :class="[
        appStore.sidebarCollapsed ? '-translate-x-full md:translate-x-0 md:w-20' : 'translate-x-0 w-64',
      ]"
    >
      <Sidebar />
    </div>
    
    <!-- 右侧内容区 -->
    <div 
      class="flex-1 flex flex-col min-w-0 overflow-hidden transition-all duration-300"
      :class="[
        appStore.isMobile ? 'ml-0' : (appStore.sidebarCollapsed ? 'md:ml-0' : 'md:ml-0')
      ]"
    >
      <!-- 顶部导航栏 -->
      <Navbar />
      
      <!-- 主要内容区域 -->
      <div class="flex-1 overflow-auto transition-colors duration-300" style="background-color: var(--el-bg-color-page);">
        <AppMain />
      </div>
    </div>
  </div>
</template>
