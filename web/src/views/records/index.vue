<script setup lang="ts">
import { reactive, computed, onMounted } from 'vue'
import { Search, Download } from '@element-plus/icons-vue'
import { useInventoryStore } from '@/store/inventory'
import * as XLSX from 'xlsx'

const inventoryStore = useInventoryStore()

onMounted(() => {
  inventoryStore.fetchRecords()
})

const searchForm = reactive({
  keyword: '',
  type: '',
  dateRange: [] as [Date, Date] | []
})

const tableData = computed(() => {
  return inventoryStore.records.map(record => ({
    ...record,
    createdAt: new Date(record.time.endsWith('Z') || record.time.includes('+') ? record.time : record.time + 'Z').toLocaleString('zh-CN', { hour12: false }),
    name: record.item_name
  })).filter(record => {
    let match = true
    if (searchForm.keyword) {
      const keyword = searchForm.keyword.toLowerCase()
      match = match && (
        record.name.toLowerCase().includes(keyword) || 
        record.item_id.toString().includes(keyword)
      )
    }
    if (searchForm.type) {
      match = match && record.type === searchForm.type
    }
    if (searchForm.dateRange && searchForm.dateRange.length === 2) {
      const start = searchForm.dateRange[0].getTime()
      const end = searchForm.dateRange[1].getTime() + 24 * 60 * 60 * 1000 - 1 // End of the day
      const recordTime = new Date(record.time.endsWith('Z') || record.time.includes('+') ? record.time : record.time + 'Z').getTime()
      match = match && (recordTime >= start && recordTime <= end)
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
  searchForm.dateRange = []
}

const handleExport = () => {
  const exportData = tableData.value.map(item => ({
    '操作时间': item.createdAt,
    '类型': item.type === 'in' ? '入库' : '出库',
    '物品ID': item.item_id,
    '物品名称': item.name,
    '变动数量': (item.type === 'in' ? '+' : '-') + item.quantity,
    '单价 (元)': item.price.toFixed(2),
    '操作人': item.operator,
    '领用人': item.recipient || '-',
    '备注': item.remark || '-'
  }))

  const worksheet = XLSX.utils.json_to_sheet(exportData)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, '流转明细')
  
  // Set column widths
  const wscols = [
    { wch: 20 }, // 操作时间
    { wch: 8 },  // 类型
    { wch: 10 }, // 物品ID
    { wch: 20 }, // 物品名称
    { wch: 10 }, // 变动数量
    { wch: 12 }, // 单价
    { wch: 12 }, // 操作人
    { wch: 12 }, // 领用人
    { wch: 30 }  // 备注
  ]
  worksheet['!cols'] = wscols

  const fileName = `流转明细_${new Date().toLocaleDateString().replace(/\//g, '-')}.xlsx`
  XLSX.writeFile(workbook, fileName)
}
</script>

<template>
  <div class="h-full flex flex-col gap-4">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">流转明细</h1>
    </div>

    <el-card shadow="hover" class="border-none" style="background-color: var(--el-bg-color-overlay);">
      <el-form :model="searchForm" label-width="70px">
        <el-row :gutter="20">
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="关键词" class="!mb-4 md:!mb-0">
              <el-input v-model="searchForm.keyword" placeholder="物品名称/ID" :prefix-icon="Search" class="w-full" clearable />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="4">
            <el-form-item label="类型" class="!mb-4 md:!mb-0">
              <el-select v-model="searchForm.type" placeholder="全部类型" clearable class="w-full">
                <el-option label="入库" value="in" />
                <el-option label="出库" value="out" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="24" :md="8" :lg="8">
            <el-form-item label="时间范围" class="!mb-4 md:!mb-0">
              <el-date-picker
                v-model="searchForm.dateRange"
                type="daterange"
                range-separator="至"
                start-placeholder="开始日期"
                end-placeholder="结束日期"
                class="!w-full"
                :shortcuts="[
                  { text: '最近一周', value: () => [new Date(Date.now() - 3600 * 1000 * 24 * 7), new Date()] },
                  { text: '最近一月', value: () => [new Date(Date.now() - 3600 * 1000 * 24 * 30), new Date()] },
                  { text: '最近三月', value: () => [new Date(Date.now() - 3600 * 1000 * 24 * 90), new Date()] }
                ]"
              />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="24" :md="24" :lg="6" class="flex justify-end items-center gap-2">
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
            <el-button type="success" :icon="Download" @click="handleExport">导出 Excel</el-button>
          </el-col>
        </el-row>
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
        <el-table-column prop="item_id" label="物品ID" width="100" />
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
