import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import dayjs from 'dayjs'

export interface InventoryItem {
  id: string
  name: string
  category: string
  brand?: string
  quantity: number
  price: number
  unit: string
  lowStockThreshold: number
  imageUrl?: string
  itemLink?: string
  remark?: string
  updatedAt: string
}

export interface OperationRecord {
  id: string
  itemId: string
  itemName: string
  type: 'in' | 'out'
  quantity: number
  price: number // Unit price at the time
  totalValue: number
  operator: string
  recipient?: string // 领用人
  remark?: string
  time: string
}

export const useInventoryStore = defineStore('inventory', () => {
  // Initial Mock Data
  const items = ref<InventoryItem[]>([
    {
      id: '1',
      name: 'A4打印纸',
      category: '办公用品',
      brand: '得力',
      quantity: 50,
      price: 25.0,
      unit: '包',
      lowStockThreshold: 10,
      remark: '常用办公耗材，请注意防潮',
      imageUrl: 'https://images.unsplash.com/photo-1586075010923-2dd4570fb338?auto=format&fit=crop&q=80&w=200',
      itemLink: 'https://item.jd.com/100000000001.html',
      updatedAt: dayjs().format('YYYY-MM-DD HH:mm:ss')
    },
    {
      id: '2',
      name: '黑色签字笔',
      category: '办公用品',
      brand: '晨光',
      quantity: 5,
      price: 2.5,
      unit: '支',
      lowStockThreshold: 20, // Low stock!
      remark: '会议室和前台备用',
      updatedAt: dayjs().format('YYYY-MM-DD HH:mm:ss')
    },
    {
      id: '3',
      name: '笔记本电脑',
      category: '电子设备',
      brand: '联想',
      quantity: 10,
      price: 5000.0,
      unit: '台',
      lowStockThreshold: 2,
      remark: '研发部新员工标配',
      imageUrl: 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&q=80&w=200',
      updatedAt: dayjs().format('YYYY-MM-DD HH:mm:ss')
    }
  ])

  const records = ref<OperationRecord[]>([
    {
      id: '1',
      itemId: '1',
      itemName: 'A4打印纸',
      type: 'in',
      quantity: 50,
      price: 25.0,
      totalValue: 1250.0,
      operator: 'Admin',
      remark: '初始入库',
      time: dayjs().subtract(1, 'day').format('YYYY-MM-DD HH:mm:ss')
    }
  ])

  // Getters
  const lowStockItems = computed(() => {
    return items.value.filter(item => item.quantity < item.lowStockThreshold)
  })

  const totalInventoryValue = computed(() => {
    return items.value.reduce((total, item) => total + item.quantity * item.price, 0)
  })

  // Actions
  const inbound = (data: Omit<InventoryItem, 'id' | 'updatedAt'> & { operator: string, remark?: string }) => {
    // Check if item exists (by name and brand/category for simplicity)
    const existingItem = items.value.find(
      item => item.name === data.name && item.brand === data.brand && item.category === data.category
    )

    const now = dayjs().format('YYYY-MM-DD HH:mm:ss')

    if (existingItem) {
      existingItem.quantity += data.quantity
      existingItem.price = data.price // Update latest price
      existingItem.updatedAt = now
      
      // Add record
      records.value.unshift({
        id: Date.now().toString(),
        itemId: existingItem.id,
        itemName: existingItem.name,
        type: 'in',
        quantity: data.quantity,
        price: data.price,
        totalValue: data.quantity * data.price,
        operator: data.operator,
        remark: data.remark,
        time: now
      })
    } else {
      const newItem: InventoryItem = {
        id: Date.now().toString(),
        name: data.name,
        category: data.category,
        brand: data.brand,
        quantity: data.quantity,
        price: data.price,
        unit: data.unit,
        lowStockThreshold: data.lowStockThreshold,
        imageUrl: data.imageUrl,
        itemLink: data.itemLink,
        updatedAt: now
      }
      items.value.push(newItem)

      // Add record
      records.value.unshift({
        id: Date.now().toString(),
        itemId: newItem.id,
        itemName: newItem.name,
        type: 'in',
        quantity: data.quantity,
        price: data.price,
        totalValue: data.quantity * data.price,
        operator: data.operator,
        remark: data.remark,
        time: now
      })
    }
  }

  const outbound = (data: { itemId: string, quantity: number, operator: string, usage?: string, recipient?: string, remark?: string }) => {
    const item = items.value.find(i => i.id === data.itemId)
    if (!item) {
      throw new Error('物品不存在')
    }
    if (item.quantity < data.quantity) {
      throw new Error(`库存不足，当前仅剩 ${item.quantity} ${item.unit}`)
    }

    item.quantity -= data.quantity
    item.updatedAt = dayjs().format('YYYY-MM-DD HH:mm:ss')

    const now = dayjs().format('YYYY-MM-DD HH:mm:ss')
    
    records.value.unshift({
      id: Date.now().toString(),
      itemId: item.id,
      itemName: item.name,
      type: 'out',
      quantity: data.quantity,
      price: item.price,
      totalValue: data.quantity * item.price,
      operator: data.operator,
      recipient: data.recipient,
      remark: `用途/去向: ${data.usage || '无'} - ${data.remark || ''}`,
      time: now
    })
  }

  const deleteItem = (id: string) => {
    const index = items.value.findIndex(item => item.id === id)
    if (index !== -1) {
      items.value.splice(index, 1)
    }
  }

  const updateItem = (id: string, data: Partial<InventoryItem>) => {
    const item = items.value.find(i => i.id === id)
    if (item) {
      Object.assign(item, data)
      item.updatedAt = dayjs().format('YYYY-MM-DD HH:mm:ss')
    }
  }

  return {
    items,
    records,
    lowStockItems,
    totalInventoryValue,
    inbound,
    outbound,
    deleteItem,
    updateItem
  }
})
