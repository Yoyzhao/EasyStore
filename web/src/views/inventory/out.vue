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
  itemId: '',
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

const handleItemChange = (val: string) => {
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
  await formRef.value.validate((valid: boolean) => {
    if (valid) {
      loading.value = true
      try {
        inventoryStore.outbound({
          itemId: form.itemId,
          quantity: form.quantity,
          operator: form.operator,
          usage: form.usage,
          recipient: form.recipient,
          remark: form.remark
        })
        setTimeout(() => {
          loading.value = false
          ElMessage.success('出库成功')
          router.push('/inventory/list')
        }, 500)
      } catch (error: any) {
        loading.value = false
        ElMessage.error(error.message || '出库失败')
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
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">物品出库</h1>
    </div>

    <el-card shadow="hover" class="border-none flex-1 overflow-auto" style="background-color: var(--el-bg-color-overlay);">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px" class="max-w-3xl">
          <el-form-item label="选择物品" prop="itemId">
            <el-select 
              v-model="form.itemId" 
              filterable 
              placeholder="搜索物品名称/ID" 
              class="w-full"
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

          <el-form-item label="当前库存">
            <span class="text-gray-600 font-bold">{{ form.currentStock }}</span>
          </el-form-item>

          <el-form-item label="出库数量" prop="quantity">
            <el-input-number 
              v-model="form.quantity" 
              :min="1" 
              :max="form.currentStock > 0 ? form.currentStock : 1" 
              :disabled="form.currentStock === 0"
              class="w-full" 
            />
          </el-form-item>

          <el-form-item label="用途/去向" prop="usage">
            <el-select v-model="form.usage" placeholder="请选择用途/去向" filterable allow-create class="w-full" clearable>
              <el-option v-for="u in usages" :key="u.id" :label="u.name" :value="u.name" />
            </el-select>
          </el-form-item>

          <el-form-item label="领用人" prop="recipient">
            <el-input v-model="form.recipient" placeholder="请输入领用人姓名" />
          </el-form-item>

          <el-form-item label="备注" prop="remark">
            <el-input v-model="form.remark" type="textarea" placeholder="请输入备注信息（可选）" />
          </el-form-item>

          <el-form-item label="操作人">
             <el-input v-model="form.operator" disabled />
          </el-form-item>

          <el-form-item>
            <el-button type="primary" :loading="loading" @click="handleSubmit">确认出库</el-button>
            <el-button @click="handleCancel">取消</el-button>
          </el-form-item>
        </el-form>
      </el-card>
  </div>
</template>
