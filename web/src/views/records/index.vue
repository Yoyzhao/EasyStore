<script setup lang="ts">
import { reactive, computed, onMounted, ref } from 'vue'
import { Search, Download } from '@element-plus/icons-vue'
import { useInventoryStore } from '@/store/inventory'
import { storeToRefs } from 'pinia'
import * as XLSX from 'xlsx'

const inventoryStore = useInventoryStore()
const { totalRecords } = storeToRefs(inventoryStore)

const searchForm = reactive({
  keyword: '',
  type: '',
  dateRange: [] as [Date, Date] | []
})

const page = ref(1)
const pageSize = ref(10)

onMounted(() => {
  fetchData()
})

const fetchData = () => {
  let startDate = ''
  let endDate = ''
  if (searchForm.dateRange && Array.isArray(searchForm.dateRange) && searchForm.dateRange.length === 2) {
    startDate = searchForm.dateRange[0].toISOString()
    const end = new Date(searchForm.dateRange[1])
    end.setHours(23, 59, 59, 999)
    endDate = end.toISOString()
  }
  inventoryStore.fetchRecords(
    searchForm.keyword, 
    searchForm.type, 
    (page.value - 1) * pageSize.value, 
    pageSize.value,
    startDate,
    endDate
  )
}

const tableData = computed(() => {
  return inventoryStore.records.map(record => ({
    ...record,
    createdAt: new Date(record.time.endsWith('Z') || record.time.includes('+') ? record.time : record.time + 'Z').toLocaleString('zh-CN', { hour12: false }),
    name: record.item_name,
    remark: record.remark ? record.remark.replace('Usage/Destination:', '用途/去向:') : '-'
  }))
})

const handleSearch = () => {
  page.value = 1
  fetchData()
}

const handleReset = () => {
  searchForm.keyword = ''
  searchForm.type = ''
  searchForm.dateRange = []
  page.value = 1
  fetchData()
}

const handleSizeChange = (val: number) => {
  pageSize.value = val
  page.value = 1
  fetchData()
}

const handleCurrentChange = (val: number) => {
  page.value = val
  fetchData()
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
  <div class="h-full max-w-7xl mx-auto flex flex-col gap-6">
    <!-- 头部区域 -->
    <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 relative overflow-hidden group">
      <!-- 装饰圆圈 -->
      <div class="absolute -right-10 -top-10 w-32 h-32 rounded-full opacity-5 bg-[#3B82F6] group-hover:opacity-10 group-hover:scale-110 transition-all duration-700 ease-out origin-top-right"></div>
      
      <div class="relative z-10">
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">流转明细</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">查看所有物品的入库和出库记录</p>
      </div>
    </div>

    <!-- 搜索筛选区 -->
    <div class="bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] p-6 mb-0">
      <el-form :model="searchForm" class="flex flex-wrap items-center gap-3 w-full" @submit.prevent="handleSearch">
        <el-form-item class="!mb-0 !mr-0">
          <el-input v-model="searchForm.keyword" placeholder="物品名称/ID" :prefix-icon="Search" class="!w-60 !rounded-xl" clearable @clear="handleSearch" />
        </el-form-item>
        <el-form-item class="!mb-0 !mr-0">
          <el-select v-model="searchForm.type" placeholder="全部类型" clearable class="!w-32 !rounded-xl" @change="handleSearch">
            <el-option label="入库" value="in" />
            <el-option label="出库" value="out" />
          </el-select>
        </el-form-item>
        <el-form-item class="!mb-0 !mr-0">
          <el-date-picker
            v-model="searchForm.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            class="!w-72 !rounded-xl"
            @change="handleSearch"
            :shortcuts="[
              { text: '最近一周', value: () => [new Date(Date.now() - 3600 * 1000 * 24 * 7), new Date()] },
              { text: '最近一月', value: () => [new Date(Date.now() - 3600 * 1000 * 24 * 30), new Date()] },
              { text: '最近三月', value: () => [new Date(Date.now() - 3600 * 1000 * 24 * 90), new Date()] }
            ]"
          />
        </el-form-item>
        <el-form-item class="!mb-0 !mr-0 ml-auto">
          <div class="flex items-center gap-2">
            <el-button type="primary" @click="handleSearch" class="!rounded-xl !h-10 font-medium px-6">查询</el-button>
            <el-button @click="handleReset" class="!rounded-xl !h-10 font-medium px-6 hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">重置</el-button>
            <el-button type="success" :icon="Download" @click="handleExport" class="!rounded-xl !h-10 font-medium shadow-sm shadow-green-500/20 px-6">导出 Excel</el-button>
          </div>
        </el-form-item>
      </el-form>
    </div>

    <!-- 表格区域 -->
    <div class="flex-1 flex flex-col bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] p-6 overflow-hidden">
      <el-table :data="tableData" style="width: 100%; flex: 1;" height="100%" class="custom-table" :header-cell-style="{ background: 'var(--el-fill-color-light)', color: 'var(--text-main)', fontWeight: '600', height: '48px' }">
        <el-table-column prop="createdAt" label="操作时间" width="180">
          <template #default="{ row }">
            <span class="text-[var(--text-muted)]">{{ row.createdAt }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="type" label="类型" width="100">
          <template #default="{ row }">
            <div :class="row.type === 'in' ? 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400' : 'bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400'" class="inline-flex items-center justify-center px-2.5 py-1 rounded-md text-xs font-medium border border-transparent">
              {{ row.type === 'in' ? '入库' : '出库' }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="item_id" label="物品ID" width="100">
          <template #default="{ row }">
            <span class="font-mono text-[var(--text-muted)] text-sm"><span class="text-[10px] opacity-60 mr-0.5">ID:</span>{{ row.item_id }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="物品名称" min-width="150">
          <template #default="{ row }">
            <span class="font-medium text-[var(--text-main)]">{{ row.name }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="quantity" label="变动数量" width="120" align="right">
          <template #default="{ row }">
            <span :class="row.type === 'in' ? 'text-green-600 dark:text-green-400 font-bold' : 'text-orange-600 dark:text-orange-400 font-bold'" class="text-base">
              {{ row.type === 'in' ? '+' : '-' }}{{ row.quantity }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="price" label="单价 (元)" width="120" align="right">
          <template #default="{ row }">
            <span class="text-[var(--text-muted)] font-mono">¥{{ row.price ? row.price.toFixed(2) : '0.00' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="operator" label="操作人" width="120">
          <template #default="{ row }">
            <div class="flex items-center gap-2">
              <div class="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/50 flex items-center justify-center text-blue-600 dark:text-blue-400 text-xs font-bold">
                {{ row.operator.charAt(0).toUpperCase() }}
              </div>
              <span class="text-sm">{{ row.operator }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="recipient" label="领用人" width="120">
          <template #default="{ row }">
            <span class="text-[var(--text-muted)]">{{ row.recipient || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="150" show-overflow-tooltip>
          <template #default="{ row }">
            <span class="text-[var(--text-muted)] truncate">{{ row.remark || '-' }}</span>
          </template>
        </el-table-column>
      </el-table>

      <div class="p-4 flex justify-end border-t border-[var(--border-subtle)] bg-[var(--card-bg)]">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          background
          layout="total, sizes, prev, pager, next, jumper"
          :total="totalRecords"
          :page-sizes="[10, 20, 50, 100]"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          class="custom-pagination"
        />
      </div>
    </div>
  </div>
</template>
