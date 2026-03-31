<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useInventoryStore } from '@/store/inventory'
import { useMetadataStore } from '@/store/metadata'
import { storeToRefs } from 'pinia'

const router = useRouter()
const inventoryStore = useInventoryStore()
const metadataStore = useMetadataStore()

const { usages } = storeToRefs(metadataStore)

const formRef = ref()
const loading = ref(false)

const form = reactive({
  itemId: null as any,
  itemName: '',
  currentStock: 0,
  quantity: 1,
  usage: '',
  recipient: '',
  remark: '',
  operator: 'Admin' // Should come from user store
})

const rules = {
  itemId: [{ required: true, message: '请选择物品', trigger: 'change' }],
  quantity: [
    { required: true, message: '请输入数量', trigger: 'blur' },
    { 
      validator: (_rule: any, value: number, callback: any) => {
        if (value > form.currentStock) {
          callback(new Error('出库数量不能大于当前库存'))
        } else {
          callback()
        }
      }, 
      trigger: 'blur' 
    }
  ],
  usage: [{ required: true, message: '请选择用途/去向', trigger: 'change' }],
  recipient: [{ required: true, message: '请输入领用人', trigger: 'blur' }]
}

// Use items from store
const items = inventoryStore.items.map(item => ({
  id: item.id,
  name: item.name,
  stock: item.quantity
}))

const handleItemChange = (val: number) => {
  const item = items.find(i => i.id === val)
  if (item) {
    form.itemName = item.name
    form.currentStock = item.stock
    // Reset quantity validation if needed
    if (form.quantity > item.stock) {
      form.quantity = 1
    }
  }
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid: boolean) => {
    if (valid) {
      loading.value = true
      try {
        await inventoryStore.outbound({
          item_id: form.itemId,
          quantity: form.quantity,
          operator: form.operator,
          usage: form.usage,
          recipient: form.recipient,
          remark: form.usage ? `用途/去向: ${form.usage}${form.remark ? ' - ' + form.remark : ''}` : form.remark
        })
        ElMessage.success('出库成功')
        router.push('/inventory/list')
      } catch (error: any) {
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
    <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">物品出库</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">从库存中移除或领取物品</p>
      </div>
      <el-button @click="handleCancel" class="!rounded-xl !h-10 font-medium hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent px-6">返回列表</el-button>
    </div>

    <!-- 表单区域 -->
    <div class="flex-1 bg-[var(--card-bg)] p-8 rounded-2xl shadow-sm border border-[var(--border-subtle)] overflow-auto">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px" class="max-w-3xl mx-auto mt-4" label-position="top">
          <el-form-item label="选择物品" prop="itemId" class="font-medium">
            <el-select 
              v-model="form.itemId" 
              filterable 
              placeholder="搜索物品名称/ID" 
              class="w-full !rounded-xl"
              @change="handleItemChange"
            >
              <el-option 
                v-for="item in items" 
                :key="item.id" 
                :label="`${item.name} (库存: ${item.stock})`" 
                :value="item.id" 
              />
            </el-select>
          </el-form-item>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="当前库存" class="font-medium">
                <div class="h-10 flex items-center px-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl border border-[var(--border-subtle)] w-full">
                  <span class="text-lg font-bold text-blue-600">{{ form.currentStock }}</span>
                </div>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="出库数量" prop="quantity" class="font-medium">
                <el-input-number 
                  v-model="form.quantity" 
                  :min="1" 
                  :max="form.currentStock > 0 ? form.currentStock : 1" 
                  :disabled="form.currentStock === 0"
                  class="w-full !rounded-xl" 
                />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="用途/去向" prop="usage" class="font-medium">
                <el-select v-model="form.usage" placeholder="请选择用途/去向" filterable allow-create class="w-full !rounded-xl" clearable>
                  <el-option v-for="u in usages" :key="u.id" :label="u.name" :value="u.name" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="领用人" prop="recipient" class="font-medium">
                <el-input v-model="form.recipient" placeholder="请输入领用人姓名" class="!rounded-xl" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="备注" prop="remark" class="font-medium">
            <el-input v-model="form.remark" type="textarea" rows="3" placeholder="请输入备注信息（可选）" class="!rounded-xl" />
          </el-form-item>

          <el-form-item label="操作人" class="font-medium">
             <el-input v-model="form.operator" disabled class="!rounded-xl" />
          </el-form-item>

          <el-form-item class="mt-8">
            <el-button type="primary" :loading="loading" @click="handleSubmit" class="!rounded-xl !h-11 font-medium shadow-sm shadow-blue-500/20 px-8 text-base">确认出库</el-button>
            <el-button @click="handleCancel" class="!rounded-xl !h-11 font-medium px-8 text-base hover:bg-gray-100 dark:hover:bg-gray-800 border-transparent">取消</el-button>
          </el-form-item>
        </el-form>
    </div>
  </div>
</template>
