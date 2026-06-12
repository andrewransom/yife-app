<script setup lang="ts">
import { Plus, Search, Settings } from 'lucide-vue-next';

const campaigns = [
  {
    id: 'ember-coast',
    name: 'Ember Coast',
    system: 'Fantasy campaign',
    updated: 'Updated today',
    count: '42 entities',
  },
  {
    id: 'iron-moons',
    name: 'Iron Moons',
    system: 'Science fantasy',
    updated: 'Updated yesterday',
    count: '19 entities',
  },
];
</script>

<template>
  <div class="mx-auto min-h-screen w-full max-w-6xl px-4 py-4">
    <header class="flex min-h-12 items-center justify-between border-b border-[var(--yife-border)]">
      <div>
        <h1 class="text-lg font-semibold">Campaign Home</h1>
        <p class="text-xs text-[var(--yife-text-muted)]">
          Select a campaign before entering the workspace.
        </p>
      </div>
      <div class="flex items-center gap-1">
        <YIconButton :icon="Search" label="Search campaigns" />
        <YIconButton :icon="Settings" label="Open user settings" />
        <YDenseButton color="primary">
          <Plus class="size-4" aria-hidden="true" />
          New
        </YDenseButton>
      </div>
    </header>

    <section class="grid gap-3 py-4 md:grid-cols-2">
      <NuxtLink
        v-for="campaign in campaigns"
        :key="campaign.id"
        :to="`/campaigns/${campaign.id}`"
        class="block border border-[var(--yife-border)] bg-[var(--yife-surface)] p-4 hover:bg-[var(--yife-surface-muted)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[var(--yife-focus)]"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h2 class="truncate text-base font-semibold">{{ campaign.name }}</h2>
            <p class="mt-1 text-sm text-[var(--yife-text-muted)]">{{ campaign.system }}</p>
          </div>
          <YStatusBadge label="Owner" tone="info" />
        </div>
        <dl class="mt-4 grid grid-cols-2 gap-2 text-xs text-[var(--yife-text-muted)]">
          <div>
            <dt class="font-medium text-[var(--yife-text)]">Records</dt>
            <dd>{{ campaign.count }}</dd>
          </div>
          <div>
            <dt class="font-medium text-[var(--yife-text)]">Activity</dt>
            <dd>{{ campaign.updated }}</dd>
          </div>
        </dl>
      </NuxtLink>
    </section>
  </div>
</template>
