<template>
  <div class="h-full flex flex-col items-center justify-center">
    <h1 class="text-6xl font-bold text-gray-800">403</h1>
    <p class="text-xl text-gray-600 mt-4">抱歉，您没有权限访问该页面</p>
    <el-button type="primary" class="mt-8" @click="$router.push('/')">返回首页</el-button>
  </div>
</template>
