import { defineStore } from 'pinia'
import { ref } from 'vue'
import request from '@/api/request'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref({
    username: '',
    role: '', // 'admin' or 'user'
    avatar: ''
  })

  const login = async (form: any) => {
    const formData = new FormData()
    formData.append('username', form.username)
    formData.append('password', form.password)
    
    const res: any = await request.post('/auth/login', formData)
    token.value = res.access_token
    localStorage.setItem('token', token.value)
    await getUserInfo()
  }

  const getUserInfo = async () => {
    if (!token.value) return
    const res: any = await request.get('/auth/me')
    userInfo.value = {
      username: res.username,
      role: res.role,
      avatar: res.avatar || ''
    }
  }

  const logout = () => {
    token.value = ''
    userInfo.value = { username: '', role: '', avatar: '' }
    localStorage.removeItem('token')
    window.location.reload()
  }

  return {
    token,
    userInfo,
    login,
    getUserInfo,
    logout
  }
})
