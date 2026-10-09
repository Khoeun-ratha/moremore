<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from './components/AppLayout.vue'
import AnimatedBackground from './components/AnimatedBackground.vue'

const route = useRoute()
const isPublicPage = computed(() => !!route.meta.hideLayout)
</script>

<template>
  <AnimatedBackground />
  <AppLayout v-if="!isPublicPage">
    <!-- Views can have several root nodes, so each is wrapped in one keyed div
         for the enter/leave animation to attach to. -->
    <router-view v-slot="{ Component, route: viewRoute }">
      <transition name="page" mode="out-in">
        <div :key="viewRoute.path" class="page-anim">
          <component :is="Component" />
        </div>
      </transition>
    </router-view>
  </AppLayout>
  <router-view v-else v-slot="{ Component, route: viewRoute }">
    <transition name="page" mode="out-in">
      <div :key="viewRoute.path" class="page-anim">
        <component :is="Component" />
      </div>
    </transition>
  </router-view>
</template>
