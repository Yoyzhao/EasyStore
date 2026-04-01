import axios from 'axios'
import { useUserStore } from '@/store/user'
import { ElMessage } from 'element-plus'

const isElectron = window.navigator.userAgent.toLowerCase().includes('electron')
const request = axios.create({
  baseURL: isElectron ? 'http://localhost:8000/api/v1' : '/api/v1',
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
