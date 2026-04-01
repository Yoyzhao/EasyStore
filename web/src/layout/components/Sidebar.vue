<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/store/user'
import { useAppStore } from '@/store/app'
import { computed } from 'vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const appStore = useAppStore()

const handleLogout = () => {
  userStore.logout()
  router.push('/login')
}

// 基于路由元数据动态生成菜单
const rootRoute = router.options.routes.find(r => r.path === '/')
const menuList = computed(() => {
  return rootRoute?.children?.filter(r => !r.meta?.hidden) || []
})

// 权限校验
const hasPermission = (routeObj: any) => {
  if (routeObj.meta?.roles) {
    return routeObj.meta.roles.includes(userStore.userInfo.role)
  }
  return true
}

// 路径解析
const resolvePath = (basePath: string, childPath?: string) => {
  const base = basePath.startsWith('/') ? basePath : `/${basePath}`
  if (!childPath) return base
  const child = childPath.startsWith('/') ? childPath.slice(1) : childPath
  return `${base === '/' ? '' : base}/${child}`
}
</script>

<template>
  <div class="h-full transition-all duration-300 flex flex-col overflow-hidden bg-transparent">
    <!-- 顶部 Logo 区域 -->
    <div :class="[appStore.sidebarCollapsed ? 'px-2 justify-center' : 'px-6', 'h-20 flex items-center shrink-0 gap-3 border-b border-[var(--border-subtle)] transition-all duration-300']">
      <div class="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
        <el-icon :size="24" class="text-blue-500"><Box /></el-icon>
      </div>
      <h1 
        v-show="!appStore.sidebarCollapsed"
        class="text-2xl font-bold truncate transition-opacity duration-300 font-display text-[var(--text-main)]" 
      >
        EasyStore
      </h1>
    </div>
    
    <!-- 导航菜单 -->
    <div class="flex-1 overflow-y-auto px-3 py-4 custom-scrollbar">
      <el-menu
        :default-active="route.path"
        :collapse="appStore.sidebarCollapsed"
        class="border-none !bg-transparent"
        router
        :collapse-transition="false"
      >
        <template v-for="menu in menuList" :key="menu.path">
          <!-- 包含子菜单的情况 -->
          <el-sub-menu v-if="menu.children && menu.children.length > 0 && hasPermission(menu)" :index="resolvePath(menu.path)">
            <template #title>
              <el-icon v-if="menu.meta?.icon">
                <component :is="menu.meta.icon" />
              </el-icon>
              <span class="font-medium">{{ menu.meta?.title }}</span>
            </template>
            
            <template v-for="child in menu.children" :key="child.path">
              <el-menu-item v-if="!child.meta?.hidden && hasPermission(child)" :index="resolvePath(menu.path, child.path)" class="rounded-lg mb-1 !h-11 !line-height-11">
                <el-icon v-if="child.meta?.icon">
                  <component :is="child.meta.icon" />
                </el-icon>
                <template #title>
                  <span class="font-medium">{{ child.meta?.title }}</span>
                </template>
              </el-menu-item>
            </template>
          </el-sub-menu>

          <!-- 没有子菜单的情况 -->
          <el-menu-item v-else-if="!menu.meta?.hidden && hasPermission(menu)" :index="resolvePath(menu.path)" class="rounded-lg mb-2 !h-12 !line-height-12">
            <el-icon v-if="menu.meta?.icon">
              <component :is="menu.meta.icon" />
            </el-icon>
            <template #title>
              <span class="font-medium">{{ menu.meta?.title }}</span>
            </template>
          </el-menu-item>
        </template>
      </el-menu>
    </div>

    <!-- 用户操作区域 -->
    <div :class="[appStore.sidebarCollapsed ? 'p-2' : 'p-4', 'mt-auto shrink-0 border-t border-[var(--border-subtle)] transition-all duration-300']">
      <el-dropdown trigger="click" placement="top" class="w-full">
        <div :class="[appStore.sidebarCollapsed ? 'justify-center px-0' : 'justify-between px-2', 'flex items-center w-full cursor-pointer py-2 rounded-xl transition-all duration-300 hover:bg-gray-100 dark:hover:bg-gray-800/50']">
          <div class="flex items-center overflow-hidden">
            <div class="w-10 h-10 rounded-full bg-gradient-to-tr from-blue-400 to-indigo-500 p-[2px] flex-shrink-0 shadow-sm">
              <img src="https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png" class="w-full h-full rounded-full border-2 border-white dark:border-gray-800 object-cover" />
            </div>
            <span 
              v-show="!appStore.sidebarCollapsed"
              class="ml-3 text-sm font-semibold truncate transition-opacity duration-300 text-[var(--text-main)]" 
            >
              {{ userStore.userInfo.username }}
            </span>
          </div>
          <el-icon v-show="!appStore.sidebarCollapsed" class="text-[var(--text-muted)]"><ArrowUp /></el-icon>
        </div>
        <template #dropdown>
          <el-dropdown-menu class="w-56 !rounded-xl !p-2">
            <div class="px-3 py-2 mb-2 border-b border-[var(--border-subtle)]">
              <div class="text-sm font-bold text-[var(--text-main)]">{{ userStore.userInfo.username }}</div>
              <div class="text-xs text-[var(--text-muted)]">{{ userStore.userInfo.role === 'admin' ? '超级管理员' : '普通用户' }}</div>
            </div>
            <el-dropdown-item @click="router.push('/profile')" class="!rounded-lg !py-2">
              <el-icon><User /></el-icon>个人中心
            </el-dropdown-item>
            <el-dropdown-item divided @click="handleLogout" class="!rounded-lg !py-2 !text-red-500">
              <el-icon><SwitchButton /></el-icon>退出登录
            </el-dropdown-item>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
    </div>
  </div>
</template>

<style scoped>
:deep(.el-menu) {
  --el-menu-bg-color: transparent;
  --el-menu-hover-bg-color: rgba(59, 130, 246, 0.08);
  --el-menu-active-color: var(--el-color-primary);
}

:deep(.el-menu-item.is-active) {
  background-color: rgba(59, 130, 246, 0.1) !important;
  color: var(--el-color-primary);
  font-weight: 600;
}

:deep(.el-sub-menu__title) {
  border-radius: 8px;
  margin-bottom: 4px;
  height: 48px !important;
  line-height: 48px !important;
}

:deep(.el-sub-menu__title:hover) {
  background-color: rgba(59, 130, 246, 0.08) !important;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: transparent;
  border-radius: 4px;
}
.custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: var(--border-subtle);
}
</style>
