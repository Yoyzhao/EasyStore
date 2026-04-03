<script setup lang="ts">
import { ref } from 'vue'
import { ArrowUp, ArrowDown } from '@element-plus/icons-vue'

const currentYear = new Date().getFullYear()
const isCollapsed = ref(false)

const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value
}
</script>

<template>
  <footer class="py-2 text-center transition-all duration-300 relative group">
    <!-- 收起/展开按钮 -->
    <div class="flex justify-center mb-1">
      <button 
        @click="toggleCollapse"
        class="p-1 rounded-full hover:bg-gray-100 transition-colors text-gray-400 hover:text-gray-600 focus:outline-none"
        :title="isCollapsed ? '展开' : '收起'"
      >
        <el-icon class="text-xs">
          <component :is="isCollapsed ? ArrowUp : ArrowDown" />
        </el-icon>
      </button>
    </div>

    <!-- 内容区域 -->
    <div 
      class="overflow-hidden transition-all duration-300 ease-in-out"
      :style="{
        maxHeight: isCollapsed ? '0px' : '60px',
        opacity: isCollapsed ? '0' : '1',
        transform: isCollapsed ? 'translateY(10px)' : 'translateY(0)'
      }"
    >
      <span class="text-sm text-gray-400 select-none">
        © {{ currentYear }} EasyStore. AI大模型应用实施工作专班赵永永开发并提供技术支持。
      </span>
    </div>
  </footer>
</template>

<style scoped>
footer {
  /* 确保在内容较少时也能保持在底部 */
  margin-top: auto;
}
</style>
