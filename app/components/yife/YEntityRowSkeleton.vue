<script setup lang="ts">
withDefaults(
  defineProps<{
    title?: string;
    caption?: string;
    active?: boolean;
  }>(),
  {
    title: 'Untitled entity',
    caption: 'No details yet',
    active: false,
  },
);
</script>

<template>
  <button
    type="button"
    class="grid min-h-11 w-full grid-cols-[2rem_1fr_auto] items-center gap-2 border-b border-[var(--yife-border)] px-2 text-left last:border-b-0 hover:bg-[var(--yife-surface-muted)]"
    :class="active ? 'bg-[var(--yife-surface-muted)]' : 'bg-transparent'"
  >
    <span
      class="flex size-7 items-center justify-center rounded-[4px] bg-[var(--yife-primary)] text-xs font-semibold text-[var(--yife-primary-text)]"
      aria-hidden="true"
    >
      {{ title.slice(0, 1).toUpperCase() }}
    </span>
    <span class="min-w-0">
      <span class="block truncate text-sm font-medium">{{ title }}</span>
      <span class="block truncate text-xs text-[var(--yife-text-muted)]">{{ caption }}</span>
    </span>
    <slot name="meta" />
  </button>
</template>
