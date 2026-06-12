<script setup lang="ts">
withDefaults(
  defineProps<{
    label: string;
    tone?: 'neutral' | 'success' | 'warning' | 'error' | 'info';
  }>(),
  {
    tone: 'neutral',
  },
);
</script>

<template>
  <UBadge :color="tone" variant="soft" size="sm" class="rounded-[4px] font-medium">
    {{ label }}
  </UBadge>
</template>
