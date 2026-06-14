<script setup lang="ts">
import { computed } from 'vue';

const labels = {
  shared: 'Shared',
  gm_only: 'GM',
  private: 'Private',
  character_owner_gm: 'Owner + GM',
} as const;

const tones = {
  shared: 'success',
  gm_only: 'warning',
  private: 'error',
  character_owner_gm: 'info',
} as const;

const props = withDefaults(
  defineProps<{
    visibility?: keyof typeof labels | string | null;
  }>(),
  {
    visibility: 'shared',
  },
);

const normalizedVisibility = computed(() => {
  if (
    props.visibility === 'gm_only' ||
    props.visibility === 'private' ||
    props.visibility === 'character_owner_gm'
  ) {
    return props.visibility;
  }

  return 'shared';
});
</script>

<template>
  <YStatusBadge :label="labels[normalizedVisibility]" :tone="tones[normalizedVisibility]" />
</template>
