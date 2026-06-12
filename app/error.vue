<script setup lang="ts">
import { ArrowLeft } from 'lucide-vue-next';

defineProps<{
  error: {
    statusCode?: number;
    statusMessage?: string;
    message?: string;
  };
}>();

const handleError = () => clearError({ redirect: '/' });
</script>

<template>
  <main class="flex min-h-screen items-center justify-center px-4 py-12">
    <section
      class="w-full max-w-md border border-[var(--yife-border)] bg-[var(--yife-surface)] p-5"
    >
      <p class="text-xs font-semibold uppercase text-[var(--yife-text-muted)]">
        {{ error.statusCode || 500 }}
      </p>
      <h1 class="mt-2 text-xl font-semibold">
        {{ error.statusCode === 404 ? 'Page not found' : 'Something went wrong' }}
      </h1>
      <p class="mt-2 text-sm text-[var(--yife-text-muted)]">
        {{ error.statusMessage || error.message || 'The requested view is not available.' }}
      </p>
      <YDenseButton class="mt-4" color="primary" @click="handleError">
        <ArrowLeft class="size-4" aria-hidden="true" />
        Return home
      </YDenseButton>
    </section>
  </main>
</template>
