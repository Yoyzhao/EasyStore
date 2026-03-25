<script setup lang="ts">
import { reactive, computed, ref, onMounted } from 'vue'
import { Search, Plus, Edit, Delete, View, Download } from '@element-plus/icons-vue'
import { useRouter } from 'vue-router'
import { useInventoryStore } from '@/store/inventory'
import { useMetadataStore } from '@/store/metadata'
import { useSystemStore } from '@/store/system'
import { useUserStore } from '@/store/user'
import { storeToRefs } from 'pinia'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import * as XLSX from 'xlsx'

import { uploadFile } from '@/api/request'

const router = useRouter()
const inventoryStore = useInventoryStore()
const metadataStore = useMetadataStore()
const systemStore = useSystemStore()
const userStore = useUserStore()

const { categories, brands } = storeToRefs(metadataStore)
const { totalItems } = storeToRefs(inventoryStore)

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
  inventoryStore.fetchItems(searchForm.keyword, searchForm.category, (page.value - 1) * pageSize.value, pageSize.value)
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
    '规格': item.specification || '-',
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
    { wch: 15 }, // 规格
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
    
    try {
      const url = await uploadFile(file.raw)
      editForm.image_url = url
    } catch (e) {
      ElMessage.error('图片上传失败')
    }
  }
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
  <div class="h-full flex flex-col gap-4">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">库存列表</h1>
      <div class="space-x-2">
        <el-button type="primary" :icon="Plus" @click="handleInbound">入库</el-button>
        <el-button type="warning" :icon="Plus" @click="handleOutbound">出库</el-button>
      </div>
    </div>

    <el-card shadow="hover" class="border-none" style="background-color: var(--el-bg-color-overlay);">
      <el-form :model="searchForm" label-width="60px">
        <el-row :gutter="20">
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="关键词" class="!mb-4 lg:!mb-0">
              <el-input v-model="searchForm.keyword" placeholder="物品名称/ID" :prefix-icon="Search" class="w-full" clearable />
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="分类" class="!mb-4 lg:!mb-0">
              <el-select v-model="searchForm.category" placeholder="全部分类" clearable class="w-full">
                <el-option v-for="item in categories" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8" :lg="6">
            <el-form-item label="品牌" class="!mb-4 lg:!mb-0">
              <el-select v-model="searchForm.brand" placeholder="全部品牌" clearable class="w-full">
                <el-option v-for="item in brands" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :xs="24" :sm="12" :md="24" :lg="6" class="flex justify-end items-center gap-2">
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
            <el-button type="success" :icon="Download" @click="handleExport">导出 Excel</el-button>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="hover" class="flex-1 flex flex-col border-none" style="background-color: var(--el-bg-color-overlay);" :body-style="{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }">
      <el-table :data="tableData" stripe style="width: 100%; flex: 1;" height="100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="物品名称" min-width="150" show-overflow-tooltip />
        <el-table-column prop="category" label="分类" width="120" />
        <el-table-column prop="brand" label="品牌" width="120" />
        <el-table-column prop="price" label="单价 (元)" width="120" align="right">
          <template #default="{ row }">
            ¥{{ row.price.toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column prop="quantity" label="当前库存" width="120" align="right">
          <template #default="{ row }">
            <span :class="{'text-red-500 font-bold': row.quantity < row.low_stock_threshold}">
              {{ row.quantity }} {{ row.unit }}
              <el-tag v-if="row.quantity < row.low_stock_threshold" type="danger" size="small" effect="plain" class="ml-1">预警</el-tag>
            </span>
          </template>
        </el-table-column>
        <el-table-column label="总价值 (元)" width="140" align="right">
          <template #default="{ row }">
            ¥{{ (row.price * row.quantity).toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column prop="updated_at" label="最后更新时间" width="180">
          <template #default="{ row }">
            {{ row.updated_at ? new Date(row.updated_at.endsWith('Z') || row.updated_at.includes('+') ? row.updated_at : row.updated_at + 'Z').toLocaleString('zh-CN', { hour12: false }) : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="260" fixed="right">
          <template #default="scope">
            <el-button size="small" :icon="View" @click="handleView(scope.row)">详情</el-button>
            <el-button size="small" type="primary" :icon="Edit" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button size="small" type="danger" :icon="Delete" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pt-4 mt-4 flex justify-end border-t" style="border-color: var(--el-border-color-lighter);">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          background
          layout="total, sizes, prev, pager, next, jumper"
          :total="totalItems"
          :page-sizes="[10, 20, 50, 100]"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 详情抽屉 -->
    <el-drawer
      v-model="detailVisible"
      title="物品详情"
      size="400px"
      destroy-on-close
    >
      <div v-if="currentItem" class="flex flex-col gap-6">
        <!-- 物品图片 -->
        <div class="flex justify-center">
          <el-image
            v-if="currentItem.image_url"
            :src="currentItem.image_url"
            class="w-48 h-48 rounded-lg shadow-sm object-cover"
            :preview-src-list="[currentItem.image_url]"
            fit="cover"
          />
          <div v-else class="w-48 h-48 bg-gray-100 dark:bg-gray-800 rounded-lg flex items-center justify-center text-gray-400">
            暂无图片
          </div>
        </div>

        <!-- 基本信息 -->
        <el-descriptions title="基本信息" :column="1" border size="small">
          <el-descriptions-item label="物品ID">{{ currentItem.id }}</el-descriptions-item>
          <el-descriptions-item label="物品名称">{{ currentItem.name }}</el-descriptions-item>
          <el-descriptions-item label="分类">{{ currentItem.category }}</el-descriptions-item>
          <el-descriptions-item label="品牌">{{ currentItem.brand || '-' }}</el-descriptions-item>
          <el-descriptions-item label="物品链接">
            <a v-if="currentItem.item_link" :href="currentItem.item_link" target="_blank" class="text-blue-500 hover:underline">{{ currentItem.item_link }}</a>
            <span v-else>-</span>
          </el-descriptions-item>
          <el-descriptions-item label="单价">¥{{ currentItem.price.toFixed(2) }}</el-descriptions-item>
          <el-descriptions-item label="当前库存">
            <span :class="{'text-red-500 font-bold': currentItem.quantity < currentItem.low_stock_threshold}">
              {{ currentItem.quantity }} {{ currentItem.unit }}
            </span>
          </el-descriptions-item>
          <el-descriptions-item label="预警阈值">{{ currentItem.low_stock_threshold }} {{ currentItem.unit }}</el-descriptions-item>
          <el-descriptions-item label="备注">{{ currentItem.remark || '无' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 历史记录 -->
        <div>
          <h3 class="text-base font-bold text-gray-800 dark:text-gray-100 mb-3">近期流转记录</h3>
          <el-timeline>
            <el-timeline-item
              v-for="record in itemRecords.slice(0, 5)"
              :key="record.id"
              :type="record.type === 'in' ? 'success' : 'warning'"
              :timestamp="record.time"
              placement="top"
            >
              <div class="flex justify-between items-center">
                <span class="font-medium text-gray-700 dark:text-gray-300">
                  {{ record.type === 'in' ? '入库' : '出库' }}
                </span>
                <span :class="record.type === 'in' ? 'text-green-500' : 'text-orange-500'" class="font-bold">
                  {{ record.type === 'in' ? '+' : '-' }}{{ record.quantity }} {{ currentItem.unit }}
                </span>
              </div>
            </el-timeline-item>
            <el-timeline-item v-if="itemRecords.length === 0" hide-timestamp>
              <span class="text-gray-400">暂无记录</span>
            </el-timeline-item>
          </el-timeline>
        </div>
      </div>
    </el-drawer>

    <!-- 编辑弹窗 -->
    <el-dialog v-model="editVisible" title="编辑物品信息" width="500px" destroy-on-close>
      <el-form ref="editFormRef" :model="editForm" :rules="editRules" label-width="90px">
        <el-form-item label="物品名称" prop="name">
          <el-input v-model="editForm.name" placeholder="请输入物品名称" />
        </el-form-item>
        <el-form-item label="分类" prop="category">
          <el-select v-model="editForm.category" placeholder="请选择分类" class="w-full">
            <el-option v-for="c in categories" :key="c.id" :label="c.name" :value="c.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="品牌" prop="brand">
          <el-select v-model="editForm.brand" placeholder="请选择品牌(可选)" clearable class="w-full">
            <el-option v-for="b in brands" :key="b.id" :label="b.name" :value="b.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="单价" prop="price">
          <el-input-number v-model="editForm.price" :min="0" :precision="2" :step="0.1" class="w-full" />
        </el-form-item>
        <el-form-item label="计量单位" prop="unit">
          <el-input v-model="editForm.unit" placeholder="如：个、台、箱" />
        </el-form-item>
        <el-form-item label="预警阈值" prop="low_stock_threshold">
          <el-input-number v-model="editForm.low_stock_threshold" :min="0" :step="1" class="w-full" />
        </el-form-item>
        <el-form-item label="物品链接" prop="item_link">
          <el-input v-model="editForm.item_link" placeholder="请输入物品购买或参考链接(可选)" />
        </el-form-item>
        <el-form-item label="物品图片">
          <div class="flex flex-col gap-2 w-full">
            <el-radio-group v-model="editForm.imageType" size="small" @change="editForm.image_url = ''">
              <el-radio-button label="link">图片链接</el-radio-button>
              <el-radio-button label="file">本地上传</el-radio-button>
            </el-radio-group>
            
            <el-input 
              v-if="editForm.imageType === 'link'" 
              v-model="editForm.image_url" 
              placeholder="请输入图片URL链接" 
            />
            
            <div v-else class="flex flex-col gap-1">
              <el-upload
                class="avatar-uploader"
                action="#"
                :show-file-list="false"
                :auto-upload="false"
                :on-change="handleImageChange"
              >
                <div v-if="editForm.image_url" class="w-32 h-32 border border-gray-300 rounded overflow-hidden">
                  <img :src="editForm.image_url" class="w-full h-full object-cover" />
                </div>
                <div v-else class="w-32 h-32 border border-dashed border-gray-300 rounded flex items-center justify-center cursor-pointer hover:border-blue-500 transition-colors">
                    <el-icon class="text-2xl text-gray-400"><Plus /></el-icon>
                </div>
              </el-upload>
              <div class="text-xs text-gray-500">支持 {{ systemStore.settings.upload.allowed_extensions.join('/') }} 格式，不超过 {{ systemStore.settings.upload.max_size_mb }}MB</div>
            </div>
          </div>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="editForm.remark" type="textarea" placeholder="请输入备注信息(可选)" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="editVisible = false">取消</el-button>
          <el-button type="primary" @click="submitEdit">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>
