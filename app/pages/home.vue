<script setup lang="ts">
import { computed, ref } from 'vue';
import { LogOut, Plus, RotateCw, Search, Settings } from 'lucide-vue-next';
import { useProtectedAppBootstrap } from '~/composables/auth/useProtectedAppBootstrap';
import { useSignOut } from '~/composables/auth/useSignOut';
import { useMyCampaignsQuery } from '~/composables/campaigns/useMyCampaignsQuery';

definePageMeta({
  auth: 'protected',
});

const bootstrap = useProtectedAppBootstrap();
const campaignsQuery = useMyCampaignsQuery({
  enabled: bootstrap.isReady,
});
const signOut = useSignOut();
const isCreateOpen = ref(false);
const signOutError = ref('');
const campaigns = computed(() => campaignsQuery.data.value ?? []);
const isLoadingCampaigns = computed(
  () => campaignsQuery.isPending.value || campaignsQuery.isFetching.value,
);
const campaignError = computed(() => campaignsQuery.error.value);
const isBootstrapInitializing = bootstrap.isInitializing;
const isBootstrapError = bootstrap.isError;

async function handleSignOut() {
  signOutError.value = '';

  try {
    await signOut();
  } catch (error) {
    signOutError.value = error instanceof Error ? error.message : 'Sign out failed.';
  }
}
</script>

<template>
  <div class="mx-auto min-h-screen w-full max-w-6xl px-4 py-4">
    <header class="flex min-h-12 items-center justify-between border-b border-[var(--yife-border)]">
      <div>
        <h1 class="text-lg font-semibold">Campaign Home</h1>
        <p class="text-xs text-[var(--yife-text-muted)]">
          Select or create a campaign before entering the workspace.
        </p>
      </div>
      <div class="flex items-center gap-1">
        <YIconButton :icon="Search" label="Search campaigns" disabled />
        <YIconButton :icon="Settings" label="Open user settings" disabled />
        <YDenseButton color="primary" @click="isCreateOpen = !isCreateOpen">
          <Plus class="size-4" aria-hidden="true" />
          New
        </YDenseButton>
        <YIconButton :icon="LogOut" label="Sign out" @click="handleSignOut" />
      </div>
    </header>

    <p v-if="signOutError" class="mt-3 text-sm text-[var(--yife-error)]">{{ signOutError }}</p>

    <section v-if="isCreateOpen" class="py-4">
      <YPanelSurface heading="Create Campaign">
        <CampaignCreateForm @created="isCreateOpen = false" />
      </YPanelSurface>
    </section>

    <section class="py-4">
      <YEmptyState
        v-if="isBootstrapInitializing"
        :icon="RotateCw"
        heading="Preparing your workspace"
        text="Profile and settings defaults are being verified."
      />

      <YEmptyState
        v-else-if="isBootstrapError"
        heading="Workspace setup failed"
        text="Profile and settings defaults could not be verified."
      >
        <YDenseButton @click="bootstrap.retry()">Retry</YDenseButton>
      </YEmptyState>

      <YEmptyState
        v-else-if="campaignError"
        heading="Campaigns unavailable"
        :text="campaignError instanceof Error ? campaignError.message : 'Campaigns could not load.'"
      />

      <div v-else-if="isLoadingCampaigns" class="grid gap-3 md:grid-cols-2">
        <YPanelSurface v-for="index in 4" :key="index" muted>
          <div class="h-28 animate-pulse bg-[var(--yife-surface-muted)]" />
        </YPanelSurface>
      </div>

      <YEmptyState
        v-else-if="campaigns.length === 0"
        heading="No campaigns yet"
        text="Create a campaign to open the first workspace shell."
      >
        <YDenseButton color="primary" @click="isCreateOpen = true">
          <Plus class="size-4" aria-hidden="true" />
          New campaign
        </YDenseButton>
      </YEmptyState>

      <div v-else class="grid gap-3 md:grid-cols-2">
        <CampaignCard
          v-for="campaign in campaigns"
          :key="campaign.campaign_id"
          :campaign="campaign"
        />
      </div>
    </section>
  </div>
</template>
