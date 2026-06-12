<script setup lang="ts">
withDefaults(
  defineProps<{
    label?: string;
  }>(),
  {
    label: 'Toolbar',
  },
);
</script>

<template>
  <div
    class="flex min-h-10 items-center gap-1 border-b border-[var(--yife-border)] bg-[var(--yife-surface)] px-2"
    role="toolbar"
    :aria-label="label"
  >
    <slot />
  </div>
</template>
