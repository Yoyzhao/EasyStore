<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/store/user'
import { User, Lock, Box } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()

const loading = ref(false)
const rememberMe = ref(false)
const loginForm = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

const formRef = ref()

const handleLogin = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      loading.value = true
      try {
        await userStore.login(loginForm)
        ElMessage.success('登录成功')
        router.push('/')
      } catch (error: any) {
        ElMessage.error(error.message || '登录失败')
      } finally {
        loading.value = false
      }
    }
  })
}
</script>

<template>
  <div class="min-h-screen flex relative overflow-hidden bg-slate-50 dark:bg-slate-950">
    <!-- Background Decoration -->
    <div class="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] rounded-full bg-blue-500/10 blur-[100px] pointer-events-none"></div>
    <div class="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-purple-500/10 blur-[100px] pointer-events-none"></div>

    <div class="flex-1 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 relative z-10">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <!-- Logo Area -->
        <div class="flex justify-center mb-6">
          <div class="w-20 h-20 rounded-[1.25rem] bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-[0_8px_30px_rgb(59,130,246,0.3)] transform transition-transform hover:scale-105 duration-300 relative group">
            <div class="absolute inset-0 bg-white/20 rounded-[1.25rem] opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <el-icon class="text-5xl text-white drop-shadow-md"><Box /></el-icon>
          </div>
        </div>
        <h2 class="mt-2 text-center text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          EasyStore
        </h2>
        <p class="mt-2 text-center text-sm text-slate-500 dark:text-slate-400 font-medium">
          简易仓库管理系统 · 高效运转
        </p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10 border border-slate-200/50 dark:border-slate-700/50">
          <el-form
            ref="formRef"
            :model="loginForm"
            :rules="rules"
            class="space-y-6"
            @keyup.enter="handleLogin"
            size="large"
          >
            <el-form-item prop="username">
              <el-input
                v-model="loginForm.username"
                placeholder="用户名 (admin/user)"
                :prefix-icon="User"
                class="custom-input"
              />
            </el-form-item>

            <el-form-item prop="password">
              <el-input
                v-model="loginForm.password"
                type="password"
                placeholder="密码 (123456)"
                :prefix-icon="Lock"
                show-password
                class="custom-input"
              />
            </el-form-item>

            <div class="flex items-center justify-between mt-4 mb-6">
              <div class="flex items-center">
                <el-checkbox v-model="rememberMe" class="text-sm">记住我</el-checkbox>
              </div>
              <div class="text-sm">
                <a href="#" class="font-medium text-blue-600 hover:text-blue-500 dark:text-blue-400 transition-colors">忘记密码?</a>
              </div>
            </div>

            <el-button
              type="primary"
              :loading="loading"
              class="w-full !rounded-xl !h-12 !text-base font-semibold shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 transition-all duration-300"
              @click="handleLogin"
            >
              登 录
            </el-button>
          </el-form>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
:deep(.custom-input .el-input__wrapper) {
  border-radius: 0.75rem;
  box-shadow: 0 0 0 1px var(--el-border-color) inset;
  padding: 0 15px;
  background-color: var(--el-fill-color-blank);
  transition: all 0.3s ease;
}

:deep(.custom-input .el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 2px var(--el-color-primary) inset;
}

:deep(.custom-input .el-input__inner) {
  height: 48px;
}

/* 深色模式特定适配补充 */
html.dark :deep(.custom-input .el-input__wrapper) {
  background-color: var(--el-bg-color-overlay);
  box-shadow: 0 0 0 1px var(--el-border-color-darker) inset;
}

html.dark :deep(.custom-input .el-input__inner) {
  color: var(--el-text-color-primary);
}
</style>
