import { defineStore } from 'pinia'
import request from '@/api/request'

interface SystemSettings {
  upload: {
    max_size_mb: number
    allowed_extensions: string[]
  }
  access: {
    allow_external_ip: boolean
  }
  storage: {
    data_path: string
  }
  general: {
    project_name: string
    port: number
  }
}

export const useSystemStore = defineStore('system', {
  state: () => ({
    settings: {
      upload: {
        max_size_mb: 5,
        allowed_extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp']
      },
      access: {
        allow_external_ip: false
      },
      storage: {
        data_path: 'data'
      },
      general: {
        project_name: 'EasyStore',
        port: 8000
      }
    } as SystemSettings,
    isLoaded: false
  }),
  actions: {
    async fetchSettings() {
      try {
        const res: any = await request.get('/system/settings')
        this.settings = res
        this.isLoaded = true
      } catch (error) {
        console.error('Failed to fetch system settings', error)
      }
    }
  }
})
