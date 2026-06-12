<script setup lang="ts">
import type { Component } from 'vue';

withDefaults(
  defineProps<{
    icon?: Component;
    heading?: string;
    title?: string;
    text?: string;
  }>(),
  {
    icon: undefined,
    heading: undefined,
    title: undefined,
    text: undefined,
  },
);
</script>

<template>
  <div
    class="flex min-h-32 flex-col items-center justify-center border border-dashed border-[var(--yife-border)] bg-[var(--yife-surface)] p-4 text-center"
  >
    <component
      v-if="icon"
      :is="icon"
      class="mb-2 size-5 text-[var(--yife-text-muted)]"
      aria-hidden="true"
    />
    <p class="text-sm font-semibold">{{ heading || title }}</p>
    <p v-if="text" class="mt-1 max-w-sm text-xs text-[var(--yife-text-muted)]">{{ text }}</p>
    <div v-if="$slots.default" class="mt-3">
      <slot />
    </div>
  </div>
</template>
