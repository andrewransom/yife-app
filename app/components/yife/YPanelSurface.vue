<script setup lang="ts">
import { computed, useAttrs } from 'vue';

defineOptions({
  inheritAttrs: false,
});

const props = withDefaults(
  defineProps<{
    heading?: string;
    title?: string;
    muted?: boolean;
  }>(),
  {
    heading: undefined,
    title: undefined,
    muted: false,
  },
);

const attrs = useAttrs();
const panelTitle = computed(() => {
  if (props.heading) {
    return props.heading;
  }

  if (props.title) {
    return props.title;
  }

  return typeof attrs.title === 'string' ? attrs.title : undefined;
});
</script>

<template>
  <section
    class="border border-[var(--yife-border)]"
    :class="props.muted ? 'bg-[var(--yife-surface-muted)]' : 'bg-[var(--yife-surface)]'"
  >
    <header
      v-if="panelTitle || $slots.actions"
      class="flex min-h-10 items-center gap-2 border-b border-[var(--yife-border)] px-3"
    >
      <h2 v-if="panelTitle" class="min-w-0 flex-1 truncate text-sm font-semibold">
        {{ panelTitle }}
      </h2>
      <div v-if="$slots.actions" class="flex shrink-0 items-center gap-1">
        <slot name="actions" />
      </div>
    </header>
    <div class="p-3">
      <slot />
    </div>
  </section>
</template>
