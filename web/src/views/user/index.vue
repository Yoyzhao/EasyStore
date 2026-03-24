<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUsersStore } from '@/store/users'

const usersStore = useUsersStore()

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
  <div class="h-full flex flex-col gap-4">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">用户管理</h1>
      <el-button type="primary" :icon="Plus" @click="handleAdd">新增用户</el-button>
    </div>

    <el-card shadow="hover" class="flex-1 flex flex-col border-none" style="background-color: var(--el-bg-color-overlay);" :body-style="{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }">
      <el-table :data="usersStore.users" stripe style="width: 100%; flex: 1;" height="100%">
        <el-table-column prop="id" label="ID" width="100" />
        <el-table-column prop="username" label="用户名" min-width="150" />
        <el-table-column prop="role" label="角色" width="120">
          <template #default="{ row }">
            <el-tag :type="row.role === 'admin' ? 'danger' : 'primary'">
              {{ row.role === 'admin' ? '管理员' : '普通用户' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="is_active" label="状态" width="120">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'info'" effect="plain">
              {{ row.is_active ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button size="small" :icon="Edit" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button 
              size="small" 
              type="danger" 
              :icon="Delete" 
              :disabled="scope.row.username === 'admin'"
              @click="handleDelete(scope.row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Dialog -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" :disabled="isEditing && form.username === 'admin'" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
           <el-input v-model="form.password" type="password" show-password />
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="form.role" class="w-full">
            <el-option label="管理员" value="admin" />
            <el-option label="普通用户" value="user" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status" v-if="isEditing">
          <el-radio-group v-model="form.status">
            <el-radio label="active">正常</el-radio>
            <el-radio label="disabled">禁用</el-radio>
          </el-radio-group>
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
