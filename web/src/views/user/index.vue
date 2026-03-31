<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUsersStore } from '@/store/users'
import { useAppStore } from '@/store/app'

const usersStore = useUsersStore()
const appStore = useAppStore()

const page = ref(1)
const pageSize = ref(10)

const tableData = computed(() => {
  const start = (page.value - 1) * pageSize.value
  const end = start + pageSize.value
  return usersStore.users.slice(start, end)
})

const handleSizeChange = (val: number) => {
  pageSize.value = val
  page.value = 1
}

const handleCurrentChange = (val: number) => {
  page.value = val
}

const formatDate = (dateStr: string) => {
  if (!dateStr) return ''
  // Append Z to indicate UTC time if not present, so the browser parses it correctly and converts to local time
  const dStr = dateStr.endsWith('Z') || dateStr.includes('+') ? dateStr : dateStr + 'Z'
  const date = new Date(dStr)
  return date.toLocaleString('zh-CN', { hour12: false })
}

onMounted(() => {
  usersStore.fetchUsers()
})

const dialogVisible = ref(false)
const dialogTitle = ref('新增用户')
const formRef = ref()

const form = reactive({
  id: '',
  username: '',
  password: '', // In a real app, this would be handled securely
  role: 'user' as 'admin' | 'user',
  status: 'active' as 'active' | 'disabled'
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于 6 位', trigger: 'blur' }
  ],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }]
}

const isEditing = computed(() => !!form.id)

const handleAdd = () => {
  dialogTitle.value = '新增用户'
  form.id = ''
  form.username = ''
  form.password = ''
  form.role = 'user'
  form.status = 'active'
  dialogVisible.value = true
}

const handleEdit = (row: any) => {
  dialogTitle.value = '编辑用户'
  form.id = row.id
  form.username = row.username
  form.password = '******' // Placeholder, won't update unless changed
  form.role = row.role
  form.status = row.is_active ? 'active' : 'disabled'
  dialogVisible.value = true
}

const handleDelete = (row: any) => {
  ElMessageBox.confirm(
    `确定要删除用户 ${row.username} 吗？`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(() => {
    try {
      usersStore.deleteUser(row.id)
      ElMessage.success('删除成功')
    } catch (error: any) {
      ElMessage.error(error.message)
    }
  }).catch(() => {})
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate((valid: boolean) => {
    if (valid) {
      try {
        if (isEditing.value) {
          // Update
          usersStore.updateUser(form.id as unknown as number, {
            username: form.username,
            password: form.password,
            role: form.role,
            status: form.status
          })
          ElMessage.success('用户已更新')
        } else {
          // Create
          usersStore.addUser({
            username: form.username,
            password: form.password,
            role: form.role,
            status: form.status
          })
          ElMessage.success('用户已创建')
        }
        dialogVisible.value = false
      } catch (error: any) {
        ElMessage.error(error.message)
      }
    }
  })
}
</script>

<template>
  <div class="h-full max-w-7xl mx-auto flex flex-col gap-6">
    <!-- 头部区域 -->
    <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">用户管理</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">管理系统用户的权限与状态</p>
      </div>
      <el-button type="primary" :icon="Plus" @click="handleAdd" class="w-full sm:w-auto !rounded-xl !h-10 shadow-sm shadow-blue-500/20 font-medium px-6">新增用户</el-button>
    </div>

    <div class="flex-1 bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col min-h-0">
      <el-table :data="tableData" style="width: 100%; flex: 1;" height="100%" class="custom-table" :header-cell-style="{ background: 'var(--el-fill-color-light)', color: 'var(--text-main)', fontWeight: '600', height: '50px' }" :row-style="{ height: '60px' }">
        <el-table-column prop="id" label="ID" width="100" />
        <el-table-column prop="username" label="用户名" min-width="150">
          <template #default="{ row }">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 dark:from-blue-900/50 dark:to-indigo-900/50 flex items-center justify-center text-blue-600 dark:text-blue-400 font-bold text-sm">
                {{ row.username.charAt(0).toUpperCase() }}
              </div>
              <span class="font-medium">{{ row.username }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="role" label="角色" width="120">
          <template #default="{ row }">
            <div :class="row.role === 'admin' ? 'bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400' : 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'" class="inline-flex items-center justify-center px-2.5 py-1 rounded-md text-xs font-medium border border-transparent">
              {{ row.role === 'admin' ? '管理员' : '普通用户' }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="is_active" label="状态" width="120">
          <template #default="{ row }">
            <div :class="row.is_active ? 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400' : 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'" class="inline-flex items-center justify-center px-2.5 py-1 rounded-md text-xs font-medium border border-transparent">
              <div class="w-1.5 h-1.5 rounded-full mr-1.5" :class="row.is_active ? 'bg-green-500' : 'bg-gray-400'"></div>
              {{ row.is_active ? '正常' : '禁用' }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            <span class="text-[var(--text-muted)]">{{ formatDate(row.created_at) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right" align="center">
          <template #default="scope">
            <div class="flex items-center justify-center gap-2">
              <el-tooltip content="编辑" placement="top" :show-after="300">
                <el-button circle size="small" type="primary" :icon="Edit" @click="handleEdit(scope.row)" class="!bg-blue-50 hover:!bg-blue-100 dark:!bg-blue-900/30 dark:hover:!bg-blue-900/50 !border-transparent !text-blue-500 transition-colors" />
              </el-tooltip>
              <el-tooltip content="删除" placement="top" :show-after="300" v-if="scope.row.username !== 'admin'">
                <el-button circle size="small" type="danger" :icon="Delete" @click="handleDelete(scope.row)" class="!bg-red-50 hover:!bg-red-100 dark:!bg-red-900/30 dark:hover:!bg-red-900/50 !border-transparent !text-red-500 transition-colors" />
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
          :total="usersStore.users.length"
          :page-sizes="[10, 20, 50, 100]"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          class="custom-pagination"
        />
      </div>
    </div>

    <!-- Dialog -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" :width="appStore.isMobile ? '90%' : '500px'" class="!rounded-2xl custom-dialog" :show-close="false">
      <template #header="{ close, titleId, titleClass }">
        <div class="flex justify-between items-center px-2 pt-2">
          <h4 :id="titleId" :class="titleClass" class="!text-lg !font-bold text-[var(--text-main)]">{{ dialogTitle }}</h4>
          <div class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer text-gray-400 transition-colors" @click="close">
            <el-icon><Close /></el-icon>
          </div>
        </div>
      </template>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="80px" :label-position="appStore.isMobile ? 'top' : 'left'" class="mt-4 px-2">
        <el-form-item label="用户名" prop="username" class="font-medium">
          <el-input v-model="form.username" :disabled="isEditing && form.username === 'admin'" class="!rounded-xl" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="密码" prop="password" class="font-medium mt-6">
           <el-input v-model="form.password" type="password" show-password class="!rounded-xl" placeholder="请输入密码" />
        </el-form-item>
        <el-form-item label="角色" prop="role" class="font-medium mt-6">
          <el-select v-model="form.role" class="w-full !rounded-xl">
            <el-option label="管理员" value="admin" />
            <el-option label="普通用户" value="user" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status" v-if="isEditing" class="font-medium mt-6">
          <el-radio-group v-model="form.status">
            <el-radio-button label="active" class="!rounded-l-xl">正常</el-radio-button>
            <el-radio-button label="disabled" class="!rounded-r-xl">禁用</el-radio-button>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="flex justify-end gap-3 px-2 pb-2 mt-4">
          <el-button @click="dialogVisible = false" class="!rounded-xl !h-10 font-medium px-6 hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">取消</el-button>
          <el-button type="primary" @click="handleSubmit" class="!rounded-xl !h-10 font-medium shadow-sm shadow-blue-500/20 px-6">确定</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>
