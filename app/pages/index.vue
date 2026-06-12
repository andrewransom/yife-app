<script setup lang="ts">
import { BookOpen, LogIn, Sparkles } from 'lucide-vue-next';
</script>

<template>
  <div class="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-4 py-4">
    <header class="flex min-h-12 items-center justify-between border-b border-[var(--yife-border)]">
      <div class="flex items-center gap-2">
        <div
          class="flex size-8 items-center justify-center rounded-[4px] bg-[var(--yife-primary)] text-[var(--yife-primary-text)]"
        >
          <BookOpen class="size-4" aria-hidden="true" />
        </div>
        <span class="text-sm font-semibold">Yife.app</span>
      </div>
      <YDenseButton>
        <LogIn class="size-4" aria-hidden="true" />
        Sign in
      </YDenseButton>
    </header>

    <section class="grid flex-1 items-center gap-6 py-8 md:grid-cols-[1fr_24rem]">
      <div class="max-w-2xl">
        <p class="text-xs font-semibold uppercase text-[var(--yife-text-muted)]">
          Campaign knowledge
        </p>
        <h1 class="mt-2 text-3xl font-semibold tracking-normal md:text-4xl">Yife.app</h1>
        <p class="mt-3 text-base leading-7 text-[var(--yife-text-muted)]">
          A compact workspace for tabletop campaign notes, entities, sessions, and role-aware
          visibility.
        </p>
        <div class="mt-5 flex flex-wrap gap-2">
          <YDenseButton color="primary">
            <Sparkles class="size-4" aria-hidden="true" />
            Create campaign
          </YDenseButton>
          <YDenseButton variant="outline">Open existing campaign</YDenseButton>
        </div>
      </div>

      <YPanelSurface heading="Workspace Preview">
        <div class="space-y-2">
          <YEntityRowSkeleton title="Blackwater Crossing" caption="Location · shared" active>
            <template #meta>
              <YVisibilityBadge visibility="shared" />
            </template>
          </YEntityRowSkeleton>
          <YEntityRowSkeleton title="Mara Voss" caption="NPC · GM notes pending">
            <template #meta>
              <YVisibilityBadge visibility="gm_only" />
            </template>
          </YEntityRowSkeleton>
          <YEntityRowSkeleton title="Session 04" caption="Recap · private draft">
            <template #meta>
              <YVisibilityBadge visibility="private" />
            </template>
          </YEntityRowSkeleton>
        </div>
      </YPanelSurface>
    </section>
  </div>
</template>
