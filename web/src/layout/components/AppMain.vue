<script setup lang="ts">
import { useRoute } from 'vue-router'

const route = useRoute()
</script>

<template>
  <section class="p-6 h-full transition-colors duration-300" style="background-color: var(--el-bg-color-page); color: var(--el-text-color-primary);">
    <router-view v-slot="{ Component }">
      <component :is="Component" :key="route.fullPath" />
    </router-view>
  </section>
</template>

<style scoped>
/* Removed transition styles as they are no longer used */
</style>
