<script setup lang="ts">
import { Archive, ChevronRight, PanelRightClose, Plus, Search, Settings } from 'lucide-vue-next';
import { storeToRefs } from 'pinia';
import { useUiStore } from '~/stores/ui';

const route = useRoute();
const uiStore = useUiStore();
const { isRightPanelCollapsed } = storeToRefs(uiStore);

const campaignId = computed(() => String(route.params.campaignId || 'campaign'));

const entities = [
  ['Rook Ashvale', 'Character · active', 'shared'],
  ['The Brass Orchard', 'Location · discovered', 'shared'],
  ['Veyra of the Ninth Door', 'NPC · hidden agenda', 'gm_only'],
  ['Session 07 prep', 'Note · draft', 'private'],
] as const;
</script>

<template>
  <div class="flex min-h-screen flex-col">
    <YCompactToolbar label="Campaign actions">
      <NuxtLink
        to="/home"
        class="flex items-center gap-1 px-2 text-sm text-[var(--yife-text-muted)] hover:text-[var(--yife-text)]"
      >
        Home
        <ChevronRight class="size-3" aria-hidden="true" />
      </NuxtLink>
      <h1 class="min-w-0 flex-1 truncate text-sm font-semibold">Campaign · {{ campaignId }}</h1>
      <YIconButton :icon="Search" label="Search campaign" />
      <YIconButton :icon="Plus" label="Create record" />
      <YIconButton :icon="Settings" label="Campaign settings" />
      <YIconButton
        :icon="PanelRightClose"
        label="Toggle context panel"
        @click="uiStore.toggleRightPanel()"
      />
    </YCompactToolbar>

    <div class="grid flex-1 grid-cols-1 md:grid-cols-[17rem_1fr] xl:grid-cols-[17rem_1fr_20rem]">
      <aside class="border-r border-[var(--yife-border)] bg-[var(--yife-surface)]">
        <div
          class="flex min-h-10 items-center justify-between border-b border-[var(--yife-border)] px-3"
        >
          <h2 class="text-sm font-semibold">Directory</h2>
          <YStatusBadge label="M01" />
        </div>
        <div>
          <YEntityRowSkeleton
            v-for="([title, caption, visibility], index) in entities"
            :key="title"
            :title="title"
            :caption="caption"
            :active="index === 0"
          >
            <template #meta>
              <YVisibilityBadge :visibility="visibility" />
            </template>
          </YEntityRowSkeleton>
        </div>
      </aside>

      <section class="min-w-0 bg-[var(--yife-canvas)] p-3">
        <YPanelSurface heading="Record Detail Shell">
          <div class="flex flex-wrap items-center gap-2 border-b border-[var(--yife-border)] pb-3">
            <YStatusBadge label="Active" tone="success" />
            <YVisibilityBadge visibility="shared" />
          </div>
          <div class="grid gap-3 pt-3 lg:grid-cols-[1fr_14rem]">
            <div>
              <h2 class="text-xl font-semibold">Rook Ashvale</h2>
              <p class="mt-2 max-w-2xl text-sm leading-6 text-[var(--yife-text-muted)]">
                Detail content, rich text sections, mentions, and role-aware fields start in later
                milestones.
              </p>
            </div>
            <YEmptyState
              :icon="Archive"
              heading="No linked records"
              text="Relationships and backlinks arrive after the entity baseline."
            />
          </div>
        </YPanelSurface>
      </section>

      <aside
        v-if="!isRightPanelCollapsed"
        class="hidden border-l border-[var(--yife-border)] bg-[var(--yife-surface)] p-3 xl:block"
      >
        <YPanelSurface heading="Context" muted>
          <div class="space-y-3 text-sm text-[var(--yife-text-muted)]">
            <p>Session context, recent activity, backlinks, and related records will live here.</p>
            <YStatusBadge label="Placeholder" tone="info" />
          </div>
        </YPanelSurface>
      </aside>
    </div>
  </div>
</template>
