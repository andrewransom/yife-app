<script setup lang="ts">
import type { EntityTypeOption } from '~/composables/entities/types';

defineProps<{
  entityTypes: EntityTypeOption[];
  modelValue: string;
}>();

const emit = defineEmits<{
  'update:modelValue': [value: string];
}>();
</script>

<template>
  <div class="flex flex-wrap gap-1" role="group" aria-label="Entity type">
    <button
      type="button"
      class="h-7 rounded-[4px] border px-2 text-xs font-medium"
      :class="
        modelValue === 'all'
          ? 'border-[var(--yife-primary)] bg-[var(--yife-primary)] text-[var(--yife-primary-text)]'
          : 'border-[var(--yife-border)] bg-[var(--yife-surface)] text-[var(--yife-text)]'
      "
      @click="emit('update:modelValue', 'all')"
    >
      All
    </button>
    <button
      v-for="type in entityTypes"
      :key="type.entity_type_key"
      type="button"
      class="h-7 rounded-[4px] border px-2 text-xs font-medium"
      :class="
        modelValue === type.entity_type_key
          ? 'border-[var(--yife-primary)] bg-[var(--yife-primary)] text-[var(--yife-primary-text)]'
          : 'border-[var(--yife-border)] bg-[var(--yife-surface)] text-[var(--yife-text)]'
      "
      @click="emit('update:modelValue', type.entity_type_key)"
    >
      {{ type.plural_label }}
    </button>
  </div>
</template>
