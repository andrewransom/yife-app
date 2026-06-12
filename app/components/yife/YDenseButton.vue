<script setup lang="ts">
withDefaults(
  defineProps<{
    color?: 'primary' | 'neutral' | 'secondary' | 'success' | 'warning' | 'error';
    variant?: 'solid' | 'outline' | 'soft' | 'ghost';
    type?: 'button' | 'submit' | 'reset';
    disabled?: boolean;
  }>(),
  {
    color: 'neutral',
    variant: 'soft',
    type: 'button',
    disabled: false,
  },
);
</script>

<template>
  <UButton
    :type="type"
    :color="color"
    :variant="variant"
    :disabled="disabled"
    size="sm"
    class="min-h-8 gap-1.5 rounded-[4px] px-2.5 text-sm font-medium"
  >
    <slot />
  </UButton>
</template>
