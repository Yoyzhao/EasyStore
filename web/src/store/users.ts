import { defineStore } from 'pinia'
import { ref } from 'vue'
import dayjs from 'dayjs'

export interface UserItem {
  id: string
  username: string
  role: 'admin' | 'user'
  createdAt: string
  status: 'active' | 'disabled'
}

export const useUsersStore = defineStore('users', () => {
  // Mock Data
  const users = ref<UserItem[]>([
    {
      id: '1',
      username: 'admin',
      role: 'admin',
      createdAt: '2024-01-01 10:00:00',
      status: 'active'
    },
    {
      id: '2',
      username: 'user',
      role: 'user',
      createdAt: '2024-01-02 14:30:00',
      status: 'active'
    }
  ])

  const addUser = (user: Omit<UserItem, 'id' | 'createdAt' | 'status'>) => {
    if (users.value.some(u => u.username === user.username)) {
      throw new Error('用户名已存在')
    }
    users.value.push({
      id: Date.now().toString(),
      username: user.username,
      role: user.role,
      createdAt: dayjs().format('YYYY-MM-DD HH:mm:ss'),
      status: 'active'
    })
  }

  const updateUser = (id: string, data: Partial<UserItem>) => {
    const index = users.value.findIndex(u => u.id === id)
    if (index !== -1) {
      // Check username conflict if changing username
      if (data.username && data.username !== users.value[index].username) {
         if (users.value.some(u => u.username === data.username)) {
           throw new Error('用户名已存在')
         }
      }
      users.value[index] = { ...users.value[index], ...data }
    }
  }

  const deleteUser = (id: string) => {
    const index = users.value.findIndex(u => u.id === id)
    if (index !== -1) {
      if (users.value[index].username === 'admin') {
        throw new Error('无法删除初始管理员账户')
      }
      users.value.splice(index, 1)
    }
  }

  return {
    users,
    addUser,
    updateUser,
    deleteUser
  }
})
