<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/api/request'

const activeTab = ref('general')

// ====== 系统设置 ======
const settingsFormRef = ref()
const settingsForm = ref({
  upload: {
    max_size_mb: 5,
    allowed_extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp']
  }
})

const extensionOptions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip', 'rar']

const loadingSettings = ref(false)
const savingSettings = ref(false)

const fetchSettings = async () => {
  loadingSettings.value = true
  try {
    const res: any = await request.get('/system/settings')
    settingsForm.value = res
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '获取设置失败')
  } finally {
    loadingSettings.value = false
  }
}

const saveSettings = async () => {
  if (!settingsFormRef.value) return
  await settingsFormRef.value.validate(async (valid: boolean) => {
    if (valid) {
      savingSettings.value = true
      try {
        await request.put('/system/settings', settingsForm.value)
        ElMessage.success('设置保存成功')
      } catch (error: any) {
        ElMessage.error(error.response?.data?.detail || '保存设置失败')
      } finally {
        savingSettings.value = false
      }
    }
  })
}

// ====== 备份与恢复 ======
const downloading = ref(false)
const restoring = ref(false)

const handleBackup = async () => {
  try {
    downloading.value = true
    const response: any = await request.get('/system/backup', {
      responseType: 'blob'
    })
    
    // Create a blob from the response
    const blob = new Blob([response], { type: 'application/zip' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    const dateStr = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
    link.setAttribute('download', `easystore_backup_${dateStr}.zip`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('备份下载成功')
  } catch (error) {
    ElMessage.error('备份失败')
  } finally {
    downloading.value = false
  }
}

const beforeRestoreUpload = (file: File) => {
  const isZip = file.name.endsWith('.zip')
  if (!isZip) {
    ElMessage.error('只能上传 zip 格式的备份文件!')
    return false
  }
  return true
}

const handleRestore = async (options: any) => {
  try {
    await ElMessageBox.confirm(
      '恢复数据将覆盖当前系统的所有数据（包括数据库和上传的图片）。此操作不可逆！是否确认恢复？',
      '高危操作确认',
      {
        confirmButtonText: '确认恢复',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    
    restoring.value = true
    const formData = new FormData()
    formData.append('file', options.file)
    
    await request.post('/system/restore', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    
    ElMessage.success('系统数据恢复成功！请刷新页面或重启服务以确保数据生效。')
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.detail || '恢复数据失败')
    }
  } finally {
    restoring.value = false
  }
}

onMounted(() => {
  fetchSettings()
})
</script>

<template>
  <div class="h-full flex flex-col gap-4">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">系统设置</h1>
    </div>

    <el-card shadow="hover" class="flex-1 flex flex-col border-none" style="background-color: var(--el-bg-color-overlay);" :body-style="{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }">
      <div class="h-full overflow-auto">
        <el-tabs v-model="activeTab" class="system-tabs h-full flex flex-col">
          
          <!-- 常规设置 / 上传设置 -->
          <el-tab-pane label="常规参数" name="general" class="h-full overflow-auto">
            <div class="py-4 px-6 max-w-3xl" v-loading="loadingSettings">
              <el-form 
                ref="settingsFormRef" 
                :model="settingsForm" 
                label-width="140px" 
                label-position="left"
              >
                <div class="font-bold text-lg mb-4 mt-2" style="color: var(--el-text-color-primary)">上传限制设置</div>
                
                <el-form-item label="最大文件大小 (MB)" prop="upload.max_size_mb">
                  <el-input-number 
                    v-model="settingsForm.upload.max_size_mb" 
                    :min="1" 
                    :max="100" 
                    :step="1"
                    class="!w-48"
                  />
                  <div class="ml-4 text-xs" style="color: var(--el-text-color-secondary)">
                    控制系统允许上传的单个文件最大体积
                  </div>
                </el-form-item>
                
                <el-form-item label="允许的格式后缀" prop="upload.allowed_extensions">
                  <el-select
                    v-model="settingsForm.upload.allowed_extensions"
                    multiple
                    filterable
                    allow-create
                    default-first-option
                    placeholder="请选择或输入允许的格式"
                    class="!w-full max-w-md"
                  >
                    <el-option
                      v-for="ext in extensionOptions"
                      :key="ext"
                      :label="ext"
                      :value="ext"
                    />
                  </el-select>
                  <div class="w-full text-xs mt-1" style="color: var(--el-text-color-secondary)">
                    控制系统允许上传的文件后缀类型，可直接输入并回车添加新类型
                  </div>
                </el-form-item>

                <el-form-item class="mt-8">
                  <el-button type="primary" @click="saveSettings" :loading="savingSettings">
                    保存设置
                  </el-button>
                  <el-button @click="fetchSettings">重置修改</el-button>
                </el-form-item>
              </el-form>
            </div>
          </el-tab-pane>

          <!-- 备份与恢复 -->
          <el-tab-pane label="备份与恢复" name="backup" class="h-full overflow-auto">
            <div class="py-4 px-6 max-w-5xl">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                
                <!-- 备份卡片 -->
                <div class="border rounded-lg p-6 flex flex-col h-full" style="border-color: var(--el-border-color-light)">
                  <div class="flex items-center mb-4 text-lg font-bold" style="color: var(--el-text-color-primary)">
                    <el-icon class="mr-2 text-blue-500"><Download /></el-icon>
                    数据备份
                  </div>
                  <p class="text-sm mb-6 flex-1" style="color: var(--el-text-color-regular)">
                    将当前的数据库文件、系统配置以及所有上传的图片附件打包下载到本地。建议定期备份以防数据丢失。
                  </p>
                  <el-button 
                    type="primary" 
                    size="large" 
                    class="w-full" 
                    @click="handleBackup" 
                    :loading="downloading"
                  >
                    <el-icon class="mr-2"><Download /></el-icon> 下载系统备份
                  </el-button>
                </div>

                <!-- 恢复卡片 -->
                <div class="border rounded-lg p-6 flex flex-col h-full bg-red-50 dark:bg-red-950/20" style="border-color: var(--el-color-danger-light-7)">
                  <div class="flex items-center mb-4 text-lg font-bold text-red-600 dark:text-red-500">
                    <el-icon class="mr-2"><Upload /></el-icon>
                    数据恢复
                  </div>
                  <p class="text-sm mb-6 flex-1" style="color: var(--el-text-color-regular)">
                    上传之前下载的 <b>.zip</b> 备份文件进行数据恢复。
                    <span class="text-red-500 font-bold block mt-1">警告：此操作将覆盖当前系统所有数据，请谨慎操作！</span>
                  </p>
                  
                  <el-upload
                    action="#"
                    :show-file-list="false"
                    :before-upload="beforeRestoreUpload"
                    :http-request="handleRestore"
                    accept=".zip"
                    class="w-full"
                  >
                    <el-button 
                      type="danger" 
                      size="large" 
                      class="w-full"
                      :loading="restoring"
                    >
                      <el-icon class="mr-2"><Upload /></el-icon> 上传备份并恢复
                    </el-button>
                  </el-upload>
                </div>

              </div>
            </div>
          </el-tab-pane>
          
        </el-tabs>
      </div>
    </el-card>
  </div>
</template>

<style scoped>
.system-tabs :deep(.el-tabs__item) {
  font-size: 16px;
  padding: 0 24px;
}
.system-tabs :deep(.el-tabs__content) {
  flex: 1;
  overflow: hidden;
}
</style>
