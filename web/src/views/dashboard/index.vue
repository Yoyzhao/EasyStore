<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import * as echarts from 'echarts'
import { useDark } from '@vueuse/core'
import { useDashboardStore } from '@/store/dashboard'
import { useInventoryStore } from '@/store/inventory'

const isDark = useDark()
const chartRef = ref<HTMLElement | null>(null)
let chartInstance: echarts.ECharts | null = null

const dashboardStore = useDashboardStore()
const inventoryStore = useInventoryStore()

// 核心数据
const coreData = computed(() => [
  { title: '总物品种类', value: dashboardStore.stats.total_items, icon: 'Box', color: 'text-blue-500', bg: 'bg-blue-100', darkBg: 'rgba(59, 130, 246, 0.3)' },
  { title: '总库存价值', value: dashboardStore.stats.total_value, icon: 'Coin', color: 'text-green-500', bg: 'bg-green-100', darkBg: 'rgba(16, 185, 129, 0.3)' },
  { title: '库存告警', value: dashboardStore.stats.low_stock_items, icon: 'Warning', color: 'text-red-500', bg: 'bg-red-100', darkBg: 'rgba(239, 68, 68, 0.3)' },
  { title: '近期出入库', value: dashboardStore.stats.recent_inbound + dashboardStore.stats.recent_outbound, icon: 'Sort', color: 'text-purple-500', bg: 'bg-purple-100', darkBg: 'rgba(168, 85, 247, 0.3)' }
])

const recentRecords = computed(() => {
  return inventoryStore.records.slice(0, 5).map(r => ({
    id: r.id,
    type: r.type === 'in' ? '入库' : '出库',
    item: r.item_name,
    qty: r.quantity,
    operator: r.operator,
    time: new Date(r.time).toLocaleString()
  }))
})

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
      data: dashboardStore.trend.dates,
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
        data: dashboardStore.trend.inbound,
        itemStyle: { color: '#10B981' }
      },
      {
        name: '出库',
        type: 'line',
        smooth: true,
        data: dashboardStore.trend.outbound,
        itemStyle: { color: '#F59E0B' }
      }
    ]
  }
  
  chartInstance.setOption(option)
}

watch(() => [isDark.value, dashboardStore.trend], () => {
  initChart()
}, { deep: true })

const handleResize = () => {
  chartInstance?.resize()
}

onMounted(async () => {
  await Promise.all([
    dashboardStore.fetchStats(),
    dashboardStore.fetchTrend(),
    inventoryStore.fetchRecords()
  ])
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
