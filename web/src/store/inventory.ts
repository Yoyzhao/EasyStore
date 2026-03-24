import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import request from '@/api/request'

export interface InventoryItem {
  id: number
  name: string
  category: string
  brand?: string
  quantity: number
  price: number
  unit: string
  low_stock_threshold: number
  image_url?: string
  item_link?: string
  remark?: string
  updated_at?: string
}

export interface OperationRecord {
  id: number
  item_id: number
  item_name: string
  type: 'in' | 'out'
  quantity: number
  price: number
  total_value: number
  operator: string
  recipient?: string
  remark?: string
  time: string
}

export const useInventoryStore = defineStore('inventory', () => {
  const items = ref<InventoryItem[]>([])
  const records = ref<OperationRecord[]>([])

  const lowStockItems = computed(() => {
    return items.value.filter(item => item.quantity < item.low_stock_threshold)
  })

  const totalInventoryValue = computed(() => {
    return items.value.reduce((total, item) => total + item.quantity * item.price, 0)
  })

  const fetchItems = async (search?: string, category?: string) => {
    const params: any = {}
    if (search) params.search = search
    if (category) params.category = category
    const res: any = await request.get('/items/', { params })
    items.value = res
  }

  const fetchRecords = async () => {
    const res: any = await request.get('/transactions/')
    records.value = res
  }

  const inbound = async (data: any) => {
    await request.post('/transactions/inbound', data)
    await fetchItems()
    await fetchRecords()
  }

  const outbound = async (data: any) => {
    await request.post('/transactions/outbound', data)
    await fetchItems()
    await fetchRecords()
  }

  const deleteItem = async (id: number) => {
    await request.delete(`/items/${id}`)
    await fetchItems()
  }

  const updateItem = async (id: number, data: Partial<InventoryItem>) => {
    await request.put(`/items/${id}`, data)
    await fetchItems()
  }

  return {
    items,
    records,
    lowStockItems,
    totalInventoryValue,
    fetchItems,
    fetchRecords,
    inbound,
    outbound,
    deleteItem,
    updateItem
  }
})
