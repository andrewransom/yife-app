<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import {
  Archive,
  ChevronRight,
  List,
  PanelRightClose,
  Plus,
  Search,
  Settings,
  Timer,
} from 'lucide-vue-next';
import { storeToRefs } from 'pinia';
import { useRoute } from '#imports';
import { useCurrentUser } from '~/composables/auth/useCurrentUser';
import { useProtectedAppBootstrap } from '~/composables/auth/useProtectedAppBootstrap';
import { useCampaignByIdQuery } from '~/composables/campaigns/useCampaignByIdQuery';
import { useCampaignRoleViewContext } from '~/composables/campaigns/useCampaignRoleViewContext';
import { useCurrentSessionQuery } from '~/composables/entities/useCurrentSessionQuery';
import { useCampaignEntitySummariesQuery } from '~/composables/entities/useCampaignEntitySummariesQuery';
import { useEncountersQuery } from '~/composables/entities/useEncountersQuery';
import { useEntityDetailQuery } from '~/composables/entities/useEntityDetailQuery';
import { useEntityStatusOptionsQuery } from '~/composables/entities/useEntityStatusOptionsQuery';
import { useEntityTypeOptionsQuery } from '~/composables/entities/useEntityTypeOptionsQuery';
import { useSessionsQuery } from '~/composables/entities/useSessionsQuery';
import { useStorylinesQuery } from '~/composables/entities/useStorylinesQuery';
import { useUiStore } from '~/stores/ui';

definePageMeta({
  auth: 'protected',
});

const route = useRoute();
const uiStore = useUiStore();
const { activeViewPreference, isRightPanelCollapsed, selectedEntityId } = storeToRefs(uiStore);
const bootstrap = useProtectedAppBootstrap();
const currentUser = useCurrentUser();

const campaignId = computed(() => String(route.params.campaignId || ''));
const campaignQuery = useCampaignByIdQuery(campaignId, {
  enabled: bootstrap.isReady,
});
const roleViewContext = useCampaignRoleViewContext(campaignId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(campaignQuery.data.value)),
});

const campaign = computed(() => campaignQuery.data.value);
const membership = computed(() => roleViewContext.membershipQuery.data.value);
const selectedTypeKey = ref('all');
const selectedStatusKey = ref('');
const directorySearch = ref('');
const storylineType = ref('');
const storylineCategoryLabel = ref('');
const storylinePriorityLabel = ref('');
const storylineMajorMode = ref<'all' | 'major' | 'minor'>('all');
const encounterTypeLabel = ref('');
const relatedSessionEntityId = ref('');
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
const roleLabel = computed(() => {
  const roles = membership.value?.role_keys ?? campaign.value?.role_keys ?? [];

  if (roleViewContext.workspaceMode.value === 'mixed') {
    return 'gm + player';
  }

  if (roles.includes('owner')) {
    return 'owner';
  }

  if (roles.includes('game_master')) {
    return 'gm';
  }

  return roles[0] ?? 'member';
});
const activeViewLabel = computed(() =>
  roleViewContext.activeRoleView.value === 'gm' ? 'GM view' : 'Player view',
);
const canCreateEntities = computed(() => Boolean(roleViewContext.isGameMaster.value));
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
const currentSessionQuery = useCurrentSessionQuery(campaignId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(campaign.value)),
  previewAsPlayer: computed(() => roleViewContext.isPlayerPreview.value),
});
const entitySummariesQuery = useCampaignEntitySummariesQuery(campaignId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(campaign.value)),
});
const sessionsQuery = useSessionsQuery(
  campaignId,
  {
    statusKey: selectedStatusKey,
    search: directorySearch,
    includeCancelled: computed(() => selectedStatusKey.value === 'cancelled'),
  },
  {
    enabled: computed(() => bootstrap.isReady.value && Boolean(campaign.value)),
    previewAsPlayer: computed(() => roleViewContext.isPlayerPreview.value),
  },
);
const storylinesQuery = useStorylinesQuery(
  campaignId,
  {
    statusKey: selectedStatusKey,
    search: directorySearch,
    storylineType,
    categoryLabel: storylineCategoryLabel,
    priorityLabel: storylinePriorityLabel,
    majorMode: storylineMajorMode,
  },
  {
    enabled: computed(() => bootstrap.isReady.value && Boolean(campaign.value)),
    previewAsPlayer: computed(() => roleViewContext.isPlayerPreview.value),
  },
);
const encountersQuery = useEncountersQuery(
  campaignId,
  {
    statusKey: selectedStatusKey,
    search: directorySearch,
    encounterTypeLabel,
    relatedSessionEntityId,
  },
  {
    enabled: computed(() => bootstrap.isReady.value && Boolean(campaign.value)),
    previewAsPlayer: computed(() => roleViewContext.isPlayerPreview.value),
  },
);
const statusOptionsQuery = useEntityStatusOptionsQuery(campaignId, selectedTypeKey, {
  enabled: computed(() => selectedTypeKey.value !== 'all'),
});
const entityDetailQuery = useEntityDetailQuery(selectedEntityId, {
  enabled: computed(() => bootstrap.isReady.value && Boolean(selectedEntityId.value)),
  previewAsPlayer: computed(() => roleViewContext.isPlayerPreview.value),
});
const entityTypes = computed(() => entityTypesQuery.data.value ?? []);
const entitySummaries = computed(() => entitySummariesQuery.data.value ?? []);
const directorySummaries = computed(() => {
  if (selectedTypeKey.value === 'session') {
    return sessionsQuery.data.value ?? [];
  }

  if (selectedTypeKey.value === 'storyline') {
    return storylinesQuery.data.value ?? [];
  }

  if (selectedTypeKey.value === 'encounter') {
    return encountersQuery.data.value ?? [];
  }

  return entitySummaries.value;
});
const statusOptions = computed(() =>
  selectedTypeKey.value === 'all' ? [] : (statusOptionsQuery.data.value ?? []),
);
const selectedEntityDetail = computed(() => entityDetailQuery.data.value);
const currentSession = computed(() => currentSessionQuery.data.value);
const isDirectoryLoading = computed(
  () =>
    entityTypesQuery.isPending.value ||
    (selectedTypeKey.value === 'session'
      ? sessionsQuery.isPending.value
      : selectedTypeKey.value === 'storyline'
        ? storylinesQuery.isPending.value
        : selectedTypeKey.value === 'encounter'
          ? encountersQuery.isPending.value
          : entitySummariesQuery.isPending.value),
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
const isSelectedEntityCharacterController = computed(
  () =>
    Boolean(selectedEntityDetail.value?.controlling_user_id) &&
    selectedEntityDetail.value?.controlling_user_id === currentUser.value?.id,
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
  storylineType.value = '';
  storylineCategoryLabel.value = '';
  storylinePriorityLabel.value = '';
  storylineMajorMode.value = 'all';
  encounterTypeLabel.value = '';
  relatedSessionEntityId.value = '';
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
  uiStore.setActiveViewPreference('detail');
  isCreateOpen.value = false;
}

function handleSelectEntity(entityId: string) {
  uiStore.selectEntity(entityId);
  uiStore.setActiveViewPreference('detail');
}

function openTimelineView() {
  uiStore.setActiveViewPreference('timeline');
}

function openDirectoryView() {
  uiStore.setActiveViewPreference(selectedEntityId.value ? 'detail' : 'directory');
}

function handleTimelineOpen(entityId: string) {
  uiStore.selectEntity(entityId);
  uiStore.setActiveViewPreference('detail');
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
      <div class="flex items-center gap-1">
        <YIconButton
          :icon="List"
          label="Open records"
          :color="activeViewPreference === 'timeline' ? 'neutral' : 'primary'"
          :variant="activeViewPreference === 'timeline' ? 'ghost' : 'soft'"
          @click="openDirectoryView"
        />
        <YIconButton
          :icon="Timer"
          label="Open timeline"
          :color="activeViewPreference === 'timeline' ? 'primary' : 'neutral'"
          :variant="activeViewPreference === 'timeline' ? 'soft' : 'ghost'"
          @click="openTimelineView"
        />
      </div>
      <select
        v-if="roleViewContext.workspaceMode.value === 'mixed'"
        :value="roleViewContext.selectedViewPreference.value"
        class="h-8 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        @change="
          roleViewContext.setSelectedViewPreference(
            ($event.target as HTMLSelectElement).value as 'gm' | 'player',
          )
        "
      >
        <option value="gm">GM view</option>
        <option value="player">Player view</option>
      </select>
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
          <div class="flex items-center gap-2">
            <YStatusBadge :label="roleLabel" tone="info" />
            <YStatusBadge
              :label="activeViewLabel"
              :tone="roleViewContext.isPlayerPreview.value ? 'warning' : 'success'"
            />
          </div>
        </div>
        <EntityDirectoryShell
          :summaries="directorySummaries"
          :entity-types="entityTypes"
          :statuses="statusOptions"
          :selected-entity-id="selectedEntityId"
          :selected-type-key="selectedTypeKey"
          :status-key="selectedStatusKey"
          :search="directorySearch"
          :storyline-type="storylineType"
          :storyline-category-label="storylineCategoryLabel"
          :storyline-priority-label="storylinePriorityLabel"
          :storyline-major-mode="storylineMajorMode"
          :encounter-type-label="encounterTypeLabel"
          :related-session-entity-id="relatedSessionEntityId"
          :is-loading="isDirectoryLoading"
          :can-create="canCreateEntities"
          @update:selected-type-key="selectedTypeKey = $event"
          @update:status-key="selectedStatusKey = $event"
          @update:search="directorySearch = $event"
          @update:storyline-type="storylineType = $event"
          @update:storyline-category-label="storylineCategoryLabel = $event"
          @update:storyline-priority-label="storylinePriorityLabel = $event"
          @update:storyline-major-mode="storylineMajorMode = $event"
          @update:encounter-type-label="encounterTypeLabel = $event"
          @update:related-session-entity-id="relatedSessionEntityId = $event"
          @select="handleSelectEntity"
          @create="openCreate"
        />
      </aside>

      <section class="min-w-0 bg-[var(--yife-canvas)] p-3">
        <YPanelSurface v-if="isCreateOpen" heading="Create Record">
          <EntityCreateForm
            :campaign-id="campaignId"
            :entity-types="entityTypes"
            :initial-type-key="selectedTypeKey"
            :current-session-entity-id="currentSession?.session_entity_id ?? null"
            @created="handleCreated"
            @cancel="isCreateOpen = false"
          />
        </YPanelSurface>

        <EntityDetailShell
          v-else-if="selectedEntityId && activeViewPreference !== 'timeline'"
          :detail="selectedEntityDetail"
          :is-loading="isDetailLoading"
          :is-unavailable="selectedEntityMissing"
          :active-role-view="roleViewContext.activeRoleView.value"
          :is-player-preview="roleViewContext.isPlayerPreview.value"
          :show-inline-context="isRightPanelCollapsed"
        />

        <TimelineEventListPanel
          v-else-if="activeViewPreference === 'timeline'"
          :campaign-id="campaignId"
          heading="Timeline"
          :active-role-view="roleViewContext.activeRoleView.value"
          :is-player-preview="roleViewContext.isPlayerPreview.value"
          @open="handleTimelineOpen"
        />

        <YPanelSurface v-else heading="Campaign Overview">
          <div class="flex flex-wrap items-center gap-2 border-b border-[var(--yife-border)] pb-3">
            <YStatusBadge :label="campaign?.status_label || 'Active'" tone="success" />
            <YStatusBadge :label="roleLabel" tone="info" />
            <YStatusBadge
              :label="activeViewLabel"
              :tone="roleViewContext.isPlayerPreview.value ? 'warning' : 'success'"
            />
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
          <div class="mt-3 grid gap-3 xl:grid-cols-[minmax(0,18rem)_minmax(0,1fr)]">
            <CurrentSessionPanel
              :campaign-id="campaignId"
              :active-role-view="roleViewContext.activeRoleView.value"
              :is-player-preview="roleViewContext.isPlayerPreview.value"
            />
            <CampaignActivityPanel
              :campaign-id="campaignId"
              :active-role-view="roleViewContext.activeRoleView.value"
              :is-player-preview="roleViewContext.isPlayerPreview.value"
            />
          </div>
          <CampaignNotesPanel :campaign-id="campaignId" class="mt-3" />
        </YPanelSurface>
      </section>

      <aside
        v-if="!isRightPanelCollapsed"
        class="hidden border-l border-[var(--yife-border)] bg-[var(--yife-surface)] p-3 xl:block"
      >
        <div v-if="selectedEntityDetail" class="space-y-3">
          <EntityNotesWidget
            :entity-id="selectedEntityDetail.entity_id"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
            :is-character-controller="isSelectedEntityCharacterController"
          />
          <EntityRelationshipsPanel
            :campaign-id="selectedEntityDetail.campaign_id"
            :entity-id="selectedEntityDetail.entity_id"
            :can-manage="selectedEntityDetail.can_manage_visibility"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
            :is-character-controller="isSelectedEntityCharacterController"
          />
          <EntityRelatedRecordsPanel
            :entity-id="selectedEntityDetail.entity_id"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
            :is-character-controller="isSelectedEntityCharacterController"
          />
          <EntityBacklinksPanel
            :entity-id="selectedEntityDetail.entity_id"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
            :is-character-controller="isSelectedEntityCharacterController"
          />
          <TimelineEventListPanel
            :campaign-id="campaignId"
            heading="Timeline Context"
            :related-entity-id="selectedEntityDetail.entity_id"
            compact
            :show-filters="false"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
            @open="handleTimelineOpen"
          />
        </div>
        <div v-else class="space-y-3">
          <CurrentSessionPanel
            :campaign-id="campaignId"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
          />
          <YPanelSurface heading="Context" muted>
            <YEmptyState
              heading="No record selected"
              text="Select a record to inspect notes, relationships, backlinks, and timeline context."
            />
          </YPanelSurface>
          <CampaignActivityPanel
            :campaign-id="campaignId"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
            :limit="6"
          />
          <TimelineEventListPanel
            :campaign-id="campaignId"
            heading="Campaign Timeline"
            compact
            :show-filters="false"
            :active-role-view="roleViewContext.activeRoleView.value"
            :is-player-preview="roleViewContext.isPlayerPreview.value"
            @open="handleTimelineOpen"
          />
        </div>
      </aside>
    </div>
  </div>
</template>
