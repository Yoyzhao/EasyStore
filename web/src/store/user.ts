import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref({
    username: 'Admin',
    role: 'admin' // 'admin' or 'user'
  })

  const login = async (form: any) => {
    // Mock login logic
    return new Promise<void>((resolve, reject) => {
      setTimeout(() => {
        if (form.username === 'admin' && form.password === '123456') {
          token.value = 'mock-token-admin'
          userInfo.value = { username: 'Admin', role: 'admin' }
          localStorage.setItem('token', token.value)
          resolve()
        } else if (form.username === 'user' && form.password === '123456') {
          token.value = 'mock-token-user'
          userInfo.value = { username: 'User', role: 'user' }
          localStorage.setItem('token', token.value)
          resolve()
        } else {
          reject(new Error('用户名或密码错误'))
        }
      }, 500)
    })
  }

  const logout = () => {
    token.value = ''
    userInfo.value = { username: '', role: '' }
    localStorage.removeItem('token')
    window.location.reload()
  }

  return {
    token,
    userInfo,
    login,
    logout
  }
})
