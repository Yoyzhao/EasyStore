import { defineStore } from 'pinia'
import { ref } from 'vue'
import request from '@/api/request'

export interface UserItem {
  id: number
  username: string
  role: 'admin' | 'user'
  created_at: string
  is_active: boolean
}

export const useUsersStore = defineStore('users', () => {
  const users = ref<UserItem[]>([])
  
  const fetchUsers = async () => {
    const res: any = await request.get('/users/')
    users.value = res
  }

  const addUser = async (user: any) => {
    await request.post('/users/', {
      username: user.username,
      password: user.password,
      role: user.role,
      is_active: user.status === 'active'
    })
    await fetchUsers()
  }

  const updateUser = async (id: number, data: any) => {
    const updateData: any = {
      username: data.username,
      role: data.role,
      is_active: data.status === 'active'
    }
    if (data.password && data.password !== '******') {
      updateData.password = data.password
    }
    await request.put(`/users/${id}`, updateData)
    await fetchUsers()
  }

  const deleteUser = async (id: number) => {
    await request.delete(`/users/${id}`)
    await fetchUsers()
  }

  return {
    users,
    fetchUsers,
    addUser,
    updateUser,
    deleteUser
  }
})
