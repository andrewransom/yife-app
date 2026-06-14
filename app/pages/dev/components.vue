<script setup lang="ts">
import { Eye, Lock, Plus, Search, Settings } from 'lucide-vue-next';

definePageMeta({
  layout: false,
});

const config = useRuntimeConfig();
const isEnabled = String(config.public.devComponentWorkbench) === 'true';
</script>

<template>
  <div v-if="isEnabled" class="mx-auto min-h-screen w-full max-w-6xl px-4 py-4">
    <header class="flex min-h-12 items-center justify-between border-b border-[var(--yife-border)]">
      <h1 class="text-lg font-semibold">Component Workbench</h1>
      <YStatusBadge label="Dev only" tone="warning" />
    </header>

    <div class="grid gap-4 py-4 lg:grid-cols-2">
      <YPanelSurface heading="Buttons">
        <div class="flex flex-wrap items-center gap-2">
          <YDenseButton color="primary">
            <Plus class="size-4" aria-hidden="true" />
            Create
          </YDenseButton>
          <YDenseButton variant="outline">Secondary</YDenseButton>
          <YIconButton :icon="Search" label="Search" />
          <YIconButton :icon="Settings" label="Settings" />
        </div>
      </YPanelSurface>

      <YPanelSurface heading="Badges">
        <div class="flex flex-wrap gap-2">
          <YStatusBadge label="Active" tone="success" />
          <YStatusBadge label="Blocked" tone="error" />
          <YVisibilityBadge visibility="shared" />
          <YVisibilityBadge visibility="gm_only" />
          <YVisibilityBadge visibility="private" />
        </div>
      </YPanelSurface>

      <YPanelSurface heading="Entity Rows">
        <YEntityRowSkeleton title="The Amber Road" caption="Storyline · active" active>
          <template #meta>
            <YVisibilityBadge visibility="shared" />
          </template>
        </YEntityRowSkeleton>
        <YEntityRowSkeleton title="Hidden Moon Compact" caption="Faction · private">
          <template #meta>
            <YVisibilityBadge visibility="private" />
          </template>
        </YEntityRowSkeleton>
      </YPanelSurface>

      <YPanelSurface heading="Form And Empty State">
        <div class="space-y-3">
          <YFormField label="Entity name" hint="Visual shell only. No persistence in M01.">
            <UInput placeholder="Name" size="sm" />
          </YFormField>
          <YEmptyState
            :icon="Eye"
            heading="Nothing selected"
            text="Select a row to inspect details."
          />
          <YEmptyState
            :icon="Lock"
            heading="Private content"
            text="Visibility-safe placeholders arrive with data access."
          />
        </div>
      </YPanelSurface>
    </div>
  </div>
  <main v-else class="flex min-h-screen items-center justify-center px-4 py-12">
    <section
      class="w-full max-w-md border border-[var(--yife-border)] bg-[var(--yife-surface)] p-5"
    >
      <p class="text-xs font-semibold uppercase text-[var(--yife-text-muted)]">404</p>
      <h1 class="mt-2 text-xl font-semibold">Page not found</h1>
      <p class="mt-2 text-sm text-[var(--yife-text-muted)]">Page not found</p>
      <YDenseButton class="mt-4" color="primary" to="/">Return home</YDenseButton>
    </section>
  </main>
</template>
