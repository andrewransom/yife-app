<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { Archive, ChevronRight, PanelRightClose, Plus, Search, Settings } from 'lucide-vue-next';
import { storeToRefs } from 'pinia';
import { useRoute } from '#imports';
import { useProtectedAppBootstrap } from '~/composables/auth/useProtectedAppBootstrap';
import { useCampaignByIdQuery } from '~/composables/campaigns/useCampaignByIdQuery';
import { useCampaignMembershipSummaryQuery } from '~/composables/campaigns/useCampaignMembershipSummaryQuery';
import { useCampaignEntitySummariesQuery } from '~/composables/entities/useCampaignEntitySummariesQuery';
import { useEntityDetailQuery } from '~/composables/entities/useEntityDetailQuery';
import { useEntityStatusOptionsQuery } from '~/composables/entities/useEntityStatusOptionsQuery';
import { useEntityTypeOptionsQuery } from '~/composables/entities/useEntityTypeOptionsQuery';
import { useUiStore } from '~/stores/ui';

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
const selectedTypeKey = ref('all');
const selectedStatusKey = ref('');
const directorySearch = ref('');
const isCreateOpen = ref(false);
const isLoading = computed(
  () =>
    bootstrap.isInitializing.value ||
    campaignQuery.isPending.value ||
    campaignQuery.isFetching.value,
);
const isUnavailable = computed(
  () => bootstrap.isReady.value && !isLoading.value && !campaign.value,
);
const roleLabel = computed(
  () => membership.value?.role_keys[0] ?? campaign.value?.role_keys[0] ?? 'member',
);
const canCreateEntities = computed(() =>
  Boolean(
    membership.value?.role_keys.includes('owner') ||
    membership.value?.role_keys.includes('game_master'),
  ),
);
const overviewText = computed(
  () =>
    campaign.value?.description ||
    'Campaign overview, entity directories, notes, and sessions start in later milestones.',
);
const isBootstrapReady = bootstrap.isReady;
const isBootstrapError = bootstrap.isError;
const entityTypesQuery = useEntityTypeOptionsQuery(campaignId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(campaign.value)),
});
const entitySummariesQuery = useCampaignEntitySummariesQuery(campaignId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(campaign.value)),
});
const statusOptionsQuery = useEntityStatusOptionsQuery(campaignId, selectedTypeKey, {
  enabled: computed(() => selectedTypeKey.value !== 'all'),
});
const selectedEntityId = computed(() => uiStore.selectedEntityId);
const entityDetailQuery = useEntityDetailQuery(selectedEntityId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(selectedEntityId.value)),
});
const entityTypes = computed(() => entityTypesQuery.data.value ?? []);
const entitySummaries = computed(() => entitySummariesQuery.data.value ?? []);
const statusOptions = computed(() =>
  selectedTypeKey.value === 'all' ? [] : (statusOptionsQuery.data.value ?? []),
);
const selectedEntityDetail = computed(() => entityDetailQuery.data.value);
const isDirectoryLoading = computed(
  () => entitySummariesQuery.isPending.value || entityTypesQuery.isPending.value,
);
const isDetailLoading = computed(
  () => entityDetailQuery.isPending.value || entityDetailQuery.isFetching.value,
);
const selectedEntityMissing = computed(
  () =>
    Boolean(selectedEntityId.value) &&
    !entityDetailQuery.isPending.value &&
    !selectedEntityDetail.value,
);

watch(
  campaign,
  (value) => {
    if (value) {
      uiStore.selectCampaign(value.campaign_id);
    }
  },
  { immediate: true },
);

watch(selectedTypeKey, () => {
  selectedStatusKey.value = '';
});

watch(
  entitySummaries,
  (summaries) => {
    if (
      selectedEntityId.value &&
      !summaries.some((summary) => summary.entity_id === selectedEntityId.value)
    ) {
      uiStore.selectEntity(null);
    }
  },
  { immediate: true },
);

function openCreate() {
  if (!canCreateEntities.value) {
    return;
  }
  isCreateOpen.value = true;
}

function handleCreated(entityId: string) {
  uiStore.selectEntity(entityId);
  isCreateOpen.value = false;
}
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
      <CampaignSwitcher :current-campaign-id="campaignId" :enabled="isBootstrapReady" />
      <h1 class="min-w-0 flex-1 truncate text-sm font-semibold">
        {{ campaign?.name || 'Campaign workspace' }}
      </h1>
      <YIconButton :icon="Search" label="Search campaign" disabled />
      <YIconButton
        :icon="Plus"
        label="Create record"
        :disabled="!canCreateEntities"
        @click="openCreate"
      />
      <YIconButton
        :icon="Settings"
        label="Campaign settings"
        :to="`/campaigns/${campaignId}/settings`"
      />
      <YIconButton
        :icon="PanelRightClose"
        label="Toggle context panel"
        @click="uiStore.toggleRightPanel()"
      />
    </YCompactToolbar>

    <div v-if="isLoading" class="flex flex-1 items-center justify-center p-4">
      <YEmptyState heading="Opening campaign" text="Loading workspace context." />
    </div>

    <div v-else-if="isBootstrapError" class="flex flex-1 items-center justify-center p-4">
      <YEmptyState
        heading="Workspace setup failed"
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

    <div
      v-else
      class="grid flex-1 grid-cols-1 md:grid-cols-[17rem_1fr] xl:grid-cols-[17rem_1fr_20rem]"
    >
      <aside class="border-r border-[var(--yife-border)] bg-[var(--yife-surface)]">
        <div
          class="flex min-h-10 items-center justify-between border-b border-[var(--yife-border)] px-3"
        >
          <h2 class="text-sm font-semibold">Directory</h2>
          <YStatusBadge :label="roleLabel" tone="info" />
        </div>
        <EntityDirectoryShell
          :summaries="entitySummaries"
          :entity-types="entityTypes"
          :statuses="statusOptions"
          :selected-entity-id="selectedEntityId"
          :selected-type-key="selectedTypeKey"
          :status-key="selectedStatusKey"
          :search="directorySearch"
          :is-loading="isDirectoryLoading"
          :can-create="canCreateEntities"
          @update:selected-type-key="selectedTypeKey = $event"
          @update:status-key="selectedStatusKey = $event"
          @update:search="directorySearch = $event"
          @select="uiStore.selectEntity($event)"
          @create="openCreate"
        />
      </aside>

      <section class="min-w-0 bg-[var(--yife-canvas)] p-3">
        <YPanelSurface v-if="isCreateOpen" heading="Create Record">
          <EntityCreateForm
            :campaign-id="campaignId"
            :entity-types="entityTypes"
            :initial-type-key="selectedTypeKey"
            @created="handleCreated"
            @cancel="isCreateOpen = false"
          />
        </YPanelSurface>

        <EntityDetailShell
          v-else-if="selectedEntityId"
          :detail="selectedEntityDetail"
          :is-loading="isDetailLoading"
          :is-unavailable="selectedEntityMissing"
        />

        <YPanelSurface v-else heading="Campaign Overview">
          <div class="flex flex-wrap items-center gap-2 border-b border-[var(--yife-border)] pb-3">
            <YStatusBadge :label="campaign?.status_label || 'Active'" tone="success" />
            <YStatusBadge :label="roleLabel" tone="info" />
          </div>
          <div class="grid gap-3 pt-3 lg:grid-cols-[1fr_14rem]">
            <div>
              <h2 class="text-xl font-semibold">{{ campaign?.name }}</h2>
              <p class="mt-2 max-w-2xl text-sm leading-6 text-[var(--yife-text-muted)]">
                {{ overviewText }}
              </p>
            </div>
            <YEmptyState
              :icon="Archive"
              :heading="entitySummaries.length ? 'Select a record' : 'No workspace records'"
              :text="
                entitySummaries.length
                  ? 'Open a directory row to inspect its detail shell.'
                  : 'Create the first campaign record from the directory toolbar.'
              "
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
