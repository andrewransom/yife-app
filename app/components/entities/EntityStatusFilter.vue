<script setup lang="ts">
import type { EntityStatusOption } from '~/composables/entities/types';

defineProps<{
  statuses: EntityStatusOption[];
  modelValue?: string;
}>();

const emit = defineEmits<{
  'update:modelValue': [value: string];
}>();
</script>

<template>
  <label class="block">
    <span class="sr-only">Status</span>
    <select
      class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
      :value="modelValue || ''"
      @change="emit('update:modelValue', ($event.target as HTMLSelectElement).value)"
    >
      <option value="">Any status</option>
      <option v-for="status in statuses" :key="status.key" :value="status.key">
        {{ status.label }}
      </option>
    </select>
  </label>
</template>
