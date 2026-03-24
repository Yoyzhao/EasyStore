<script setup lang="ts">
import { reactive, computed, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { useInventoryStore } from '@/store/inventory'

const inventoryStore = useInventoryStore()

onMounted(() => {
  inventoryStore.fetchRecords()
})

const searchForm = reactive({
  keyword: '',
  type: ''
})

const tableData = computed(() => {
  return inventoryStore.records.map(record => ({
    ...record,
    createdAt: new Date(record.time.endsWith('Z') || record.time.includes('+') ? record.time : record.time + 'Z').toLocaleString('zh-CN', { hour12: false }),
    name: record.item_name
  })).filter(record => {
    let match = true
    if (searchForm.keyword) {
      match = match && record.name.includes(searchForm.keyword)
    }
    if (searchForm.type) {
      match = match && record.type === searchForm.type
    }
    return match
  })
})

const handleSearch = () => {
  // handled by computed tableData
}

const handleReset = () => {
  searchForm.keyword = ''
  searchForm.type = ''
}
</script>

<template>
  <div class="h-full flex flex-col gap-4">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">流转明细</h1>
    </div>

    <el-card shadow="hover" class="border-none" style="background-color: var(--el-bg-color-overlay);">
      <el-form :inline="true" :model="searchForm" class="flex flex-wrap items-center gap-x-4 gap-y-2">
        <el-form-item label="关键词" class="!mb-0">
          <el-input v-model="searchForm.keyword" placeholder="物品名称" :prefix-icon="Search" style="width: 240px" clearable />
        </el-form-item>
        <el-form-item label="类型" class="!mb-0">
          <el-select v-model="searchForm.type" placeholder="全部类型" clearable style="width: 160px">
            <el-option label="入库" value="in" />
            <el-option label="出库" value="out" />
          </el-select>
        </el-form-item>
        <el-form-item class="!mb-0 ml-auto mr-0">
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="hover" class="flex-1 flex flex-col border-none" style="background-color: var(--el-bg-color-overlay);" :body-style="{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }">
      <el-table :data="tableData" stripe style="width: 100%; flex: 1;" height="100%">
        <el-table-column prop="createdAt" label="操作时间" width="180" />
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.type === 'in' ? 'success' : 'warning'">
              {{ row.type === 'in' ? '入库' : '出库' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="物品名称" min-width="150" />
        <el-table-column prop="quantity" label="变动数量" width="120" align="right">
          <template #default="{ row }">
            <span :class="row.type === 'in' ? 'text-green-600' : 'text-orange-600'">
              {{ row.type === 'in' ? '+' : '-' }}{{ row.quantity }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="price" label="单价 (元)" width="120" align="right">
          <template #default="{ row }">
            {{ row.price ? row.price.toFixed(2) : '0.00' }}
          </template>
        </el-table-column>
        <el-table-column prop="operator" label="操作人" width="120" />
        <el-table-column prop="recipient" label="领用人" width="120" />
        <el-table-column prop="remark" label="备注" min-width="150" show-overflow-tooltip />
      </el-table>

      <div class="pt-4 mt-4 flex justify-end border-t" style="border-color: var(--el-border-color-lighter);">
        <el-pagination
          background
          layout="total, sizes, prev, pager, next, jumper"
          :total="100"
          :page-sizes="[10, 20, 50, 100]"
        />
      </div>
    </el-card>
  </div>
</template>
