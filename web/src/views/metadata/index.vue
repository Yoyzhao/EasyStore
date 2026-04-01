<script setup lang="ts">
import { ref, onMounted, computed, reactive } from 'vue'
import { Plus, Delete, Edit, Search } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useMetadataStore } from '@/store/metadata'
import { storeToRefs } from 'pinia'

const activeTab = ref('category')
const metadataStore = useMetadataStore()

const searchForm = reactive({
  keyword: ''
})

const page = ref(1)
const pageSize = ref(10)

onMounted(() => {
  metadataStore.fetchMetadata()
})

const { categories, brands, units, usages } = storeToRefs(metadataStore)

const currentData = computed(() => {
  let data: any[] = []
  if (activeTab.value === 'category') data = categories.value
  else if (activeTab.value === 'brand') data = brands.value
  else if (activeTab.value === 'unit') data = units.value
  else if (activeTab.value === 'usage') data = usages.value
  
  if (searchForm.keyword) {
    const kw = searchForm.keyword.toLowerCase()
    data = data.filter(item => 
      item.name.toLowerCase().includes(kw) || 
      (item.description && item.description.toLowerCase().includes(kw))
    )
  }
  return data
})

const tableData = computed(() => {
  const start = (page.value - 1) * pageSize.value
  const end = start + pageSize.value
  return currentData.value.slice(start, end)
})

const handleSearch = () => {
  page.value = 1
}

const handleReset = () => {
  searchForm.keyword = ''
  page.value = 1
}

const handleSizeChange = (val: number) => {
  pageSize.value = val
  page.value = 1
}

const handleCurrentChange = (val: number) => {
  page.value = val
}

const handleTabChange = () => {
  page.value = 1
  searchForm.keyword = ''
}

// Dialog control
const dialogVisible = ref(false)
const dialogTitle = ref('')
const form = ref({
  id: 0,
  name: '',
  description: ''
})
const editingType = ref('') // 'category', 'brand', 'unit', 'usage'

const handleAdd = (type: string) => {
  editingType.value = type
  dialogTitle.value = type === 'category' ? '新增分类' : (type === 'brand' ? '新增品牌' : (type === 'unit' ? '新增单位' : '新增用途/去向'))
  form.value = { id: 0, name: '', description: '' }
  dialogVisible.value = true
}

const handleEdit = (type: string, row: any) => {
  editingType.value = type
  dialogTitle.value = type === 'category' ? '编辑分类' : (type === 'brand' ? '编辑品牌' : (type === 'unit' ? '编辑单位' : '编辑用途/去向'))
  form.value = { ...row }
  dialogVisible.value = true
}

const handleDelete = (type: string, row: any) => {
  const typeName = type === 'category' ? '分类' : (type === 'brand' ? '品牌' : (type === 'unit' ? '单位' : '用途/去向'))
  ElMessageBox.confirm(
    `确定要删除该${typeName}吗？`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  )
    .then(async () => {
      await metadataStore.deleteMetadata(type, row.id)
      ElMessage({
        type: 'success',
        message: '删除成功',
      })
    })
    .catch(() => {})
}

const handleSubmit = async () => {
  if (!form.value.name) {
    ElMessage.warning('名称不能为空')
    return
  }
  
  const newItem: any = { 
    name: form.value.name, 
    description: form.value.description 
  }
  
  if (form.value.id) {
    newItem.id = form.value.id
    await metadataStore.updateMetadata(editingType.value, newItem)
  } else {
    await metadataStore.addMetadata(editingType.value, newItem)
  }

  dialogVisible.value = false
  ElMessage.success('操作成功')
}

</script>

<template>
  <div class="h-full max-w-7xl mx-auto flex flex-col gap-6">
    <!-- 头部区域 -->
    <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 relative overflow-hidden group">
      <!-- 装饰圆圈 -->
      <div class="absolute -right-10 -top-10 w-32 h-32 rounded-full opacity-5 bg-[#3B82F6] group-hover:opacity-10 group-hover:scale-110 transition-all duration-700 ease-out origin-top-right"></div>
      
      <div class="relative z-10">
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">元数据管理</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">管理系统中的分类、品牌、单位及用途等基础数据</p>
      </div>
    </div>

    <div class="bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] p-6">
      <el-form :model="searchForm" class="flex flex-wrap items-center gap-3 w-full" @submit.prevent="handleSearch">
        <el-form-item class="!mb-0 !mr-0">
          <el-input v-model="searchForm.keyword" placeholder="搜索名称/描述" :prefix-icon="Search" class="!w-60 !rounded-xl" clearable @clear="handleSearch" />
        </el-form-item>
        <el-form-item class="!mb-0 !mr-0 ml-auto">
          <div class="flex items-center gap-2">
            <el-button type="primary" @click="handleSearch" class="!rounded-xl !h-10 font-medium px-6">查询</el-button>
            <el-button @click="handleReset" class="!rounded-xl !h-10 font-medium hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent px-6">重置</el-button>
            <el-button type="success" :icon="Plus" @click="handleAdd(activeTab)" class="!rounded-xl !h-10 font-medium shadow-sm shadow-green-500/20 px-6">新增</el-button>
          </div>
        </el-form-item>
      </el-form>
    </div>

    <div class="flex-1 bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col min-h-0">
      <el-tabs v-model="activeTab" class="flex-1 flex flex-col h-full custom-tabs" @tab-change="handleTabChange">
        <!-- 分类管理 -->
        <el-tab-pane label="物品分类" name="category" class="h-full overflow-auto flex flex-col">
          <el-table :data="tableData" style="width: 100%; flex: 1" class="custom-table" :header-cell-style="{ background: 'var(--el-fill-color-light)', color: 'var(--text-main)', fontWeight: '600', height: '48px' }">
            <el-table-column prop="id" label="ID" width="80">
              <template #default="{ row }">
                <span class="font-mono text-[var(--text-muted)] text-sm"><span class="text-[10px] opacity-60 mr-0.5">ID:</span>{{ row.id }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="名称" width="180">
              <template #default="{ row }">
                <span class="font-medium text-[var(--text-main)]">{{ row.name }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="描述">
              <template #default="{ row }">
                <span class="text-[var(--text-muted)]">{{ row.description || '-' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100" align="right">
              <template #default="scope">
                <div class="flex items-center justify-end gap-2">
                  <el-tooltip content="编辑" placement="top">
                    <el-button circle size="small" type="primary" :icon="Edit" @click="handleEdit('category', scope.row)" class="!bg-blue-50 hover:!bg-blue-100 dark:!bg-blue-900/30 dark:hover:!bg-blue-900/50 !border-transparent !text-blue-500" />
                  </el-tooltip>
                  <el-tooltip content="删除" placement="top">
                    <el-button circle size="small" type="danger" :icon="Delete" @click="handleDelete('category', scope.row)" class="!bg-red-50 hover:!bg-red-100 dark:!bg-red-900/30 dark:hover:!bg-red-900/50 !border-transparent !text-red-500" />
                  </el-tooltip>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 品牌管理 -->
        <el-tab-pane label="物品品牌" name="brand" class="h-full overflow-auto flex flex-col">
          <el-table :data="tableData" style="width: 100%; flex: 1" class="custom-table" :header-cell-style="{ background: 'var(--el-fill-color-light)', color: 'var(--text-main)', fontWeight: '600', height: '48px' }">
            <el-table-column prop="id" label="ID" width="80">
              <template #default="{ row }">
                <span class="font-mono text-[var(--text-muted)] text-sm"><span class="text-[10px] opacity-60 mr-0.5">ID:</span>{{ row.id }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="名称" width="180">
              <template #default="{ row }">
                <span class="font-medium text-[var(--text-main)]">{{ row.name }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="描述">
              <template #default="{ row }">
                <span class="text-[var(--text-muted)]">{{ row.description || '-' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100" align="right">
              <template #default="scope">
                <div class="flex items-center justify-end gap-2">
                  <el-tooltip content="编辑" placement="top">
                    <el-button circle size="small" type="primary" :icon="Edit" @click="handleEdit('brand', scope.row)" class="!bg-blue-50 hover:!bg-blue-100 dark:!bg-blue-900/30 dark:hover:!bg-blue-900/50 !border-transparent !text-blue-500" />
                  </el-tooltip>
                  <el-tooltip content="删除" placement="top">
                    <el-button circle size="small" type="danger" :icon="Delete" @click="handleDelete('brand', scope.row)" class="!bg-red-50 hover:!bg-red-100 dark:!bg-red-900/30 dark:hover:!bg-red-900/50 !border-transparent !text-red-500" />
                  </el-tooltip>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 单位管理 -->
        <el-tab-pane label="单位管理" name="unit" class="h-full overflow-auto flex flex-col">
          <el-table :data="tableData" style="width: 100%; flex: 1" class="custom-table" :header-cell-style="{ background: 'var(--el-fill-color-light)', color: 'var(--text-main)', fontWeight: '600', height: '48px' }">
            <el-table-column prop="id" label="ID" width="80">
              <template #default="{ row }">
                <span class="font-mono text-[var(--text-muted)] text-sm"><span class="text-[10px] opacity-60 mr-0.5">ID:</span>{{ row.id }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="名称" width="180">
              <template #default="{ row }">
                <span class="font-medium text-[var(--text-main)]">{{ row.name }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="描述">
              <template #default="{ row }">
                <span class="text-[var(--text-muted)]">{{ row.description || '-' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100" align="right">
              <template #default="scope">
                <div class="flex items-center justify-end gap-2">
                  <el-tooltip content="编辑" placement="top">
                    <el-button circle size="small" type="primary" :icon="Edit" @click="handleEdit('unit', scope.row)" class="!bg-blue-50 hover:!bg-blue-100 dark:!bg-blue-900/30 dark:hover:!bg-blue-900/50 !border-transparent !text-blue-500" />
                  </el-tooltip>
                  <el-tooltip content="删除" placement="top">
                    <el-button circle size="small" type="danger" :icon="Delete" @click="handleDelete('unit', scope.row)" class="!bg-red-50 hover:!bg-red-100 dark:!bg-red-900/30 dark:hover:!bg-red-900/50 !border-transparent !text-red-500" />
                  </el-tooltip>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 用途管理 -->
        <el-tab-pane label="用途/去向" name="usage" class="h-full overflow-auto flex flex-col">
          <el-table :data="tableData" style="width: 100%; flex: 1" class="custom-table" :header-cell-style="{ background: 'var(--el-fill-color-light)', color: 'var(--text-main)', fontWeight: '600', height: '48px' }">
            <el-table-column prop="id" label="ID" width="80">
              <template #default="{ row }">
                <span class="font-mono text-[var(--text-muted)] text-sm"><span class="text-[10px] opacity-60 mr-0.5">ID:</span>{{ row.id }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="名称" width="180">
              <template #default="{ row }">
                <span class="font-medium text-[var(--text-main)]">{{ row.name }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="描述">
              <template #default="{ row }">
                <span class="text-[var(--text-muted)]">{{ row.description || '-' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100" align="right">
              <template #default="scope">
                <div class="flex items-center justify-end gap-2">
                  <el-tooltip content="编辑" placement="top">
                    <el-button circle size="small" type="primary" :icon="Edit" @click="handleEdit('usage', scope.row)" class="!bg-blue-50 hover:!bg-blue-100 dark:!bg-blue-900/30 dark:hover:!bg-blue-900/50 !border-transparent !text-blue-500" />
                  </el-tooltip>
                  <el-tooltip content="删除" placement="top">
                    <el-button circle size="small" type="danger" :icon="Delete" @click="handleDelete('usage', scope.row)" class="!bg-red-50 hover:!bg-red-100 dark:!bg-red-900/30 dark:hover:!bg-red-900/50 !border-transparent !text-red-500" />
                  </el-tooltip>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>

      <div class="p-4 flex justify-end border-t border-[var(--border-subtle)] bg-[var(--card-bg)]">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          background
          layout="total, sizes, prev, pager, next, jumper"
          :total="currentData.length"
          :page-sizes="[10, 20, 50, 100]"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          class="custom-pagination"
        />
      </div>
    </div>

    <!-- Dialog -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" class="!rounded-2xl custom-dialog">
      <el-form :model="form" label-width="80px" class="mt-4">
        <el-form-item label="名称" required class="font-medium">
          <el-input v-model="form.name" class="!rounded-xl" />
        </el-form-item>
        <el-form-item label="描述" class="font-medium">
          <el-input v-model="form.description" type="textarea" rows="3" class="!rounded-xl" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false" class="!rounded-xl font-medium px-6 hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">取消</el-button>
          <el-button type="primary" @click="handleSubmit" class="!rounded-xl font-medium px-6 shadow-sm shadow-blue-500/20">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
:deep(.el-tabs__content) {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
:deep(.custom-tabs .el-tabs__nav-wrap::after) {
  height: 1px;
  background-color: var(--border-subtle);
}
:deep(.custom-tabs .el-tabs__item) {
  font-size: 15px;
  font-weight: 500;
  color: var(--text-muted);
}
:deep(.custom-tabs .el-tabs__item.is-active) {
  color: var(--el-color-primary);
  font-weight: 600;
}
:deep(.custom-dialog .el-dialog__header) {
  margin-right: 0;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border-subtle);
}
:deep(.custom-dialog .el-dialog__title) {
  font-weight: 600;
  font-size: 18px;
}
</style>