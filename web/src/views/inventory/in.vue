<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { useInventoryStore } from '@/store/inventory'
import { useUserStore } from '@/store/user'
import { useMetadataStore } from '@/store/metadata'
import { useSystemStore } from '@/store/system'
import { storeToRefs } from 'pinia'
import ImageCropper from '@/components/ImageCropper.vue'
import { BACKEND_URL } from '@/api/request'

const router = useRouter()
const inventoryStore = useInventoryStore()
const userStore = useUserStore()
const metadataStore = useMetadataStore()
const systemStore = useSystemStore()

// 裁剪相关
const imageCropperRef = ref()

onMounted(() => {
  inventoryStore.fetchItems()
  metadataStore.fetchMetadata()
  if (!systemStore.isLoaded && userStore.userInfo?.role === 'admin') {
    systemStore.fetchSettings()
  }
})

const { categories, brands, units } = storeToRefs(metadataStore)

const formRef = ref()
const loading = ref(false)
const inboundMode = ref<'new' | 'existing'>('new')

const form = reactive({
  itemId: null as any,
  name: '',
  category: '',
  brand: '',
  unit: '',
  quantity: 1,
  price: 0,
  low_stock_threshold: 10,
  remarks: '',
  imageType: 'link', // 'link' or 'file'
  image: '',
  itemLink: ''
})

const rules = {
  itemId: [{ required: true, message: '请选择物品', trigger: 'change' }],
  name: [{ required: true, message: '请输入物品名称', trigger: 'blur' }],
  category: [{ required: true, message: '请选择分类', trigger: 'change' }],
  unit: [{ required: true, message: '请选择单位', trigger: 'change' }],
  quantity: [{ required: true, message: '请输入数量', trigger: 'blur' }],
  price: [{ required: true, message: '请输入单价', trigger: 'blur' }],
  low_stock_threshold: [{ required: true, message: '请输入低库存阈值', trigger: 'blur' }]
}

const handleModeChange = () => {
  formRef.value?.resetFields()
  form.itemId = ''
  form.name = ''
  form.category = ''
  form.brand = ''
  form.unit = ''
  form.quantity = 1
  form.price = 0
  form.low_stock_threshold = 10
  form.remarks = ''
  form.imageType = 'link'
  form.image = ''
  form.itemLink = ''
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
    
    // 打开裁剪组件
    imageCropperRef.value.open(file.raw)
  }
}

const handleCropSuccess = (res: any) => {
  form.image = res.url
  ElMessage.success('图片裁剪并上传成功')
}

const getImageUrl = (url?: string) => {
  if (!url) return ''
  if (url.startsWith('http')) return url
  return `${BACKEND_URL}${url}`
}

const handleItemSelect = (id: number) => {
  const item = inventoryStore.items.find(i => i.id === id)
  if (item) {
    form.name = item.name
    form.category = item.category
    form.brand = item.brand || ''
    form.unit = item.unit
    form.price = item.price
    form.low_stock_threshold = item.low_stock_threshold ?? 10
    form.itemLink = item.item_link || ''
    if (item.image_url) {
      form.imageType = 'link'
      form.image = item.image_url
    } else {
      form.imageType = 'link'
      form.image = ''
    }
  }
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      loading.value = true
      
      try {
        await inventoryStore.inbound({
          name: form.name,
          category: form.category,
          brand: form.brand,
          quantity: form.quantity,
          price: form.price,
          unit: form.unit,
          low_stock_threshold: form.low_stock_threshold,
          image_url: form.image,
          item_link: form.itemLink,
          operator: userStore.userInfo.username,
          remark: form.remarks
        })

        ElMessage.success('入库成功')
        router.push('/inventory/list')
      } catch (e: any) {
        // Error is handled in interceptor
      } finally {
        loading.value = false
      }
    }
  })
}

const handleCancel = () => {
  router.back()
}
</script>

<template>
  <div class="h-full max-w-7xl mx-auto flex flex-col gap-6">
    <!-- 头部区域 -->
    <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 relative overflow-hidden group">
      <!-- 装饰圆圈 -->
      <div class="absolute -right-10 -top-10 w-32 h-32 rounded-full opacity-5 bg-[#3B82F6] group-hover:opacity-10 group-hover:scale-110 transition-all duration-700 ease-out origin-top-right"></div>
      
      <div class="relative z-10">
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">物品入库</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">添加新物品或增加现有物品库存</p>
      </div>
      <el-button @click="handleCancel" class="relative z-10 !rounded-xl !h-10 font-medium hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent px-6">返回列表</el-button>
    </div>

    <!-- 表单区域 -->
    <div class="flex-1 bg-[var(--card-bg)] p-8 rounded-2xl shadow-sm border border-[var(--border-subtle)] overflow-auto">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px" class="max-w-3xl mx-auto mt-4" label-position="top">
          <el-form-item label="入库类型" class="font-medium">
            <el-radio-group v-model="inboundMode" @change="handleModeChange" class="!rounded-xl">
              <el-radio-button label="new">新物品入库</el-radio-button>
              <el-radio-button label="existing">已有物品入库</el-radio-button>
            </el-radio-group>
          </el-form-item>

          <el-form-item v-if="inboundMode === 'existing'" label="选择物品" prop="itemId" class="font-medium">
            <el-select v-model="form.itemId" filterable placeholder="搜索物品名称或ID" class="w-full !rounded-xl" @change="handleItemSelect">
              <el-option v-for="item in inventoryStore.items" :key="item.id" :label="`${item.name} (ID: ${item.id})`" :value="item.id" />
            </el-select>
          </el-form-item>

          <el-form-item v-if="inboundMode === 'new'" label="物品名称" prop="name" class="font-medium">
            <el-input v-model="form.name" placeholder="请输入物品名称" class="!rounded-xl" />
          </el-form-item>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="分类" prop="category" class="font-medium">
                <el-select v-model="form.category" placeholder="请选择分类" filterable allow-create class="w-full !rounded-xl" :disabled="inboundMode === 'existing'">
                  <el-option v-for="c in categories" :key="c.id" :label="c.name" :value="c.name" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="品牌" prop="brand" class="font-medium">
                <el-select v-model="form.brand" placeholder="请选择品牌 (可选)" filterable allow-create clearable class="w-full !rounded-xl" :disabled="inboundMode === 'existing'">
                  <el-option v-for="b in brands" :key="b.id" :label="b.name" :value="b.name" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="单位" prop="unit" class="font-medium">
                <el-select v-model="form.unit" placeholder="请选择单位" filterable allow-create class="w-full !rounded-xl" :disabled="inboundMode === 'existing'">
                  <el-option v-for="u in units" :key="u.id" :label="u.name" :value="u.name" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="入库数量" prop="quantity" class="font-medium">
                <el-input-number v-model="form.quantity" :min="1" class="w-full !rounded-xl" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="单价" prop="price" class="font-medium">
                <el-input-number v-model="form.price" :min="0" :precision="2" class="w-full !rounded-xl" :disabled="inboundMode === 'existing'" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="低库存阈值" prop="low_stock_threshold" class="font-medium">
                <el-input-number v-model="form.low_stock_threshold" :min="0" class="w-full !rounded-xl" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="物品链接" prop="itemLink" class="font-medium">
            <el-input v-model="form.itemLink" placeholder="请输入物品购买或参考链接" :disabled="inboundMode === 'existing'" class="!rounded-xl" />
          </el-form-item>

          <el-form-item label="物品图片" class="font-medium">
            <div class="flex flex-col gap-2 w-full">
              <el-radio-group v-model="form.imageType" size="small" :disabled="inboundMode === 'existing'" @change="form.image = ''" class="!rounded-xl">
                <el-radio-button label="link">图片链接</el-radio-button>
                <el-radio-button label="file">本地上传</el-radio-button>
              </el-radio-group>
              
              <el-input 
                v-if="form.imageType === 'link'" 
                v-model="form.image" 
                placeholder="请输入图片URL链接" 
                :disabled="inboundMode === 'existing'" 
                class="!rounded-xl"
              />
              
              <div v-else class="flex flex-col gap-1 mt-2">
                <el-upload
                  class="avatar-uploader"
                  action="#"
                  :show-file-list="false"
                  :auto-upload="false"
                  :on-change="handleImageChange"
                  :disabled="inboundMode === 'existing'"
                >
                  <div v-if="form.image" class="w-32 h-32 border border-[var(--border-subtle)] rounded-xl overflow-hidden shadow-sm">
                    <img :src="getImageUrl(form.image)" class="w-full h-full object-cover" />
                  </div>
                  <div v-else class="w-32 h-32 border border-dashed border-[var(--border-subtle)] rounded-xl flex items-center justify-center cursor-pointer hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-all" :class="{'bg-gray-100 dark:bg-gray-800 cursor-not-allowed opacity-60 hover:border-[var(--border-subtle)] hover:bg-gray-100': inboundMode === 'existing'}">
                      <el-icon class="text-2xl text-gray-400"><Plus /></el-icon>
                  </div>
                </el-upload>
                <div class="text-xs text-[var(--text-muted)] mt-1">支持 {{ systemStore.settings.upload.allowed_extensions.join('/') }} 格式，不超过 {{ systemStore.settings.upload.max_size_mb }}MB</div>
              </div>
            </div>
          </el-form-item>

          <el-form-item label="备注" prop="remarks" class="font-medium">
            <el-input v-model="form.remarks" type="textarea" rows="3" placeholder="请输入备注信息" class="!rounded-xl" />
          </el-form-item>

          <el-form-item class="mt-8">
            <el-button type="primary" :loading="loading" @click="handleSubmit" class="!rounded-xl !h-11 font-medium shadow-sm shadow-blue-500/20 px-8 text-base">确认入库</el-button>
            <el-button @click="handleCancel" class="!rounded-xl !h-11 font-medium px-8 text-base hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">取消</el-button>
          </el-form-item>
        </el-form>
    </div>

    <!-- 图片裁剪组件 -->
    <ImageCropper
      ref="imageCropperRef"
      upload-url="/upload/"
      method="POST"
      title="裁剪物品图片"
      :aspect-ratio="[1, 1]"
      @success="handleCropSuccess"
    />
  </div>
</template>
