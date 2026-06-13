<script setup lang="ts">
import type { Component } from 'vue';

withDefaults(
  defineProps<{
    icon: Component;
    label: string;
    tooltip?: string;
    to?: string;
    color?: 'primary' | 'neutral' | 'secondary' | 'success' | 'warning' | 'error';
    variant?: 'solid' | 'outline' | 'soft' | 'ghost';
    disabled?: boolean;
  }>(),
  {
    tooltip: undefined,
    to: undefined,
    color: 'neutral',
    variant: 'ghost',
    disabled: false,
  },
);
</script>

<template>
  <UTooltip :text="tooltip || label">
    <UButton
      :to="to"
      type="button"
      :aria-label="label"
      :color="color"
      :variant="variant"
      :disabled="disabled"
      size="sm"
      class="size-8 rounded-[4px] p-0"
    >
      <component :is="icon" class="size-4" aria-hidden="true" />
    </UButton>
  </UTooltip>
</template>
