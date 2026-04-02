<script setup lang="ts">
import { reactive, computed, ref, onMounted } from 'vue'
import { Search, Plus, Edit, Delete, View, Download, Minus } from '@element-plus/icons-vue'
import { formatToUTC8 } from '@/utils/date'
import { useRouter } from 'vue-router'
import { useInventoryStore } from '@/store/inventory'
import { useMetadataStore } from '@/store/metadata'
import { useSystemStore } from '@/store/system'
import { useUserStore } from '@/store/user'
import { useAppStore } from '@/store/app'
import { storeToRefs } from 'pinia'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import * as XLSX from 'xlsx'
import ImageCropper from '@/components/ImageCropper.vue'

const router = useRouter()
const inventoryStore = useInventoryStore()
const metadataStore = useMetadataStore()
const systemStore = useSystemStore()
const userStore = useUserStore()
const appStore = useAppStore()

const { categories, brands } = storeToRefs(metadataStore)
const { totalItems } = storeToRefs(inventoryStore)

// 裁剪相关
const imageCropperRef = ref()

const searchForm = reactive({
  keyword: '',
  category: '',
  brand: ''
})

const page = ref(1)
const pageSize = ref(10)

onMounted(() => {
  fetchData()
  inventoryStore.fetchRecords()
  metadataStore.fetchMetadata()
  if (!systemStore.isLoaded && userStore.userInfo?.role === 'admin') {
    systemStore.fetchSettings()
  }
})

const fetchData = () => {
  inventoryStore.fetchItems(
    searchForm.keyword,
    searchForm.category,
    searchForm.brand,
    (page.value - 1) * pageSize.value,
    pageSize.value
  )
}

const tableData = computed(() => inventoryStore.items)

const detailVisible = ref(false)
const currentItem = ref<any>(null)
const itemRecords = computed(() => {
  if (!currentItem.value) return []
  return inventoryStore.records.filter(r => r.item_id === currentItem.value.id)
})

// 编辑相关
const editVisible = ref(false)
const editFormRef = ref<FormInstance>()
const editForm = reactive({
  id: 0,
  name: '',
  category: '',
  brand: '',
  price: 0,
  unit: '',
  low_stock_threshold: 0,
  remark: '',
  imageType: 'link',
  image_url: '',
  item_link: ''
})

const editRules: FormRules = {
  name: [{ required: true, message: '请输入物品名称', trigger: 'blur' }],
  category: [{ required: true, message: '请选择分类', trigger: 'change' }],
  unit: [{ required: true, message: '请输入单位', trigger: 'blur' }],
  price: [{ required: true, message: '请输入单价', trigger: 'blur' }],
  low_stock_threshold: [{ required: true, message: '请输入预警阈值', trigger: 'blur' }]
}

const handleSearch = () => {
  page.value = 1
  fetchData()
}

const handleReset = () => {
  searchForm.keyword = ''
  searchForm.category = ''
  searchForm.brand = ''
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

const handleInbound = () => {
  router.push('/inventory/in')
}

const handleOutbound = () => {
  router.push('/inventory/out')
}

const handleExport = () => {
  const exportData = tableData.value.map(item => ({
    '物品ID': item.id,
    '物品名称': item.name,
    '分类': item.category,
    '品牌': item.brand || '-',
    '库存量': item.quantity + ' ' + item.unit,
    '单价 (元)': item.price.toFixed(2),
    '总价 (元)': (item.price * item.quantity).toFixed(2),
    '预警阈值': item.low_stock_threshold,
    '备注': item.remark || '-'
  }))

  const worksheet = XLSX.utils.json_to_sheet(exportData)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, '库存列表')
  
  // Set column widths
  const wscols = [
    { wch: 10 }, // 物品ID
    { wch: 20 }, // 物品名称
    { wch: 12 }, // 分类
    { wch: 12 }, // 品牌
    { wch: 12 }, // 库存量
    { wch: 12 }, // 单价
    { wch: 12 }, // 总价
    { wch: 12 }, // 预警阈值
    { wch: 30 }  // 备注
  ]
  worksheet['!cols'] = wscols

  const fileName = `库存列表_${new Date().toLocaleDateString().replace(/\//g, '-')}.xlsx`
  XLSX.writeFile(workbook, fileName)
}

const handleEdit = (row: any) => {
  editForm.id = row.id
  editForm.name = row.name
  editForm.category = row.category
  editForm.brand = row.brand || ''
  editForm.price = row.price
  editForm.unit = row.unit
  editForm.low_stock_threshold = row.low_stock_threshold
  editForm.remark = row.remark || ''
  editForm.item_link = row.item_link || ''
  if (row.image_url) {
    editForm.imageType = 'link'
    editForm.image_url = row.image_url
  } else {
    editForm.imageType = 'link'
    editForm.image_url = ''
  }
  editVisible.value = true
}

const submitEdit = async () => {
  if (!editFormRef.value) return
  await editFormRef.value.validate((valid) => {
    if (valid) {
      inventoryStore.updateItem(editForm.id, {
        name: editForm.name,
        category: editForm.category,
        brand: editForm.brand,
        price: editForm.price,
        unit: editForm.unit,
        low_stock_threshold: editForm.low_stock_threshold,
        remark: editForm.remark,
        image_url: editForm.image_url,
        item_link: editForm.item_link
      })
      ElMessage.success('物品信息已更新')
      editVisible.value = false
    }
  })
}

const handleImageChange = async (file: any) => {
  if (file.raw) {
    const ext = file.raw.name.split('.').pop()?.toLowerCase() || ''
    const allowedExts = systemStore.settings.upload.allowed_extensions
    const maxSizeMB = systemStore.settings.upload.max_size_mb

    const isAllowedExt = allowedExts.includes(ext)
    const isLtMax = file.raw.size / 1024 / 1024 < maxSizeMB

    if (!isAllowedExt) {
      ElMessage.error(`上传图片只能是 ${allowedExts.join('/')} 格式!`)
      return false
    }
    if (!isLtMax) {
      ElMessage.error(`上传图片大小不能超过 ${maxSizeMB}MB!`)
      return false
    }
    
    // 打开裁剪组件
    imageCropperRef.value.open(file.raw)
  }
}

const handleCropSuccess = (res: any) => {
  editForm.image_url = res.url
  ElMessage.success('图片裁剪并上传成功')
}

const handleView = (row: any) => {
  currentItem.value = row
  detailVisible.value = true
}

const handleDelete = (row: any) => {
  ElMessageBox.confirm(
    `确定要删除物品 ${row.name} 吗？`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(() => {
    inventoryStore.deleteItem(row.id)
    ElMessage.success('删除成功')
  }).catch(() => {})
}


</script>

<template>
  <div class="h-full max-w-7xl mx-auto flex flex-col gap-6">
    <!-- 头部区域 -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] relative overflow-hidden group">
      <!-- 装饰性背景图形 -->
      <div class="absolute -right-10 -top-10 w-32 h-32 rounded-full opacity-5 bg-[#3B82F6] group-hover:opacity-10 group-hover:scale-110 transition-all duration-700 ease-out origin-top-right"></div>
      
      <div class="relative z-10">
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">库存管理</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">管理您的所有物品库存、入库与出库操作</p>
      </div>
      <div class="flex items-center gap-3 w-full sm:w-auto relative z-10">
        <el-button type="primary" :icon="Plus" @click="handleInbound" class="flex-1 sm:flex-none !rounded-xl !h-10 font-medium shadow-sm shadow-blue-500/20">入库</el-button>
        <el-button type="warning" :icon="Plus" @click="handleOutbound" class="flex-1 sm:flex-none !rounded-xl !h-10 font-medium shadow-sm shadow-orange-500/20">出库</el-button>
      </div>
    </div>

    <div class="bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] p-6">
      <el-form :model="searchForm" class="flex flex-wrap items-center gap-3 w-full" @submit.prevent="handleSearch">
        <el-form-item class="!mb-0 !mr-0">
          <el-input v-model="searchForm.keyword" placeholder="搜索物品名称/ID" :prefix-icon="Search" class="!w-60 !rounded-xl" clearable @clear="handleSearch" />
        </el-form-item>
        <el-form-item class="!mb-0 !mr-0">
          <el-select v-model="searchForm.category" placeholder="全部分类" clearable class="!w-40 !rounded-xl" @change="handleSearch">
            <el-option v-for="item in categories" :key="item.id" :label="item.name" :value="item.name" />
          </el-select>
        </el-form-item>
        <el-form-item class="!mb-0 !mr-0">
          <el-select v-model="searchForm.brand" placeholder="全部品牌" clearable class="!w-40 !rounded-xl" @change="handleSearch">
            <el-option v-for="item in brands" :key="item.id" :label="item.name" :value="item.name" />
          </el-select>
        </el-form-item>
        <el-form-item class="!mb-0 !mr-0 ml-auto">
          <div class="flex items-center gap-2">
            <el-button type="primary" @click="handleSearch" class="!rounded-xl !h-10 font-medium px-6">查询</el-button>
            <el-button @click="handleReset" class="!rounded-xl !h-10 font-medium hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent px-6">重置</el-button>
            <el-button type="success" :icon="Download" @click="handleExport" class="!rounded-xl !h-10 font-medium shadow-sm shadow-green-500/20 px-6">导出 Excel</el-button>
          </div>
        </el-form-item>
      </el-form>
    </div>

    <!-- 表格数据区 -->
    <div class="flex-1 flex flex-col bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] p-6 overflow-hidden">
      <el-table 
        :data="tableData" 
        v-loading="inventoryStore.loading"
        style="width: 100%; flex: 1;"
        height="100%"
        class="custom-table"
        :header-cell-style="{ background: 'var(--el-fill-color-light)', color: 'var(--text-main)', fontWeight: '600', height: '48px' }"
      >
        <el-table-column prop="id" label="ID" width="80" align="center">
          <template #default="{ row }">
            <span class="font-mono text-[var(--text-muted)] text-sm"><span class="text-[10px] opacity-60 mr-0.5">ID:</span>{{ row.id }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="物品名称" min-width="180" show-overflow-tooltip>
          <template #default="{ row }">
            <div class="font-bold text-[var(--text-main)]">{{ row.name }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="category" label="分类" width="130">
          <template #default="{ row }">
            <el-tag size="small" type="info" class="!rounded-md !border-none !bg-gray-100 dark:!bg-gray-800 dark:!text-gray-300">{{ row.category }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="brand" label="品牌" width="130">
          <template #default="{ row }">
            <span class="text-[var(--text-muted)]">{{ row.brand || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="price" label="单价 (元)" width="130" align="right">
          <template #default="{ row }">
            <span class="font-medium text-[var(--text-main)]">¥{{ row.price.toFixed(2) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="quantity" label="当前库存" width="140" align="right">
          <template #default="{ row }">
            <div class="flex items-center justify-end gap-2">
              <el-tag v-if="row.quantity < row.low_stock_threshold" type="danger" size="small" class="!rounded-md !border-none !bg-red-100 dark:!bg-red-900/30">预警</el-tag>
              <span class="font-bold" :class="row.quantity < row.low_stock_threshold ? 'text-red-500' : 'text-green-500'">
                {{ row.quantity }} <span class="text-xs font-normal opacity-70">{{ row.unit }}</span>
              </span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="总价值 (元)" width="150" align="right">
          <template #default="{ row }">
            <span class="font-bold text-blue-500">¥{{ (row.price * row.quantity).toFixed(2) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="updated_at" label="最后更新时间" width="180">
          <template #default="{ row }">
            <span class="text-[var(--text-muted)] text-sm">
              {{ row.updated_at ? new Date(row.updated_at.endsWith('Z') || row.updated_at.includes('+') ? row.updated_at : row.updated_at + 'Z').toLocaleString('zh-CN', { hour12: false }) : '-' }}
            </span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right" align="center">
          <template #default="scope">
            <div class="flex items-center justify-center gap-2">
              <el-tooltip content="详情" placement="top">
                <el-button circle size="small" :icon="View" @click="handleView(scope.row)" class="!bg-gray-100 hover:!bg-gray-200 dark:!bg-gray-800 dark:hover:!bg-gray-700 !border-transparent text-gray-600 dark:text-gray-300" />
              </el-tooltip>
              <el-tooltip content="编辑" placement="top">
                <el-button circle size="small" type="primary" :icon="Edit" @click="handleEdit(scope.row)" class="!bg-blue-50 hover:!bg-blue-100 dark:!bg-blue-900/30 dark:hover:!bg-blue-900/50 !border-transparent !text-blue-500" />
              </el-tooltip>
              <el-tooltip content="删除" placement="top">
                <el-button circle size="small" type="danger" :icon="Delete" @click="handleDelete(scope.row)" class="!bg-red-50 hover:!bg-red-100 dark:!bg-red-900/30 dark:hover:!bg-red-900/50 !border-transparent !text-red-500" />
              </el-tooltip>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <div class="p-4 flex justify-end border-t border-[var(--border-subtle)] bg-[var(--card-bg)]">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          background
          layout="total, sizes, prev, pager, next, jumper"
          :total="totalItems"
          :page-sizes="[10, 20, 50, 100]"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          class="custom-pagination"
        />
      </div>
    </div>

    <!-- 详情抽屉 -->
    <el-drawer
      v-model="detailVisible"
      title="物品详情"
      :size="appStore.isMobile ? '90%' : '440px'"
      destroy-on-close
      class="custom-drawer"
    >
      <div v-if="currentItem" class="flex flex-col gap-8">
        <!-- 物品图片 -->
        <div class="flex justify-center p-4 bg-[var(--page-bg)] rounded-2xl border border-[var(--border-subtle)]">
          <el-image
            v-if="currentItem.image_url"
            :src="currentItem.image_url"
            class="w-56 h-56 rounded-xl shadow-md object-cover border-4 border-white dark:border-gray-800"
            :preview-src-list="[currentItem.image_url]"
            fit="cover"
          />
          <div v-else class="w-56 h-56 bg-gray-100 dark:bg-gray-800 rounded-xl flex flex-col items-center justify-center text-gray-400 border border-dashed border-gray-300">
            <el-icon size="32" class="mb-2"><View /></el-icon>
            <span class="text-sm">暂无图片</span>
          </div>
        </div>

        <!-- 基本信息 -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 mb-2">
            <div class="w-1 h-4 bg-blue-500 rounded-full"></div>
            <h3 class="text-base font-bold text-[var(--text-main)]">基本信息</h3>
          </div>
          <el-descriptions :column="1" border size="default" class="custom-descriptions">
            <el-descriptions-item label="物品ID">
              <span class="font-mono text-gray-500"><span class="text-[10px] opacity-60 mr-0.5">ID:</span>{{ currentItem.id }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="物品名称">
              <span class="font-bold text-[var(--text-main)]">{{ currentItem.name }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="分类">
              <el-tag size="small" type="info" class="!rounded-md !border-none !bg-gray-100 dark:!bg-gray-800 dark:!text-gray-300">{{ currentItem.category }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="品牌">
              <span class="text-[var(--text-muted)]">{{ currentItem.brand || '-' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="物品链接">
              <el-link v-if="currentItem.item_link" :href="currentItem.item_link" target="_blank" type="primary" class="!text-sm">查看购买链接</el-link>
              <span v-else class="text-gray-400">-</span>
            </el-descriptions-item>
            <el-descriptions-item label="单价">
              <span class="text-lg font-bold text-orange-500">¥{{ currentItem.price.toFixed(2) }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="当前库存">
              <div class="flex items-center gap-2">
                <span class="font-bold text-lg" :class="currentItem.quantity < currentItem.low_stock_threshold ? 'text-red-500' : 'text-green-500'">
                  {{ currentItem.quantity }} <span class="text-sm font-normal text-gray-400">{{ currentItem.unit }}</span>
                </span>
                <el-tag v-if="currentItem.quantity < currentItem.low_stock_threshold" type="danger" size="small" class="!rounded-md">库存预警</el-tag>
              </div>
            </el-descriptions-item>
            <el-descriptions-item label="预警阈值">
              <span class="text-gray-600 dark:text-gray-400">{{ currentItem.low_stock_threshold }} {{ currentItem.unit }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="备注">
              <span class="text-gray-500 italic">{{ currentItem.remark || '无备注信息' }}</span>
            </el-descriptions-item>
          </el-descriptions>
        </div>

        <!-- 历史记录 -->
        <div class="space-y-4">
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-2">
              <div class="w-1 h-4 bg-purple-500 rounded-full"></div>
              <h3 class="text-base font-bold text-[var(--text-main)]">近期流转记录</h3>
            </div>
            <span class="text-xs text-[var(--text-muted)]">显示最近5条</span>
          </div>
          <div class="bg-[var(--page-bg)] p-4 rounded-2xl border border-[var(--border-subtle)]">
            <el-timeline class="!pl-1">
              <el-timeline-item
                v-for="record in itemRecords.slice(0, 5)"
                :key="record.id"
                :type="record.type === 'in' ? 'success' : 'warning'"
                placement="top"
              >
                <template #default>
                  <div class="flex flex-col gap-1.5">
                    <span class="text-[11px] text-[var(--text-muted)] font-mono opacity-80 leading-none">{{ formatToUTC8(record.time) }}</span>
                    <div class="flex items-center justify-between bg-[var(--card-bg)] p-3 rounded-xl border border-[var(--border-subtle)] shadow-sm group/item hover:border-blue-500/30 transition-all duration-300">
                      <div class="flex items-center gap-2.5">
                        <div :class="record.type === 'in' ? 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400' : 'bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400'" class="p-1.5 rounded-lg transition-colors duration-300">
                          <el-icon size="14"><Plus v-if="record.type === 'in'" /><Minus v-else /></el-icon>
                        </div>
                        <div class="flex flex-col">
                          <span class="font-bold text-sm text-[var(--text-main)]">{{ record.type === 'in' ? '入库' : '出库' }}</span>
                          <span class="text-[10px] text-[var(--text-muted)] truncate max-w-[100px]">{{ record.operator }}</span>
                        </div>
                      </div>
                      <span :class="record.type === 'in' ? 'text-green-500' : 'text-orange-500'" class="font-bold font-mono text-base">
                        {{ record.type === 'in' ? '+' : '-' }}{{ record.quantity }}
                      </span>
                    </div>
                  </div>
                </template>
              </el-timeline-item>
              <el-timeline-item v-if="itemRecords.length === 0" hide-timestamp>
                <div class="text-gray-400 text-center py-4 italic">暂无流转记录</div>
              </el-timeline-item>
            </el-timeline>
          </div>
        </div>
      </div>
    </el-drawer>

    <!-- 编辑弹窗 -->
    <el-dialog v-model="editVisible" title="编辑物品信息" :width="appStore.isMobile ? '90%' : '500px'" destroy-on-close class="!rounded-2xl">
      <el-form ref="editFormRef" :model="editForm" :rules="editRules" label-width="90px" :label-position="appStore.isMobile ? 'top' : 'left'">
        <el-form-item label="物品名称" prop="name" class="font-medium">
          <el-input v-model="editForm.name" placeholder="请输入物品名称" class="!rounded-xl" />
        </el-form-item>
        <el-form-item label="分类" prop="category" class="font-medium">
          <el-select v-model="editForm.category" placeholder="请选择分类" class="w-full !rounded-xl">
            <el-option v-for="c in categories" :key="c.id" :label="c.name" :value="c.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="品牌" prop="brand" class="font-medium">
          <el-select v-model="editForm.brand" placeholder="请选择品牌(可选)" clearable class="w-full !rounded-xl">
            <el-option v-for="b in brands" :key="b.id" :label="b.name" :value="b.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="单价" prop="price" class="font-medium">
          <el-input-number v-model="editForm.price" :min="0" :precision="2" :step="0.1" class="w-full !rounded-xl" />
        </el-form-item>
        <el-form-item label="计量单位" prop="unit" class="font-medium">
          <el-input v-model="editForm.unit" placeholder="如：个、台、箱" class="!rounded-xl" />
        </el-form-item>
        <el-form-item label="预警阈值" prop="low_stock_threshold" class="font-medium">
          <el-input-number v-model="editForm.low_stock_threshold" :min="0" :step="1" class="w-full !rounded-xl" />
        </el-form-item>
        <el-form-item label="物品链接" prop="item_link" class="font-medium">
          <el-input v-model="editForm.item_link" placeholder="请输入物品购买或参考链接(可选)" class="!rounded-xl" />
        </el-form-item>
        <el-form-item label="物品图片" class="font-medium">
          <div class="flex flex-col gap-2 w-full">
            <el-radio-group v-model="editForm.imageType" size="small" @change="editForm.image_url = ''" class="!rounded-xl">
              <el-radio-button label="link">图片链接</el-radio-button>
              <el-radio-button label="file">本地上传</el-radio-button>
            </el-radio-group>
            
            <el-input 
              v-if="editForm.imageType === 'link'" 
              v-model="editForm.image_url" 
              placeholder="请输入图片URL链接" 
              class="!rounded-xl"
            />
            
            <div v-else class="flex flex-col gap-1">
              <el-upload
                class="avatar-uploader"
                action="#"
                :show-file-list="false"
                :auto-upload="false"
                :on-change="handleImageChange"
              >
                <div v-if="editForm.image_url" class="w-32 h-32 border border-[var(--border-subtle)] rounded-xl overflow-hidden shadow-sm">
                  <img :src="editForm.image_url" class="w-full h-full object-cover" />
                </div>
                <div v-else class="w-32 h-32 border border-dashed border-[var(--border-subtle)] rounded-xl flex items-center justify-center cursor-pointer hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-all">
                    <el-icon class="text-2xl text-gray-400"><Plus /></el-icon>
                </div>
              </el-upload>
              <div class="text-xs text-[var(--text-muted)]">支持 {{ systemStore.settings.upload.allowed_extensions.join('/') }} 格式，不超过 {{ systemStore.settings.upload.max_size_mb }}MB</div>
            </div>
          </div>
        </el-form-item>
        <el-form-item label="备注" prop="remark" class="font-medium">
          <el-input v-model="editForm.remark" type="textarea" placeholder="请输入备注信息(可选)" class="!rounded-xl" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="flex justify-end gap-3 pt-4 border-t border-[var(--border-subtle)]">
          <el-button @click="editVisible = false" class="!rounded-xl !h-10 font-medium hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">取消</el-button>
          <el-button type="primary" @click="submitEdit" class="!rounded-xl !h-10 font-medium shadow-sm shadow-blue-500/20">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 图片裁剪组件 -->
    <ImageCropper
      ref="imageCropperRef"
      upload-url="/upload/"
      method="POST"
      title="裁剪物品图片"
      :aspect-ratio="[1, 1]"
      @success="handleCropSuccess"
    />
  </div>
</template>
