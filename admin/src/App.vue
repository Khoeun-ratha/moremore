<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from './components/AppLayout.vue'

const route = useRoute()
const isPublicPage = computed(() => !!route.meta.public)
</script>

<template>
  <AppLayout v-if="!isPublicPage">
    <router-view />
  </AppLayout>
  <router-view v-else />
</template>
