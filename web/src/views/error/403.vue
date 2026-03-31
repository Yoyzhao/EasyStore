<template>
  <div class="h-full flex flex-col items-center justify-center bg-[var(--bg-main)] px-4">
    <div class="bg-[var(--card-bg)]/80 backdrop-blur-xl p-12 rounded-2xl shadow-2xl border border-[var(--border-subtle)] max-w-lg w-full text-center">
      <h1 class="text-8xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-indigo-600 font-display mb-6">403</h1>
      <h2 class="text-2xl font-bold text-[var(--text-main)] mb-4">拒绝访问</h2>
      <p class="text-[var(--text-muted)] mb-8 leading-relaxed">
        抱歉，您没有权限访问该页面。这可能是因为您的会话已过期，或者您尝试访问了一个需要更高权限的区域。
      </p>
      <el-button type="primary" size="large" class="!rounded-xl !h-12 shadow-md shadow-blue-500/20 font-medium px-8 text-base" @click="$router.push('/')">
        返回首页
      </el-button>
    </div>
  </div>
</template>
