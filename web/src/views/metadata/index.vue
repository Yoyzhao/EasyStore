<script setup lang="ts">
import { ref } from 'vue'
import { Plus, Delete, Edit } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useMetadataStore } from '@/store/metadata'
import { storeToRefs } from 'pinia'

const activeTab = ref('category')
const metadataStore = useMetadataStore()

const { categories, brands, units, usages } = storeToRefs(metadataStore)

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
    .then(() => {
      metadataStore.deleteMetadata(type, row.id)
      ElMessage({
        type: 'success',
        message: '删除成功',
      })
    })
    .catch(() => {})
}

const handleSubmit = () => {
  if (!form.value.name) {
    ElMessage.warning('名称不能为空')
    return
  }
  
  const newItem = { 
    id: form.value.id || Date.now(), 
    name: form.value.name, 
    description: form.value.description 
  }

  if (form.value.id) {
    metadataStore.updateMetadata(editingType.value, newItem)
  } else {
    metadataStore.addMetadata(editingType.value, newItem)
  }

  dialogVisible.value = false
  ElMessage.success('操作成功')
}

</script>

<template>
  <div class="h-full flex flex-col gap-4">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">元数据管理</h1>
    </div>

    <el-card shadow="hover" class="flex-1 flex flex-col border-none" style="background-color: var(--el-bg-color-overlay);" :body-style="{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }">
      <el-tabs v-model="activeTab" class="flex-1 flex flex-col h-full">
        <!-- 分类管理 -->
        <el-tab-pane label="物品分类" name="category" class="h-full overflow-auto">
          <div class="mb-4">
            <el-button type="primary" :icon="Plus" @click="handleAdd('category')">新增分类</el-button>
          </div>
          <el-table :data="categories" stripe style="width: 100%">
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="name" label="分类名称" width="180" />
            <el-table-column prop="description" label="描述" />
            <el-table-column label="操作" width="180" align="right">
              <template #default="scope">
                <el-button size="small" :icon="Edit" @click="handleEdit('category', scope.row)">编辑</el-button>
                <el-button size="small" type="danger" :icon="Delete" @click="handleDelete('category', scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 品牌管理 -->
        <el-tab-pane label="物品品牌" name="brand" class="h-full overflow-auto">
          <div class="mb-4">
            <el-button type="primary" :icon="Plus" @click="handleAdd('brand')">新增品牌</el-button>
          </div>
          <el-table :data="brands" stripe style="width: 100%">
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="name" label="品牌名称" width="180" />
            <el-table-column prop="description" label="描述" />
            <el-table-column label="操作" width="180" align="right">
              <template #default="scope">
                <el-button size="small" :icon="Edit" @click="handleEdit('brand', scope.row)">编辑</el-button>
                <el-button size="small" type="danger" :icon="Delete" @click="handleDelete('brand', scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 单位管理 -->
        <el-tab-pane label="单位管理" name="unit" class="h-full overflow-auto">
          <div class="mb-4">
            <el-button type="primary" :icon="Plus" @click="handleAdd('unit')">新增单位</el-button>
          </div>
          <el-table :data="units" stripe style="width: 100%">
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="name" label="单位名称" width="180" />
            <el-table-column label="操作" width="180" align="right">
              <template #default="scope">
                <el-button size="small" :icon="Edit" @click="handleEdit('unit', scope.row)">编辑</el-button>
                <el-button size="small" type="danger" :icon="Delete" @click="handleDelete('unit', scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 用途管理 -->
        <el-tab-pane label="用途/去向" name="usage" class="h-full overflow-auto">
          <div class="mb-4">
            <el-button type="primary" :icon="Plus" @click="handleAdd('usage')">新增用途/去向</el-button>
          </div>
          <el-table :data="usages" stripe style="width: 100%">
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="name" label="名称" width="180" />
            <el-table-column prop="description" label="描述" />
            <el-table-column label="操作" width="180" align="right">
              <template #default="scope">
                <el-button size="small" :icon="Edit" @click="handleEdit('usage', scope.row)">编辑</el-button>
                <el-button size="small" type="danger" :icon="Delete" @click="handleDelete('usage', scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- Dialog -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="名称" required>
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="描述" v-if="editingType !== 'unit'">
          <el-input v-model="form.description" type="textarea" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
:deep(.el-tabs__content) {
  flex: 1;
  overflow: hidden;
}
</style>