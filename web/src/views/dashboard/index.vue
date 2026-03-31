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
  { title: '总物品种类', value: dashboardStore.stats.total_items, unit: '种', icon: 'Box', color: 'text-blue-500', bg: 'bg-blue-100', darkBg: 'rgba(59, 130, 246, 0.3)' },
  { title: '总库存价值', value: dashboardStore.stats.total_value, unit: '', icon: 'Coin', color: 'text-green-500', bg: 'bg-green-100', darkBg: 'rgba(16, 185, 129, 0.3)' },
  { title: '库存告警', value: dashboardStore.stats.low_stock_items, unit: '项', icon: 'Warning', color: 'text-red-500', bg: 'bg-red-100', darkBg: 'rgba(239, 68, 68, 0.3)' },
  { title: '近期出入库', value: dashboardStore.stats.recent_inbound + dashboardStore.stats.recent_outbound, unit: '次', icon: 'Sort', color: 'text-purple-500', bg: 'bg-purple-100', darkBg: 'rgba(168, 85, 247, 0.3)' }
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
  <div class="h-full max-w-7xl mx-auto flex flex-col gap-6">
    <!-- 头部区域 -->
    <div class="bg-[var(--card-bg)] p-6 rounded-2xl shadow-sm border border-[var(--border-subtle)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h1 class="text-2xl font-bold text-[var(--text-main)] font-display tracking-tight">控制面板</h1>
        <p class="text-sm text-[var(--text-muted)] mt-1">快速了解系统状态与库存概览</p>
      </div>
    </div>

    <!-- 核心数据卡片 -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 sm:gap-6">
      <div v-for="(item, index) in coreData" :key="index" class="bg-[var(--card-bg)] rounded-2xl p-5 shadow-sm hover:shadow-md transition-all duration-300 hover:-translate-y-1 border border-[var(--border-subtle)] relative overflow-hidden group">
        <!-- 装饰性背景图形 -->
        <div class="absolute -right-6 -top-6 w-24 h-24 rounded-full opacity-10 group-hover:scale-150 transition-transform duration-500 ease-out" :class="item.bg.replace('100', '500')"></div>
        
        <div class="flex items-center relative z-10">
          <div :class="[item.color, 'p-4 rounded-2xl mr-4 flex-shrink-0 flex items-center justify-center', isDark ? 'bg-opacity-20' : item.bg]" :style="isDark ? { backgroundColor: item.darkBg } : {}">
            <el-icon :size="26"><component :is="item.icon" /></el-icon>
          </div>
          <div class="min-w-0 flex-1">
            <div class="text-sm mb-1 truncate text-[var(--text-muted)] font-medium">{{ item.title }}</div>
            <div class="text-2xl sm:text-3xl font-bold truncate text-[var(--text-main)] font-display tracking-tight">
              <span v-if="item.title === '总库存价值'" class="text-lg mr-0.5">￥</span>
              {{ item.value }}
              <span v-if="item.unit" class="text-sm ml-1 font-medium text-[var(--text-muted)]">{{ item.unit }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <!-- 趋势图 -->
      <div class="xl:col-span-2 bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] p-6 transition-colors duration-300">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-bold text-lg text-[var(--text-main)] font-display">近期出入库趋势</h2>
        </div>
        <div ref="chartRef" class="h-64 sm:h-80 w-full"></div>
      </div>

      <!-- 最新操作记录 -->
      <div class="bg-[var(--card-bg)] rounded-2xl shadow-sm border border-[var(--border-subtle)] p-6 transition-colors duration-300 flex flex-col">
        <h2 class="font-bold text-lg text-[var(--text-main)] font-display mb-6">最新操作记录</h2>
        <div class="space-y-5 flex-1 overflow-y-auto custom-scrollbar pr-2">
          <div v-for="record in recentRecords" :key="record.id" class="flex items-center group">
            <div class="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 mr-4" :class="record.type === '入库' ? 'bg-green-100 text-green-600 dark:bg-green-900/30' : 'bg-orange-100 text-orange-600 dark:bg-orange-900/30'">
              <el-icon :size="18"><component :is="record.type === '入库' ? 'Bottom' : 'Top'" /></el-icon>
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-sm font-bold truncate text-[var(--text-main)] group-hover:text-blue-500 transition-colors">
                {{ record.item }}
              </div>
              <div class="text-xs mt-1 text-[var(--text-muted)] flex items-center gap-1">
                <el-icon><User /></el-icon>{{ record.operator }} <span class="mx-1">·</span> {{ record.time }}
              </div>
            </div>
            <div class="text-base font-bold ml-3 whitespace-nowrap" :class="record.type === '入库' ? 'text-green-500' : 'text-orange-500'">
              {{ record.type === '入库' ? '+' : '-' }}{{ record.qty }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
