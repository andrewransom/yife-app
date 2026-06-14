<script setup lang="ts">
import { computed } from 'vue';
import { ChevronRight, PanelRightClose, Settings } from 'lucide-vue-next';
import { storeToRefs } from 'pinia';
import { useRoute } from '#imports';
import { useProtectedAppBootstrap } from '~/composables/auth/useProtectedAppBootstrap';
import { useCampaignByIdQuery } from '~/composables/campaigns/useCampaignByIdQuery';
import { useCampaignMembershipSummaryQuery } from '~/composables/campaigns/useCampaignMembershipSummaryQuery';
import { useUiStore } from '~/stores/ui';
import { canManageCampaignSettings } from '~/utils/campaign-settings';

definePageMeta({
  auth: 'protected',
});

const route = useRoute();
const uiStore = useUiStore();
const { isRightPanelCollapsed } = storeToRefs(uiStore);
const bootstrap = useProtectedAppBootstrap();
const campaignId = computed(() => String(route.params.campaignId || ''));

const campaignQuery = useCampaignByIdQuery(campaignId, {
  enabled: bootstrap.isReady,
});
const membershipQuery = useCampaignMembershipSummaryQuery(campaignId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(campaignQuery.data.value)),
});

const campaign = computed(() => campaignQuery.data.value);
const membership = computed(() => membershipQuery.data.value);
const isLoading = computed(
  () =>
    bootstrap.isInitializing.value ||
    campaignQuery.isPending.value ||
    campaignQuery.isFetching.value ||
    membershipQuery.isPending.value,
);
const isUnavailable = computed(
  () => bootstrap.isReady.value && !isLoading.value && !campaign.value,
);
const canManage = computed(() => canManageCampaignSettings(membership.value?.role_keys ?? []));
</script>

<template>
  <div class="flex min-h-screen flex-col">
    <YCompactToolbar label="Campaign settings actions">
      <NuxtLink
        to="/home"
        class="flex items-center gap-1 px-2 text-sm text-[var(--yife-text-muted)] hover:text-[var(--yife-text)]"
      >
        Home
        <ChevronRight class="size-3" aria-hidden="true" />
      </NuxtLink>
      <NuxtLink
        :to="`/campaigns/${campaignId}`"
        class="flex items-center gap-1 px-2 text-sm text-[var(--yife-text-muted)] hover:text-[var(--yife-text)]"
      >
        Campaign
        <ChevronRight class="size-3" aria-hidden="true" />
      </NuxtLink>
      <h1 class="min-w-0 flex-1 truncate text-sm font-semibold">
        {{ campaign?.name || 'Campaign settings' }}
      </h1>
      <YIconButton :icon="Settings" label="Campaign settings" disabled />
      <YIconButton
        :icon="PanelRightClose"
        label="Toggle context panel"
        @click="uiStore.toggleRightPanel()"
      />
    </YCompactToolbar>

    <div v-if="isLoading" class="flex flex-1 items-center justify-center p-4">
      <YEmptyState heading="Opening settings" text="Loading campaign settings context." />
    </div>

    <div v-else-if="bootstrap.isError.value" class="flex flex-1 items-center justify-center p-4">
      <YEmptyState
        heading="Settings setup failed"
        text="Profile and settings defaults could not be verified."
      >
        <YDenseButton @click="bootstrap.retry()">Retry</YDenseButton>
      </YEmptyState>
    </div>

    <div v-else-if="isUnavailable" class="flex flex-1 items-center justify-center p-4">
      <YEmptyState
        heading="Campaign unavailable"
        text="This campaign is unavailable or you do not have access."
      >
        <YDenseButton to="/home">Return home</YDenseButton>
      </YEmptyState>
    </div>

    <div v-else class="grid flex-1 grid-cols-1 xl:grid-cols-[minmax(0,1fr)_20rem]">
      <section class="min-w-0 bg-[var(--yife-canvas)] p-3">
        <div class="mb-3 flex flex-wrap items-center gap-2">
          <YStatusBadge
            :label="canManage ? 'campaign-wide editable' : 'read only'"
            :tone="canManage ? 'warning' : 'info'"
          />
          <YStatusBadge :label="campaign?.status_label || 'Planned'" tone="success" />
        </div>

        <div class="grid gap-3 2xl:grid-cols-2">
          <CampaignSettingsPresetImportPanel :campaign-id="campaignId" :can-manage="canManage" />
          <CampaignSettingsPaletteManager :campaign-id="campaignId" :can-manage="canManage" />
          <CampaignSettingsSymbolManager :campaign-id="campaignId" :can-manage="canManage" />
          <CampaignSettingsOptionManager
            class="2xl:col-span-2"
            :campaign-id="campaignId"
            :can-manage="canManage"
          />
          <CampaignSettingsQuickStatTemplateEditor
            :campaign-id="campaignId"
            template-kind="character"
            heading="Character Quick Stats"
            description="Compact character stat fields. No calculation or formula UI in MVP."
            :can-manage="canManage"
          />
          <CampaignSettingsQuickStatTemplateEditor
            :campaign-id="campaignId"
            template-kind="npc_statblock"
            heading="NPC / Encounter Statblock"
            description="Shared template for NPC and encounter statblock fields. GM-only in MVP."
            :can-manage="canManage"
          />
        </div>
      </section>

      <aside
        v-if="!isRightPanelCollapsed"
        class="hidden border-l border-[var(--yife-border)] bg-[var(--yife-surface)] p-3 xl:block"
      >
        <YPanelSurface heading="Settings Scope">
          <div class="space-y-3 text-sm text-[var(--yife-text-muted)]">
            <p>
              These controls are campaign-wide and apply to all members in this campaign.
            </p>
            <p>
              Status customization is intentionally out of scope for phase 6.
            </p>
            <p>
              Preset imports are safe to rerun. Existing keys are preserved instead of replaced.
            </p>
            <p v-if="!canManage">
              You can view these settings, but only campaign owners and Game Masters can change
              them.
            </p>
          </div>
        </YPanelSurface>
      </aside>
    </div>
  </div>
</template>
