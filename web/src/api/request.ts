import axios from 'axios'
import { useUserStore } from '@/store/user'
import { ElMessage } from 'element-plus'

const isElectron = window.navigator.userAgent.toLowerCase().includes('electron')

// 只有在 Electron 环境下才尝试从 URL 获取动态端口，网页版保持原来的 VITE_API_URL 逻辑
let dynamicPort = '8000'
if (isElectron) {
  const urlParams = new URLSearchParams(window.location.search)
  dynamicPort = urlParams.get('port') || '8000'
}

export const BACKEND_URL = isElectron 
  ? `http://127.0.0.1:${dynamicPort}` 
  : (import.meta.env.VITE_API_URL || '')

export const API_BASE_URL = isElectron
  ? `${BACKEND_URL}/api/v1`
  : (import.meta.env.VITE_API_URL ? `${import.meta.env.VITE_API_URL}/api/v1` : '/api/v1')

const request = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000
})

request.interceptors.request.use(
  (config) => {
    const userStore = useUserStore()
    if (userStore.token) {
      config.headers['Authorization'] = `Bearer ${userStore.token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

request.interceptors.response.use(
  (response) => {
    return response.data
  },
  (error) => {
    const { response } = error
    if (response) {
      ElMessage.error(response.data.detail || '请求失败')
      if (response.status === 401 || response.status === 403) {
        const userStore = useUserStore()
        userStore.logout()
      }
    } else {
      ElMessage.error('网络异常，请稍后再试')
    }
    return Promise.reject(error)
  }
)

export const uploadFile = async (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  const res: any = await request.post('/upload/', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
  return res.url
}

export default request
