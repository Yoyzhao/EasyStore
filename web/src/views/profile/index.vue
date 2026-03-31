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

const validateConfirmPassword = (_rule: any, value: string, callback: any) => {
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
  <div class="h-full overflow-auto pb-6">
    <div class="max-w-7xl mx-auto space-y-6">
      <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)]">
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">个人中心</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">管理您的个人信息和安全设置</p>
      </div>
      
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- 用户信息卡片 -->
        <div class="bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] overflow-hidden flex flex-col h-full hover:shadow-md transition-shadow">
          <div class="h-24 bg-gradient-to-r from-blue-500 to-indigo-500 w-full"></div>
          <div class="flex flex-col items-center px-6 pb-8 -mt-12 flex-1">
            <div class="w-24 h-24 rounded-full bg-[var(--card-bg)] p-1.5 shadow-md mb-4 relative">
              <div class="w-full h-full rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 dark:from-blue-900/50 dark:to-indigo-900/50 flex items-center justify-center text-blue-600 dark:text-blue-400 text-3xl font-bold font-display">
                {{ userStore.userInfo.username.charAt(0).toUpperCase() }}
              </div>
              <div class="absolute bottom-1 right-1 w-4 h-4 bg-green-500 border-2 border-[var(--card-bg)] rounded-full"></div>
            </div>
            <h3 class="text-xl font-bold mb-2 text-[var(--text-main)]">{{ userStore.userInfo.username }}</h3>
            <div :class="userStore.userInfo.role === 'admin' ? 'bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400' : 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'" class="inline-flex items-center justify-center px-3 py-1 rounded-full text-xs font-bold border border-transparent shadow-sm">
              {{ userStore.userInfo.role === 'admin' ? '超级管理员' : '普通用户' }}
            </div>
            
            <div class="w-full border-t border-[var(--border-subtle)] pt-6 mt-8">
              <div class="flex justify-between items-center py-3">
                <div class="flex items-center text-[var(--text-muted)] text-sm">
                  <el-icon class="mr-2"><User /></el-icon>
                  账号状态
                </div>
                <div class="bg-green-50 text-green-600 dark:bg-green-900/20 dark:text-green-400 px-2.5 py-1 rounded-md text-xs font-medium">正常</div>
              </div>
              <div class="flex justify-between items-center py-3">
                <div class="flex items-center text-[var(--text-muted)] text-sm">
                  <el-icon class="mr-2"><Key /></el-icon>
                  注册角色
                </div>
                <span class="text-[var(--text-main)] font-medium text-sm">{{ userStore.userInfo.role }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 修改密码卡片 -->
        <div class="lg:col-span-2 bg-[var(--card-bg)] p-8 rounded-2xl shadow-sm border border-[var(--border-subtle)] hover:shadow-md transition-shadow">
          <div class="flex items-center gap-3 mb-8 pb-4 border-b border-[var(--border-subtle)]">
            <div class="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400">
              <el-icon size="20"><Lock /></el-icon>
            </div>
            <div class="font-bold text-lg text-[var(--text-main)]">修改密码</div>
          </div>
          
          <el-form
            ref="passwordFormRef"
            :model="passwordForm"
            :rules="rules"
            label-width="100px"
            class="max-w-md mx-auto mt-4"
            label-position="top"
          >
            <el-form-item label="原密码" prop="old_password" class="font-medium">
              <el-input 
                v-model="passwordForm.old_password" 
                type="password" 
                show-password 
                placeholder="请输入当前密码" 
                class="!rounded-xl"
              />
            </el-form-item>
            
            <el-form-item label="新密码" prop="new_password" class="font-medium mt-6">
              <el-input 
                v-model="passwordForm.new_password" 
                type="password" 
                show-password 
                placeholder="请输入新密码" 
                class="!rounded-xl"
              />
            </el-form-item>
            
            <el-form-item label="确认新密码" prop="confirm_password" class="font-medium mt-6">
              <el-input 
                v-model="passwordForm.confirm_password" 
                type="password" 
                show-password 
                placeholder="请再次输入新密码" 
                class="!rounded-xl"
              />
            </el-form-item>
            
            <el-form-item class="mt-8 pt-4 border-t border-[var(--border-subtle)]">
              <div class="flex w-full gap-4">
                <el-button type="primary" @click="submitPassword" :loading="submitting" class="flex-1 !rounded-xl !h-11 font-medium shadow-sm shadow-blue-500/20 text-base">
                  确认修改
                </el-button>
                <el-button @click="passwordFormRef?.resetFields()" class="flex-1 !rounded-xl !h-11 font-medium text-base hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">
                  重置
                </el-button>
              </div>
            </el-form-item>
          </el-form>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* 可以在这里添加局部样式 */
</style>
