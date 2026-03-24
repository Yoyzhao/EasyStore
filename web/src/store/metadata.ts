import { defineStore } from 'pinia'
import { ref } from 'vue'
import request from '@/api/request'

export const useMetadataStore = defineStore('metadata', () => {
  const categories = ref<any[]>([])
  const brands = ref<any[]>([])
  const units = ref<any[]>([])
  const usages = ref<any[]>([])

  const fetchMetadata = async () => {
    categories.value = await request.get('/metadata/?type=category')
    brands.value = await request.get('/metadata/?type=brand')
    units.value = await request.get('/metadata/?type=unit')
    usages.value = await request.get('/metadata/?type=usage')
  }

  const addMetadata = async (type: string, item: any) => {
    await request.post('/metadata/', { type, ...item })
    await fetchMetadata()
  }

  const updateMetadata = async (_type: string, item: any) => {
    await request.put(`/metadata/${item.id}`, item)
    await fetchMetadata()
  }

  const deleteMetadata = async (_type: string, id: number) => {
    await request.delete(`/metadata/${id}`)
    await fetchMetadata()
  }

  return {
    categories,
    brands,
    units,
    usages,
    fetchMetadata,
    addMetadata,
    updateMetadata,
    deleteMetadata
  }
})
