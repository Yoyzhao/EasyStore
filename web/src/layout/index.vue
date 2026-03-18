<script setup lang="ts">
import Sidebar from './components/Sidebar.vue'
import Navbar from './components/Navbar.vue'
import AppMain from './components/AppMain.vue'
</script>

<template>
  <div class="h-screen w-full flex overflow-hidden transition-colors duration-300" style="background-color: var(--el-bg-color-page);">
    <!-- 侧边栏 -->
    <div class="w-64 flex-shrink-0 transition-all duration-300">
      <Sidebar />
    </div>
    
    <!-- 右侧内容区 -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- 顶部导航栏 -->
      <Navbar />
      
      <!-- 主要内容区域 -->
      <div class="flex-1 overflow-auto transition-colors duration-300" style="background-color: var(--el-bg-color-page);">
        <AppMain />
      </div>
    </div>
  </div>
</template>
