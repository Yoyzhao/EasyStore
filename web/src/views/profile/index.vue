<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useUserStore } from '@/store/user'
import { ElMessage } from 'element-plus'
import request from '@/api/request'

const userStore = useUserStore()

const passwordFormRef = ref()
const passwordForm = reactive({
  old_password: '',
  new_password: '',
  confirm_password: ''
})

const validateConfirmPassword = (rule: any, value: string, callback: any) => {
  if (value === '') {
    callback(new Error('请再次输入新密码'))
  } else if (value !== passwordForm.new_password) {
    callback(new Error('两次输入密码不一致!'))
  } else {
    callback()
  }
}

const rules = {
  old_password: [
    { required: true, message: '请输入原密码', trigger: 'blur' },
    { min: 6, max: 20, message: '长度在 6 到 20 个字符', trigger: 'blur' }
  ],
  new_password: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '长度在 6 到 20 个字符', trigger: 'blur' }
  ],
  confirm_password: [
    { required: true, validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

const submitting = ref(false)

const submitPassword = async () => {
  if (!passwordFormRef.value) return
  await passwordFormRef.value.validate(async (valid: boolean) => {
    if (valid) {
      try {
        submitting.value = true
        await request.put('/users/me/password', {
          old_password: passwordForm.old_password,
          new_password: passwordForm.new_password
        })
        ElMessage.success('密码修改成功，请重新登录')
        passwordFormRef.value.resetFields()
        setTimeout(() => {
          userStore.logout()
        }, 1500)
      } catch (error: any) {
        ElMessage.error(error.response?.data?.detail || '修改失败，请检查原密码是否正确')
      } finally {
        submitting.value = false
      }
    }
  })
}
</script>

<template>
  <div class="p-6 h-full overflow-auto">
    <div class="max-w-3xl mx-auto">
      <h2 class="text-2xl font-bold mb-6" style="color: var(--el-text-color-primary)">个人中心</h2>
      
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- 用户信息卡片 -->
        <el-card class="col-span-1 border-none shadow-sm" style="background-color: var(--el-bg-color-overlay)">
          <div class="flex flex-col items-center py-6">
            <el-avatar :size="80" src="https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png" class="mb-4" />
            <h3 class="text-xl font-bold mb-2" style="color: var(--el-text-color-primary)">{{ userStore.userInfo.username }}</h3>
            <el-tag :type="userStore.userInfo.role === 'admin' ? 'danger' : 'info'" effect="dark" round>
              {{ userStore.userInfo.role === 'admin' ? '超级管理员' : '普通用户' }}
            </el-tag>
          </div>
          <div class="border-t pt-4 mt-2" style="border-color: var(--el-border-color-light)">
            <div class="flex justify-between py-2 text-sm">
              <span style="color: var(--el-text-color-secondary)">账号状态</span>
              <span class="text-green-500 font-medium">正常</span>
            </div>
            <div class="flex justify-between py-2 text-sm">
              <span style="color: var(--el-text-color-secondary)">注册角色</span>
              <span style="color: var(--el-text-color-primary)">{{ userStore.userInfo.role }}</span>
            </div>
          </div>
        </el-card>

        <!-- 修改密码卡片 -->
        <el-card class="col-span-1 md:col-span-2 border-none shadow-sm" style="background-color: var(--el-bg-color-overlay)">
          <template #header>
            <div class="font-medium">修改密码</div>
          </template>
          
          <el-form
            ref="passwordFormRef"
            :model="passwordForm"
            :rules="rules"
            label-width="100px"
            class="mt-4 pr-8"
          >
            <el-form-item label="原密码" prop="old_password">
              <el-input 
                v-model="passwordForm.old_password" 
                type="password" 
                show-password 
                placeholder="请输入当前密码" 
              />
            </el-form-item>
            
            <el-form-item label="新密码" prop="new_password">
              <el-input 
                v-model="passwordForm.new_password" 
                type="password" 
                show-password 
                placeholder="请输入新密码" 
              />
            </el-form-item>
            
            <el-form-item label="确认新密码" prop="confirm_password">
              <el-input 
                v-model="passwordForm.confirm_password" 
                type="password" 
                show-password 
                placeholder="请再次输入新密码" 
              />
            </el-form-item>
            
            <el-form-item>
              <el-button type="primary" @click="submitPassword" :loading="submitting">
                确认修改
              </el-button>
              <el-button @click="passwordFormRef?.resetFields()">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* 可以在这里添加局部样式 */
</style>
