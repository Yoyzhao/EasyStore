<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Download, Upload, CopyDocument, FolderAdd } from '@element-plus/icons-vue'
import request from '@/api/request'
import { useAppStore } from '@/store/app'
import { useUserStore } from '@/store/user'
import { formatToUTC8 } from '@/utils/date'

const activeTab = ref('general')
const appStore = useAppStore()
const userStore = useUserStore()

// ====== 系统设置 ======
const settingsFormRef = ref()
const settingsForm = ref({
  upload: {
    max_size_mb: 5,
    allowed_extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp']
  },
  access: {
    allow_external_ip: false
  },
  storage: {
    data_path: 'data',
    current_abs_path: '',
    migration_action: 'none'
  },
  general: {
    project_name: 'EasyStore',
    port: 8000
  }
})

const extensionOptions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip', 'rar']

const loadingSettings = ref(false)
const savingSettings = ref(false)
const originalDataPath = ref('')
const originalPort = ref(8000)
const migrationDialogVisible = ref(false)
const migrationAction = ref('migrate') // 'migrate' or 'create_new'

const fetchSettings = async () => {
  loadingSettings.value = true
  try {
    const res: any = await request.get('/system/settings')
    settingsForm.value = res
    originalDataPath.value = res.storage.data_path
    originalPort.value = res.general.port
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
      // 检查路径是否改变
      if (settingsForm.value.storage.data_path !== originalDataPath.value) {
        migrationDialogVisible.value = true
        return
      }
      
      await performSave()
    }
  })
}

const confirmSaveWithMigration = async () => {
  settingsForm.value.storage.migration_action = migrationAction.value
  await performSave()
  migrationDialogVisible.value = false
}

const performSave = async () => {
  savingSettings.value = true
  try {
    await request.put('/system/settings', settingsForm.value)
    ElMessage.success('设置保存成功')
    
    // 如果修改了端口或路径，提醒重启
    const needsRestart = settingsForm.value.general.port !== originalPort.value || 
                        settingsForm.value.storage.data_path !== originalDataPath.value
    
    if (needsRestart) {
      // 检查是否在 Electron 环境下
      const isElectron = !!(window as any).electronAPI
      
      if (isElectron) {
        try {
          await ElMessageBox.confirm('配置已更改，为了使新路径生效，系统需要重启后端服务。是否现在自动重启？', '配置变更', {
            confirmButtonText: '立即重启',
            cancelButtonText: '稍后手动重启',
            type: 'warning'
          })
          
          savingSettings.value = true
          await (window as any).electronAPI.restartBackend()
          ElMessage.success('后端服务已重启，配置已生效')
          await fetchSettings()
        } catch (error) {
          if (error !== 'cancel') {
            ElMessage.error('自动重启失败，请尝试手动重启应用')
          }
        }
      } else {
        ElMessageBox.alert('配置已更改，请手动重启后端服务以使新路径或端口生效。', '保存成功', {
          confirmButtonText: '我知道了',
          type: 'success'
        })
      }
    }
    
    originalDataPath.value = settingsForm.value.storage.data_path
    originalPort.value = settingsForm.value.general.port
  } catch (error: any) {
    ElMessage.error(error.response?.data?.detail || '保存设置失败')
  } finally {
    savingSettings.value = false
  }
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
    const dateStr = formatToUTC8(new Date()).replace(/[\/ :]/g, '-')
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
  <div class="h-full max-w-7xl mx-auto flex flex-col gap-6">
    <!-- 头部区域 -->
    <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 relative overflow-hidden group">
      <!-- 装饰圆圈 -->
      <div class="absolute -right-10 -top-10 w-32 h-32 rounded-full opacity-5 bg-[#3B82F6] group-hover:opacity-10 group-hover:scale-110 transition-all duration-700 ease-out origin-top-right"></div>
      
      <div class="relative z-10">
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">系统设置</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">管理系统参数与数据备份恢复</p>
      </div>
    </div>

    <div class="flex-1 bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col min-h-0">
      <div class="h-full overflow-auto">
        <el-tabs v-model="activeTab" class="system-tabs h-full flex flex-col custom-tabs">
          
          <!-- 常规设置 / 上传设置 -->
          <el-tab-pane label="常规参数" name="general" class="h-full overflow-auto">
            <div class="py-6 px-2 sm:px-6 max-w-3xl" v-loading="loadingSettings">
              <el-form 
                ref="settingsFormRef" 
                :model="settingsForm" 
                label-width="160px" 
                :label-position="appStore.isMobile ? 'top' : 'left'"
                class="mt-4"
              >
                <div class="flex items-center gap-2 mb-6 mt-2">
                  <div class="w-1 h-5 bg-blue-500 rounded-full"></div>
                  <div class="font-bold text-lg text-[var(--text-main)]">系统信息设置</div>
                </div>

                <el-form-item label="系统名称" prop="general.project_name" class="font-medium">
                  <el-input
                    v-model="settingsForm.general.project_name"
                    placeholder="请输入系统名称"
                    class="!w-full max-w-md !rounded-xl"
                  />
                  <div class="w-full text-xs mt-2 text-[var(--text-muted)] font-normal">
                    设置系统的显示名称，将展示在页面标题和页脚。
                  </div>
                </el-form-item>

                <el-form-item label="运行端口" prop="general.port" class="font-medium">
                  <el-input-number
                    v-model="settingsForm.general.port"
                    :min="1"
                    :max="65535"
                    controls-position="right"
                    class="!w-48 !rounded-xl"
                  />
                  <div class="w-full text-xs mt-2 text-[var(--text-muted)] font-normal">
                    系统后端服务的运行端口。修改后需要重启服务生效。
                  </div>
                </el-form-item>

                <div class="flex items-center gap-2 mb-6 mt-10">
                  <div class="w-1 h-5 bg-blue-500 rounded-full"></div>
                  <div class="font-bold text-lg text-[var(--text-main)]">上传限制设置</div>
                </div>
                
                <el-form-item label="最大文件大小 (MB)" prop="upload.max_size_mb" class="font-medium">
                  <el-input-number 
                    v-model="settingsForm.upload.max_size_mb" 
                    :min="1" 
                    :max="100" 
                    :step="1"
                    class="!w-48 !rounded-xl"
                  />
                  <div class="w-full text-xs mt-2 text-[var(--text-muted)] font-normal">
                    控制系统允许上传的单个文件最大体积
                  </div>
                </el-form-item>
                
                <el-form-item label="允许的格式后缀" prop="upload.allowed_extensions" class="font-medium">
                  <el-select
                    v-model="settingsForm.upload.allowed_extensions"
                    multiple
                    filterable
                    allow-create
                    default-first-option
                    placeholder="请选择或输入允许的格式"
                    class="!w-full max-w-md !rounded-xl custom-select"
                  >
                    <el-option
                      v-for="ext in extensionOptions"
                      :key="ext"
                      :label="ext"
                      :value="ext"
                    />
                  </el-select>
                  <div class="w-full text-xs mt-2 text-[var(--text-muted)] font-normal">
                    控制系统允许上传的文件后缀类型，可直接输入并回车添加新类型
                  </div>
                </el-form-item>

                <div class="flex items-center gap-2 mb-6 mt-10">
                  <div class="w-1 h-5 bg-blue-500 rounded-full"></div>
                  <div class="font-bold text-lg text-[var(--text-main)]">访问控制设置</div>
                </div>
                
                <el-form-item label="允许外部访问" prop="access.allow_external_ip" class="font-medium">
                  <el-switch
                    v-model="settingsForm.access.allow_external_ip"
                    active-text="允许"
                    inactive-text="仅本机"
                  />
                  <div class="w-full text-xs mt-2 text-[var(--text-muted)] font-normal">
                    开启后，允许其他IP地址的设备访问本系统；关闭后，仅允许本机 (127.0.0.1 / localhost) 访问。
                  </div>
                </el-form-item>

                <div class="flex items-center gap-2 mb-6 mt-10">
                  <div class="w-1 h-5 bg-blue-500 rounded-full"></div>
                  <div class="font-bold text-lg text-[var(--text-main)]">存储位置设置</div>
                </div>

                <el-form-item label="数据保存路径" prop="storage.data_path" class="font-medium">
                  <el-input
                    v-model="settingsForm.storage.data_path"
                    :placeholder="`当前: ${settingsForm.storage.current_abs_path || 'data'}`"
                    class="!w-full max-w-md !rounded-xl"
                  />
                  <div class="w-full text-xs mt-2 text-[var(--text-muted)] font-normal">
                    控制数据库文件和上传文件的保存根路径。支持相对路径 (如 data) 或绝对路径 (如 D:\EasyStoreData)。
                    <span v-if="settingsForm.storage.current_abs_path" class="text-blue-500 font-medium">
                      当前实际路径: {{ settingsForm.storage.current_abs_path }}
                    </span>
                    <br/>修改后需手动将原数据文件夹移动到新位置并重启系统。
                  </div>
                </el-form-item>

                <el-form-item class="mt-10">
                  <el-button v-if="userStore.userInfo.role === 'admin'" type="primary" @click="saveSettings" :loading="savingSettings" class="!rounded-xl !h-11 font-medium shadow-sm shadow-blue-500/20 px-8 text-base">
                    保存设置
                  </el-button>
                  <el-button @click="fetchSettings" class="!rounded-xl !h-11 font-medium px-8 text-base hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">重置修改</el-button>
                </el-form-item>
              </el-form>
            </div>
          </el-tab-pane>

          <!-- 备份与恢复 -->
          <el-tab-pane label="备份与恢复" name="backup" class="h-full overflow-auto">
            <div class="py-8 px-2 sm:px-6 max-w-5xl">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8">
                
                <!-- 备份卡片 -->
                <div class="border rounded-2xl p-8 flex flex-col h-full bg-blue-50/50 dark:bg-blue-900/10 border-blue-100 dark:border-blue-900/30 hover:shadow-md transition-shadow">
                  <div class="flex items-center mb-6 text-xl font-bold text-blue-600 dark:text-blue-400">
                    <div class="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/50 flex items-center justify-center mr-3">
                      <el-icon size="20"><Download /></el-icon>
                    </div>
                    数据备份
                  </div>
                  <p class="text-[var(--text-muted)] leading-relaxed mb-8 flex-1">
                    将当前的数据库文件、系统配置以及所有上传的图片附件打包下载到本地。建议定期备份以防数据丢失。
                  </p>
                  <el-button 
                    v-if="userStore.userInfo.role === 'admin'"
                    type="primary" 
                    size="large" 
                    class="w-full !rounded-xl !h-12 font-medium shadow-sm shadow-blue-500/20 text-base" 
                    @click="handleBackup" 
                    :loading="downloading"
                  >
                    下载系统备份
                  </el-button>
                </div>

                <!-- 恢复卡片 -->
                <div class="border rounded-2xl p-8 flex flex-col h-full bg-red-50/50 dark:bg-red-900/10 border-red-100 dark:border-red-900/30 hover:shadow-md transition-shadow">
                  <div class="flex items-center mb-6 text-xl font-bold text-red-600 dark:text-red-400">
                    <div class="w-10 h-10 rounded-full bg-red-100 dark:bg-red-900/50 flex items-center justify-center mr-3">
                      <el-icon size="20"><Upload /></el-icon>
                    </div>
                    数据恢复
                  </div>
                  <p class="text-[var(--text-muted)] leading-relaxed mb-8 flex-1">
                    上传之前下载的 <b>.zip</b> 备份文件进行数据恢复。
                    <span class="text-red-500 font-medium block mt-2 p-3 bg-red-100/50 dark:bg-red-900/20 rounded-lg">⚠️ 警告：此操作将覆盖当前系统所有数据，请谨慎操作！</span>
                  </p>
                  
                  <el-upload
                    v-if="userStore.userInfo.role === 'admin'"
                    action="#"
                    :show-file-list="false"
                    :before-upload="beforeRestoreUpload"
                    :http-request="handleRestore"
                    accept=".zip"
                    class="w-full upload-full"
                  >
                    <el-button 
                      type="danger" 
                      size="large" 
                      class="w-full !rounded-xl !h-12 font-medium shadow-sm shadow-red-500/20 text-base"
                      :loading="restoring"
                    >
                      上传备份并恢复
                    </el-button>
                  </el-upload>
                </div>

              </div>
            </div>
          </el-tab-pane>
          
        </el-tabs>
      </div>
    </div>
  </div>

  <!-- 数据迁移选择弹窗 -->
  <el-dialog
    v-model="migrationDialogVisible"
    title="数据存储路径变更"
    width="500px"
    append-to-body
    class="!rounded-2xl"
  >
    <div class="py-2">
      <p class="text-[var(--text-main)] mb-4 font-medium">您更改了数据保存路径，请选择处理现有数据的方式：</p>
      
      <div class="space-y-4">
        <div 
          class="border rounded-xl p-4 cursor-pointer hover:border-blue-500 hover:bg-blue-50/50 transition-all group"
          :class="migrationAction === 'migrate' ? 'border-blue-500 bg-blue-50/50 shadow-sm shadow-blue-500/10' : 'border-[var(--border-subtle)]'"
          @click="migrationAction = 'migrate'"
        >
          <div class="flex items-center gap-2 font-bold text-blue-600 mb-1">
            <el-icon><CopyDocument /></el-icon>
            迁移现有数据
          </div>
          <p class="text-xs text-[var(--text-muted)] leading-relaxed">
            将当前路径 ({{ settingsForm.storage.current_abs_path }}) 下的所有数据库和文件自动复制到新路径。
          </p>
        </div>

        <div 
          class="border rounded-xl p-4 cursor-pointer hover:border-orange-500 hover:bg-orange-50/50 transition-all group"
          :class="migrationAction === 'create_new' ? 'border-orange-500 bg-orange-50/50 shadow-sm shadow-orange-500/10' : 'border-[var(--border-subtle)]'"
          @click="migrationAction = 'create_new'"
        >
          <div class="flex items-center gap-2 font-bold text-orange-600 mb-1">
            <el-icon><FolderAdd /></el-icon>
            仅更改路径 (新建目录)
          </div>
          <p class="text-xs text-[var(--text-muted)] leading-relaxed">
            在新路径创建一个空的存储目录。原有数据将保留在原处，但系统不再使用。
          </p>
        </div>
      </div>
    </div>
    <template #footer>
      <div class="flex gap-3 justify-end">
        <el-button @click="migrationDialogVisible = false" class="!rounded-xl">取消</el-button>
        <el-button type="primary" @click="confirmSaveWithMigration" :loading="savingSettings" class="!rounded-xl shadow-sm shadow-blue-500/20 px-6">
          确认并保存
        </el-button>
      </div>
    </template>
  </el-dialog>
</template>

<style scoped>
.system-tabs :deep(.el-tabs__item) {
  font-size: 15px;
  padding: 0 24px;
  height: 50px;
  line-height: 50px;
  font-weight: 500;
  transition: all 0.3s;
}

.system-tabs :deep(.el-tabs__nav-wrap::after) {
  height: 1px;
  background-color: var(--border-subtle);
}

.system-tabs :deep(.el-tabs__active-bar) {
  height: 3px;
  border-radius: 3px 3px 0 0;
}

.system-tabs :deep(.el-tabs__content) {
  flex: 1;
  overflow: hidden;
}
.upload-full :deep(.el-upload) {
  width: 100%;
}

/* 覆盖Select下拉多选标签的样式 */
.custom-select :deep(.el-select__tags .el-tag) {
  border-radius: 6px;
}
</style>
