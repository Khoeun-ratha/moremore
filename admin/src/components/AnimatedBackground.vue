<script setup lang="ts">
// Fixed, decorative backdrop shared by every page (mounted once in App.vue).
// Pure CSS animation on transform/opacity only, so it stays on the GPU and
// never triggers layout. Freezes under prefers-reduced-motion.
const sparkles = Array.from({ length: 14 }, (_, i) => ({
  left: `${(i * 61.8 * 7.3) % 100}%`,
  delay: `${-(i * 2.7) % 24}s`,
  duration: `${18 + (i % 5) * 4}s`,
  size: `${4 + (i % 3) * 2}px`,
}))
</script>

<template>
  <div class="bg" aria-hidden="true">
    <div class="bg__blob bg__blob--violet" />
    <div class="bg__blob bg__blob--sky" />
    <div class="bg__blob bg__blob--pink" />
    <div class="bg__blob bg__blob--mint" />
    <div class="bg__grid" />
    <span
      v-for="(s, i) in sparkles"
      :key="i"
      class="bg__sparkle"
      :style="{ left: s.left, width: s.size, height: s.size, animationDelay: s.delay, animationDuration: s.duration }"
    />
  </div>
</template>

<style scoped>
.bg {
  position: fixed;
  inset: 0;
  z-index: -1;
  overflow: hidden;
  pointer-events: none;
  background: linear-gradient(180deg, #f7f5ff 0%, #f8f7fc 50%, #f3f1fb 100%);
}

.bg__blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(60px);
  opacity: 0.55;
  will-change: transform;
}

.bg__blob--violet {
  width: 52vmax;
  height: 52vmax;
  top: -18vmax;
  left: -14vmax;
  background: radial-gradient(circle, rgba(108, 76, 240, 0.55), transparent 65%);
  animation: drift-a 26s ease-in-out infinite alternate;
}

.bg__blob--sky {
  width: 44vmax;
  height: 44vmax;
  top: 10vh;
  right: -16vmax;
  background: radial-gradient(circle, rgba(41, 182, 246, 0.45), transparent 65%);
  animation: drift-b 32s ease-in-out infinite alternate;
}

.bg__blob--pink {
  width: 46vmax;
  height: 46vmax;
  bottom: -20vmax;
  left: 8vw;
  background: radial-gradient(circle, rgba(240, 108, 200, 0.4), transparent 65%);
  animation: drift-c 29s ease-in-out infinite alternate;
}

.bg__blob--mint {
  width: 34vmax;
  height: 34vmax;
  bottom: -10vmax;
  right: 4vw;
  background: radial-gradient(circle, rgba(31, 174, 107, 0.35), transparent 65%);
  animation: drift-a 35s ease-in-out infinite alternate-reverse;
}

.bg__grid {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(rgba(108, 76, 240, 0.09) 1px, transparent 1px);
  background-size: 26px 26px;
  mask-image: radial-gradient(ellipse at center, #000 30%, transparent 80%);
}

.bg__sparkle {
  position: absolute;
  bottom: -20px;
  border-radius: 50%;
  background: rgba(108, 76, 240, 0.18);
  animation-name: rise;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
}

@keyframes drift-a {
  0% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(8vw, 6vh) scale(1.08); }
  100% { transform: translate(-4vw, 10vh) scale(0.96); }
}

@keyframes drift-b {
  0% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(-10vw, 8vh) scale(1.1); }
  100% { transform: translate(-4vw, -6vh) scale(0.95); }
}

@keyframes drift-c {
  0% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(12vw, -8vh) scale(1.05); }
  100% { transform: translate(4vw, -2vh) scale(1.1); }
}

@keyframes rise {
  0% { transform: translate(0, 0); opacity: 0; }
  10% { opacity: 1; }
  90% { opacity: 1; }
  100% { transform: translate(24px, -105vh); opacity: 0; }
}

@media (prefers-reduced-motion: reduce) {
  .bg__blob,
  .bg__sparkle {
    animation: none;
  }
  .bg__sparkle {
    display: none;
  }
}
</style>
