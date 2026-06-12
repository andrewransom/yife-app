<script setup lang="ts">
withDefaults(
  defineProps<{
    label: string;
    hint?: string;
    name?: string;
  }>(),
  {
    hint: undefined,
    name: undefined,
  },
);
</script>

<template>
  <UFormField :label="label" :help="hint" :name="name" class="space-y-1 text-sm">
    <slot />
  </UFormField>
</template>
