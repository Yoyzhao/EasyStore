<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { useInventoryStore } from '@/store/inventory'
import { useUserStore } from '@/store/user'
import { useMetadataStore } from '@/store/metadata'
import { storeToRefs } from 'pinia'
import { uploadFile } from '@/api/request'

const router = useRouter()
const inventoryStore = useInventoryStore()
const userStore = useUserStore()
const metadataStore = useMetadataStore()

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
  price: [{ required: true, message: '请输入单价', trigger: 'blur' }]
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
  form.remarks = ''
  form.imageType = 'link'
  form.image = ''
  form.itemLink = ''
}

const handleImageChange = async (file: any) => {
  if (file.raw) {
    const isImage = file.raw.type === 'image/jpeg' || file.raw.type === 'image/png'
    const isLt2M = file.raw.size / 1024 / 1024 < 2

    if (!isImage) {
      ElMessage.error('上传图片只能是 JPG/PNG 格式!')
      return false
    }
    if (!isLt2M) {
      ElMessage.error('上传图片大小不能超过 2MB!')
      return false
    }
    
    try {
      const url = await uploadFile(file.raw)
      form.image = url
    } catch (e) {
      ElMessage.error('图片上传失败')
    }
  }
}

const handleItemSelect = (id: number) => {
  const item = inventoryStore.items.find(i => i.id === id)
  if (item) {
    form.name = item.name
    form.category = item.category
    form.brand = item.brand || ''
    form.unit = item.unit
    form.price = item.price
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
          low_stock_threshold: 10,
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
  <div class="h-full flex flex-col gap-4">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">物品入库</h1>
    </div>

    <el-card shadow="hover" class="border-none flex-1 overflow-auto" style="background-color: var(--el-bg-color-overlay);">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px" class="max-w-3xl">
          <el-form-item label="入库类型">
            <el-radio-group v-model="inboundMode" @change="handleModeChange">
              <el-radio-button label="new">新物品入库</el-radio-button>
              <el-radio-button label="existing">已有物品入库</el-radio-button>
            </el-radio-group>
          </el-form-item>

          <el-form-item v-if="inboundMode === 'existing'" label="选择物品" prop="itemId">
            <el-select v-model="form.itemId" filterable placeholder="搜索物品名称或ID" class="w-full" @change="handleItemSelect">
              <el-option v-for="item in inventoryStore.items" :key="item.id" :label="`${item.name} (${item.id})`" :value="item.id" />
            </el-select>
          </el-form-item>

          <el-form-item v-if="inboundMode === 'new'" label="物品名称" prop="name">
            <el-input v-model="form.name" placeholder="请输入物品名称" />
          </el-form-item>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="分类" prop="category">
                <el-select v-model="form.category" placeholder="请选择分类" filterable allow-create class="w-full" :disabled="inboundMode === 'existing'">
                  <el-option v-for="c in categories" :key="c.id" :label="c.name" :value="c.name" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="品牌" prop="brand">
                <el-select v-model="form.brand" placeholder="请选择品牌 (可选)" filterable allow-create clearable class="w-full" :disabled="inboundMode === 'existing'">
                  <el-option v-for="b in brands" :key="b.id" :label="b.name" :value="b.name" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="单位" prop="unit">
                <el-select v-model="form.unit" placeholder="请选择单位" filterable allow-create class="w-full" :disabled="inboundMode === 'existing'">
                  <el-option v-for="u in units" :key="u.id" :label="u.name" :value="u.name" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="入库数量" prop="quantity">
                <el-input-number v-model="form.quantity" :min="1" class="w-full" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="单价" prop="price">
                <el-input-number v-model="form.price" :min="0" :precision="2" class="w-full" :disabled="inboundMode === 'existing'" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="物品链接" prop="itemLink">
                <el-input v-model="form.itemLink" placeholder="请输入物品购买或参考链接" :disabled="inboundMode === 'existing'" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="物品图片">
            <div class="flex flex-col gap-2 w-full">
              <el-radio-group v-model="form.imageType" size="small" :disabled="inboundMode === 'existing'" @change="form.image = ''">
                <el-radio-button label="link">图片链接</el-radio-button>
                <el-radio-button label="file">本地上传</el-radio-button>
              </el-radio-group>
              
              <el-input 
                v-if="form.imageType === 'link'" 
                v-model="form.image" 
                placeholder="请输入图片URL链接" 
                :disabled="inboundMode === 'existing'" 
              />
              
              <div v-else class="flex flex-col gap-1">
                <el-upload
                  class="avatar-uploader"
                  action="#"
                  :show-file-list="false"
                  :auto-upload="false"
                  :on-change="handleImageChange"
                  :disabled="inboundMode === 'existing'"
                >
                  <div v-if="form.image" class="w-32 h-32 border border-gray-300 rounded overflow-hidden">
                    <img :src="form.image" class="w-full h-full object-cover" />
                  </div>
                  <div v-else class="w-32 h-32 border border-dashed border-gray-300 rounded flex items-center justify-center cursor-pointer hover:border-blue-500 transition-colors" :class="{'bg-gray-100 cursor-not-allowed opacity-60': inboundMode === 'existing'}">
                      <el-icon class="text-2xl text-gray-400"><Plus /></el-icon>
                  </div>
                </el-upload>
                <div class="text-xs text-gray-500">支持 jpg/png 格式，不超过 2MB</div>
              </div>
            </div>
          </el-form-item>

          <el-form-item label="备注" prop="remarks">
            <el-input v-model="form.remarks" type="textarea" rows="3" placeholder="请输入备注信息" />
          </el-form-item>

          <el-form-item>
            <el-button type="primary" :loading="loading" @click="handleSubmit">确认入库</el-button>
            <el-button @click="handleCancel">取消</el-button>
          </el-form-item>
        </el-form>
      </el-card>
  </div>
</template>
