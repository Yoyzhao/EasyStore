import { defineStore } from 'pinia'
import { ref } from 'vue'
import request from '@/api/request'

export const useDashboardStore = defineStore('dashboard', () => {
  const stats = ref({
    total_items: 0,
    total_value: 0,
    low_stock_items: 0,
    recent_inbound: 0,
    recent_outbound: 0
  })

  const trend = ref({
    dates: [] as string[],
    inbound: [] as number[],
    outbound: [] as number[]
  })

  const fetchStats = async () => {
    const res: any = await request.get('/dashboard/stats')
    stats.value = res
  }

  const fetchTrend = async () => {
    const res: any = await request.get('/dashboard/trend')
    trend.value = res
  }

  return {
    stats,
    trend,
    fetchStats,
    fetchTrend
  }
})