<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { completeAuthCallback } from '~/composables/auth/useCompleteAuthCallback';

definePageMeta({
  auth: 'public',
});

const status = ref<'loading' | 'error'>('loading');
const message = ref('Finishing authentication.');

onMounted(async () => {
  const url = new URL(window.location.href);
  const errorDescription =
    url.searchParams.get('error_description') || url.hash.match(/error_description=([^&]+)/)?.[1];

  if (errorDescription) {
    status.value = 'error';
    message.value = decodeURIComponent(errorDescription.replaceAll('+', ' '));
    return;
  }

  try {
    await completeAuthCallback(url);
  } catch (error) {
    status.value = 'error';
    message.value = error instanceof Error ? error.message : 'Authentication callback failed.';
  }
});
</script>

<template>
  <main class="mx-auto flex min-h-screen w-full max-w-md items-center px-4 py-8">
    <section class="w-full border border-[var(--yife-border)] bg-[var(--yife-surface)] p-4">
      <p class="text-xs font-semibold uppercase text-[var(--yife-text-muted)]">Auth callback</p>
      <h1 class="mt-1 text-xl font-semibold">
        {{ status === 'loading' ? 'Signing you in' : 'Authentication problem' }}
      </h1>
      <p
        class="mt-2 text-sm"
        :class="status === 'error' ? 'text-[var(--yife-error)]' : 'text-[var(--yife-text-muted)]'"
      >
        {{ message }}
      </p>
      <YDenseButton v-if="status === 'error'" to="/auth/sign-in" class="mt-4">
        Back to sign in
      </YDenseButton>
    </section>
  </main>
</template>
