<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as echarts from 'echarts'
import { useDark } from '@vueuse/core'

const isDark = useDark()
const chartRef = ref<HTMLElement | null>(null)
let chartInstance: echarts.ECharts | null = null

// 核心数据 Mock
const coreData = ref([
  { title: '总物品种类', value: 128, icon: 'Box', color: 'text-blue-500', bg: 'bg-blue-100', darkBg: 'rgba(59, 130, 246, 0.3)' },
  { title: '总库存数量', value: 3450, icon: 'Coin', color: 'text-green-500', bg: 'bg-green-100', darkBg: 'rgba(16, 185, 129, 0.3)' },
  { title: '库存告警', value: 12, icon: 'Warning', color: 'text-red-500', bg: 'bg-red-100', darkBg: 'rgba(239, 68, 68, 0.3)' },
  { title: '今日出入库', value: 45, icon: 'Sort', color: 'text-purple-500', bg: 'bg-purple-100', darkBg: 'rgba(168, 85, 247, 0.3)' }
])

// 最新操作记录 Mock
const recentRecords = ref([
  { id: 1, type: '入库', item: 'MacBook Pro 16', qty: 10, operator: 'Admin', time: '2023-10-27 10:30' },
  { id: 2, type: '出库', item: '联想显示器', qty: 5, operator: 'User01', time: '2023-10-27 09:15' },
  { id: 3, type: '入库', item: '罗技无线鼠标', qty: 50, operator: 'Admin', time: '2023-10-26 16:40' },
  { id: 4, type: '出库', item: '机械键盘', qty: 2, operator: 'User02', time: '2023-10-26 14:20' },
  { id: 5, type: '出库', item: 'MacBook Pro 16', qty: 1, operator: 'User01', time: '2023-10-26 11:05' },
])

const initChart = () => {
  if (!chartRef.value) return
  
  if (chartInstance) {
    chartInstance.dispose()
  }
  
  chartInstance = echarts.init(chartRef.value, isDark.value ? 'dark' : 'light')
  
  const option = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis'
    },
    legend: {
      top: 0,
      data: ['入库', '出库'],
      textStyle: {
        color: isDark.value ? '#E5E7EB' : '#374151'
      }
    },
    grid: {
      top: '15%',
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: ['10-21', '10-22', '10-23', '10-24', '10-25', '10-26', '10-27'],
      axisLabel: {
        color: isDark.value ? '#9CA3AF' : '#6B7280'
      }
    },
    yAxis: {
      type: 'value',
      axisLabel: {
        color: isDark.value ? '#9CA3AF' : '#6B7280'
      },
      splitLine: {
        lineStyle: {
          color: isDark.value ? '#374151' : '#E5E7EB'
        }
      }
    },
    series: [
      {
        name: '入库',
        type: 'line',
        smooth: true,
        data: [120, 132, 101, 134, 90, 230, 210],
        itemStyle: { color: '#10B981' }
      },
      {
        name: '出库',
        type: 'line',
        smooth: true,
        data: [220, 182, 191, 234, 290, 330, 310],
        itemStyle: { color: '#F59E0B' }
      }
    ]
  }
  
  chartInstance.setOption(option)
}

watch(isDark, () => {
  initChart()
})

const handleResize = () => {
  chartInstance?.resize()
}

onMounted(() => {
  initChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  chartInstance?.dispose()
})
</script>

<template>
  <div class="space-y-6">
    <!-- 核心数据卡片 -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <el-card v-for="(item, index) in coreData" :key="index" shadow="hover" class="border-none transition-colors duration-300" style="background-color: var(--el-bg-color-overlay);">
        <div class="flex items-center">
          <div :class="[item.color, 'p-4 rounded-lg mr-4 flex-shrink-0', !isDark ? item.bg : '']" :style="{ backgroundColor: isDark ? item.darkBg : '' }">
            <el-icon :size="24"><component :is="item.icon" /></el-icon>
          </div>
          <div>
            <div class="text-sm mb-1" style="color: var(--el-text-color-regular)">{{ item.title }}</div>
            <div class="text-2xl font-bold" style="color: var(--el-text-color-primary)">{{ item.value }}</div>
          </div>
        </div>
      </el-card>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- 趋势图 -->
      <el-card shadow="hover" class="lg:col-span-2 border-none transition-colors duration-300" style="background-color: var(--el-bg-color-overlay);">
        <template #header>
          <div class="font-medium" style="color: var(--el-text-color-primary)">近期出入库趋势</div>
        </template>
        <div ref="chartRef" class="h-80 w-full"></div>
      </el-card>

      <!-- 最新操作记录 -->
      <el-card shadow="hover" class="border-none transition-colors duration-300" style="background-color: var(--el-bg-color-overlay);">
        <template #header>
          <div class="font-medium" style="color: var(--el-text-color-primary)">最新操作记录</div>
        </template>
        <div class="space-y-4">
          <div v-for="record in recentRecords" :key="record.id" class="flex items-start pb-4 border-b last:border-0 last:pb-0" style="border-color: var(--el-border-color-light)">
            <el-tag :type="record.type === '入库' ? 'success' : 'warning'" size="small" class="mr-3 flex-shrink-0">
              {{ record.type }}
            </el-tag>
            <div class="flex-1 min-w-0">
              <div class="text-sm font-medium truncate" style="color: var(--el-text-color-primary)">
                {{ record.item }}
              </div>
              <div class="text-xs mt-1" style="color: var(--el-text-color-secondary)">
                {{ record.operator }} · {{ record.time }}
              </div>
            </div>
            <div class="text-sm font-bold ml-2" :class="record.type === '入库' ? 'text-green-500' : 'text-orange-500'">
              {{ record.type === '入库' ? '+' : '-' }}{{ record.qty }}
            </div>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>
