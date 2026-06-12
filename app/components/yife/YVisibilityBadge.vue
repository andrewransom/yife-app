<script setup lang="ts">
const labels = {
  shared: 'Shared',
  gm_only: 'GM',
  private: 'Private',
} as const;

const tones = {
  shared: 'success',
  gm_only: 'warning',
  private: 'error',
} as const;

const props = withDefaults(
  defineProps<{
    visibility?: keyof typeof labels;
  }>(),
  {
    visibility: 'shared',
  },
);
</script>

<template>
  <YStatusBadge :label="labels[props.visibility]" :tone="tones[props.visibility]" />
</template>
