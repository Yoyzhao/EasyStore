import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import Layout from '@/layout/index.vue'
import { useUserStore } from '@/store/user'

const routes: Array<RouteRecordRaw> = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: { title: '登录', hidden: true }
  },
  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue'),
        meta: { title: '仪表盘', icon: 'Odometer' }
      },
      {
        path: 'inventory',
        name: 'Inventory',
        redirect: '/inventory/list',
        meta: { title: '物品与库存', icon: 'Box' },
        children: [
          {
            path: 'list',
            name: 'InventoryList',
            component: () => import('@/views/inventory/index.vue'),
            meta: { title: '库存列表', icon: 'List' }
          },
          {
            path: 'in',
            name: 'InventoryIn',
            component: () => import('@/views/inventory/in.vue'),
            meta: { title: '物品入库', icon: 'Download', roles: ['admin'] }
          },
          {
            path: 'out',
            name: 'InventoryOut',
            component: () => import('@/views/inventory/out.vue'),
            meta: { title: '物品出库', icon: 'Upload', roles: ['admin'] }
          }
        ]
      },
      {
        path: 'records',
        name: 'Records',
        component: () => import('@/views/records/index.vue'),
        meta: { title: '流转明细', icon: 'Document', roles: ['admin'] }
      },
      {
        path: 'metadata',
        name: 'Metadata',
        component: () => import('@/views/metadata/index.vue'),
        meta: { title: '元数据管理', icon: 'Setting', roles: ['admin'] }
      },
      {
        path: 'users',
        name: 'Users',
        component: () => import('@/views/user/index.vue'),
        meta: { title: '用户管理', icon: 'User', roles: ['admin'] }
      }
    ]
  },
  {
    path: '/403',
    name: '403',
    component: () => import('@/views/error/403.vue'),
    meta: { title: '无权限', hidden: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Route Guard
router.beforeEach((to, _from, next) => {
  const userStore = useUserStore()
  const token = userStore.token

  if (to.path === '/login') {
    if (token) {
      next('/')
    } else {
      next()
    }
  } else {
    if (!token) {
      next('/login')
    } else {
      // Check RBAC
      if (to.meta.roles) {
        const roles = to.meta.roles as string[]
        if (roles.includes(userStore.userInfo.role)) {
          next()
        } else {
          next('/403')
        }
      } else {
        next()
      }
    }
  }
})

export default router
