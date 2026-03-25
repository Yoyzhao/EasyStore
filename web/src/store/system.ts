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
