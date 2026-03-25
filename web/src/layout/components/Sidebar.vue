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
  <div class="h-full transition-all duration-300 flex flex-col overflow-hidden" style="background-color: var(--el-bg-color); border-right: 1px solid var(--el-border-color-light);">
    <div class="h-16 flex items-center shrink-0 gap-2 px-4" style="border-bottom: 1px solid var(--el-border-color-light);">
      <el-icon :size="28" style="color: var(--el-color-primary)"><Box /></el-icon>
      <h1 
        v-show="!appStore.sidebarCollapsed"
        class="text-xl font-bold truncate transition-opacity duration-300" 
        style="color: var(--el-text-color-primary)"
      >
        EasyStore
      </h1>
    </div>
    
    <el-menu
      :default-active="route.path"
      :collapse="appStore.sidebarCollapsed"
      class="border-none flex-1 overflow-y-auto"
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
            <span>{{ menu.meta?.title }}</span>
          </template>
          
          <template v-for="child in menu.children" :key="child.path">
            <el-menu-item v-if="!child.meta?.hidden && hasPermission(child)" :index="resolvePath(menu.path, child.path)">
              <el-icon v-if="child.meta?.icon">
                <component :is="child.meta.icon" />
              </el-icon>
              <template #title>
                <span>{{ child.meta?.title }}</span>
              </template>
            </el-menu-item>
          </template>
        </el-sub-menu>

        <!-- 没有子菜单的情况 -->
        <el-menu-item v-else-if="!menu.meta?.hidden && hasPermission(menu)" :index="resolvePath(menu.path)">
          <el-icon v-if="menu.meta?.icon">
            <component :is="menu.meta.icon" />
          </el-icon>
          <template #title>
            <span>{{ menu.meta?.title }}</span>
          </template>
        </el-menu-item>
      </template>
    </el-menu>

    <!-- 用户操作区域 -->
    <div class="p-4 mt-auto shrink-0" style="border-top: 1px solid var(--el-border-color-light);">
      <el-dropdown trigger="click" placement="top" class="w-full">
        <div class="flex items-center justify-between w-full cursor-pointer p-2 rounded transition-colors duration-300 hover:bg-gray-100 dark:hover:bg-gray-800">
          <div class="flex items-center overflow-hidden">
            <el-avatar :size="32" src="https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png" class="shrink-0" />
            <span 
              v-show="!appStore.sidebarCollapsed"
              class="ml-2 text-sm font-medium truncate transition-opacity duration-300" 
              style="color: var(--el-text-color-primary)"
            >
              {{ userStore.userInfo.username }}
            </span>
          </div>
          <el-icon v-show="!appStore.sidebarCollapsed" style="color: var(--el-text-color-secondary)"><ArrowUp /></el-icon>
        </div>
        <template #dropdown>
          <el-dropdown-menu class="w-48">
            <el-dropdown-item @click="router.push('/profile')">个人中心</el-dropdown-item>
            <el-dropdown-item divided @click="handleLogout">退出登录</el-dropdown-item>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
    </div>
  </div>
</template>

<style scoped>
.el-menu {
  background-color: transparent;
}
.hover-bg-fill:hover {
  background-color: var(--el-fill-color-light);
}
</style>
