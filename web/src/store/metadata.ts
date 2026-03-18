import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useMetadataStore = defineStore('metadata', () => {
  const categories = ref([
    { id: 1, name: '电子产品', description: '手机、电脑等' },
    { id: 2, name: '办公用品', description: '纸张、笔具等' },
    { id: 3, name: '食品饮料', description: '零食、饮料等' },
    { id: 4, name: '日用品', description: '日常生活用品' }
  ])

  const brands = ref([
    { id: 1, name: 'Apple', description: '苹果' },
    { id: 2, name: '得力', description: '办公用品品牌' },
    { id: 3, name: '百事', description: '饮料品牌' }
  ])

  const units = ref([
    { id: 1, name: '个' },
    { id: 2, name: '包' },
    { id: 3, name: '箱' },
    { id: 4, name: '台' },
    { id: 5, name: '支' },
    { id: 6, name: '件' }
  ])

  const usages = ref([
    { id: 1, name: '研发测试', description: '用于研发部门内部测试' },
    { id: 2, name: '日常办公', description: '日常办公消耗' },
    { id: 3, name: '项目交付', description: '交付给客户的项目物资' }
  ])

  const addMetadata = (type: string, item: any) => {
    const target = type === 'category' ? categories : (type === 'brand' ? brands : (type === 'unit' ? units : usages))
    target.value.push(item)
  }

  const updateMetadata = (type: string, item: any) => {
    const target = type === 'category' ? categories : (type === 'brand' ? brands : (type === 'unit' ? units : usages))
    const index = target.value.findIndex((i: any) => i.id === item.id)
    if (index !== -1) {
      target.value[index] = item
    }
  }

  const deleteMetadata = (type: string, id: number) => {
    if (type === 'category') {
      categories.value = categories.value.filter(item => item.id !== id)
    } else if (type === 'brand') {
      brands.value = brands.value.filter(item => item.id !== id)
    } else if (type === 'unit') {
      units.value = units.value.filter(item => item.id !== id)
    } else {
      usages.value = usages.value.filter(item => item.id !== id)
    }
  }

  return {
    categories,
    brands,
    units,
    usages,
    addMetadata,
    updateMetadata,
    deleteMetadata
  }
})
