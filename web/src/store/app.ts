import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  const sidebarCollapsed = ref(false)
  const isMobile = ref(false)

  const toggleSidebar = () => {
    sidebarCollapsed.value = !sidebarCollapsed.value
  }

  const setSidebarCollapsed = (value: boolean) => {
    sidebarCollapsed.value = value
  }

  const setIsMobile = (value: boolean) => {
    isMobile.value = value
    if (value) {
      sidebarCollapsed.value = true
    }
  }

  return {
    sidebarCollapsed,
    isMobile,
    toggleSidebar,
    setSidebarCollapsed,
    setIsMobile
  }
})
