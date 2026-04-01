<script setup lang="ts">
import { ref, reactive, nextTick } from 'vue'
import { Plus, Minus, RefreshLeft, RefreshRight } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import 'vue-cropper/dist/index.css'
import { VueCropper } from "vue-cropper"
import request from '@/api/request'

const props = defineProps<{
  uploadUrl: string
  method?: 'POST' | 'PUT'
  title?: string
  aspectRatio?: number[]
  autoCropWidth?: number
  autoCropHeight?: number
  fixedBox?: boolean
}>()

const emit = defineEmits<{
  (e: 'success', data: any): void
  (e: 'error', err: any): void
  (e: 'close'): void
}>()

// 裁剪相关状态
const visible = ref(false)
const cropperRef = ref()
const cropping = ref(false)
const cropperOptions = reactive({
  img: '',
  autoCrop: true,
  autoCropWidth: props.autoCropWidth || 200,
  autoCropHeight: props.autoCropHeight || 200,
  fixedBox: props.fixedBox !== undefined ? props.fixedBox : true,
  fixed: !!props.aspectRatio,
  fixedNumber: props.aspectRatio || [1, 1],
  centerBox: true,
  info: true,
  canScale: true,
  outputType: 'png'
})

const open = (file: File) => {
  const reader = new FileReader()
  reader.onload = (e) => {
    cropperOptions.img = e.target?.result as string
    visible.value = true
    nextTick(() => {
      if (cropperRef.value) {
        cropperRef.value.refresh()
      }
    })
  }
  reader.readAsDataURL(file)
}

const close = () => {
  visible.value = false
  emit('close')
}

// 裁剪操作函数
const changeScale = (num: number) => {
  cropperRef.value.changeScale(num || 1)
}

const rotateLeft = () => {
  cropperRef.value.rotateLeft()
}

const rotateRight = () => {
  cropperRef.value.rotateRight()
}

const handleCrop = () => {
  cropperRef.value.getCropBlob(async (blob: Blob) => {
    try {
      cropping.value = true
      const formData = new FormData()
      // 将 blob 转为 file
      const file = new File([blob], 'image.png', { type: 'image/png' })
      formData.append('file', file)

      const method = props.method || 'POST'
      const response: any = await request({
        url: props.uploadUrl,
        method: method,
        data: formData,
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })

      emit('success', response)
      visible.value = false
    } catch (error: any) {
      ElMessage.error(error.response?.data?.detail || '图片上传失败')
      emit('error', error)
    } finally {
      cropping.value = false
    }
  })
}

defineExpose({
  open,
  close
})
</script>

<template>
  <el-dialog
    v-model="visible"
    :title="title || '裁剪图片'"
    width="600px"
    append-to-body
    destroy-on-close
    class="cropper-dialog !rounded-2xl overflow-hidden"
  >
    <div class="flex flex-col items-center">
      <div class="w-full h-[400px] bg-gray-100 rounded-xl overflow-hidden mb-6">
        <vue-cropper
          ref="cropperRef"
          v-bind="cropperOptions"
        />
      </div>
      
      <div class="flex items-center gap-4 mb-6">
        <el-button-group>
          <el-button :icon="Plus" @click="changeScale(1)">放大</el-button>
          <el-button :icon="Minus" @click="changeScale(-1)">缩小</el-button>
        </el-button-group>
        <el-button-group>
          <el-button :icon="RefreshLeft" @click="rotateLeft">左旋转</el-button>
          <el-button :icon="RefreshRight" @click="rotateRight">右旋转</el-button>
        </el-button-group>
      </div>
      
      <div class="w-full pt-6 border-t border-[var(--border-subtle)] flex justify-end gap-3">
        <el-button @click="visible = false" class="!rounded-xl">取消</el-button>
        <el-button type="primary" :loading="cropping" @click="handleCrop" class="!rounded-xl !px-8">
          确认上传
        </el-button>
      </div>
    </div>
  </el-dialog>
</template>

<style scoped>
.cropper-dialog :deep(.el-dialog__body) {
  padding-top: 10px;
}
</style>
