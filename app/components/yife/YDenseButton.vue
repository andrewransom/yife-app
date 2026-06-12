<script setup lang="ts">
withDefaults(
  defineProps<{
    color?: 'primary' | 'neutral' | 'secondary' | 'success' | 'warning' | 'error';
    variant?: 'solid' | 'outline' | 'soft' | 'ghost';
    type?: 'button' | 'submit' | 'reset';
    disabled?: boolean;
    loading?: boolean;
    to?: string;
  }>(),
  {
    color: 'neutral',
    variant: 'soft',
    type: 'button',
    disabled: false,
    loading: false,
    to: undefined,
  },
);
</script>

<template>
  <UButton
    :to="to"
    :type="type"
    :color="color"
    :variant="variant"
    :disabled="disabled"
    :loading="loading"
    size="sm"
    class="min-h-8 gap-1.5 rounded-[4px] px-2.5 text-sm font-medium"
  >
    <slot />
  </UButton>
</template>
