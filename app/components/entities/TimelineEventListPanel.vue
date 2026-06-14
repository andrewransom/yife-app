<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useCampaignEntitySummariesQuery } from '~/composables/entities/useCampaignEntitySummariesQuery';
import { useCampaignOptionsQuery } from '~/composables/entities/useCampaignOptionsQuery';
import { useTimelineEventsQuery } from '~/composables/entities/useTimelineEventsQuery';
import type { TimelineEvent } from '~/composables/entities/types';
import { useUiStore } from '~/stores/ui';

const props = withDefaults(
  defineProps<{
    campaignId: string;
    heading?: string;
    relatedEntityId?: string | null;
    showFilters?: boolean;
    compact?: boolean;
    activeRoleView?: 'gm' | 'player';
    isPlayerPreview?: boolean;
  }>(),
  {
    heading: 'Timeline',
    relatedEntityId: null,
    showFilters: true,
    compact: false,
    activeRoleView: 'gm',
    isPlayerPreview: false,
  },
);

const emit = defineEmits<{
  open: [entityId: string];
}>();

const uiStore = useUiStore();
const eventTypeKey = ref<string>('');
const relatedSessionEntityId = ref<string>('');
const visibility = ref<string>('');

const sessionsQuery = useCampaignEntitySummariesQuery(() => props.campaignId, {
  enabled: computed(() => Boolean(props.campaignId) && props.showFilters),
});
const eventTypesQuery = useCampaignOptionsQuery(
  () => props.campaignId,
  () => 'timeline_event_type',
  {
    enabled: computed(() => Boolean(props.campaignId)),
  },
);
const timelineQuery = useTimelineEventsQuery(
  () => props.campaignId,
  {
    eventTypeKey: () => eventTypeKey.value || null,
    relatedSessionEntityId: () => relatedSessionEntityId.value || null,
    relatedEntityId: () => props.relatedEntityId || null,
    visibility: () => visibility.value || null,
  },
  {
    enabled: computed(() => Boolean(props.campaignId)),
    previewAsPlayer: computed(() => props.isPlayerPreview === true),
  },
);

const sessions = computed(() =>
  (sessionsQuery.data.value ?? []).filter((summary) => summary.entity_type_key === 'session'),
);
const eventTypes = computed(() => eventTypesQuery.data.value ?? []);
const canFilterVisibility = computed(() => props.activeRoleView === 'gm');
const items = computed(() =>
  (timelineQuery.data.value ?? []).filter((event) => {
    if (props.activeRoleView !== 'player') {
      return true;
    }

    return event.default_visibility === 'shared';
  }),
);

watch(
  () => props.activeRoleView,
  (value) => {
    if (value !== 'gm') {
      visibility.value = '';
    }
  },
  { immediate: true },
);

function openTimelineEvent(event: TimelineEvent) {
  uiStore.selectEntity(event.entity_id);
  emit('open', event.entity_id);
}
</script>

<template>
  <YPanelSurface :heading="heading" muted>
    <div v-if="showFilters" class="mb-3 grid gap-2 sm:grid-cols-2 xl:grid-cols-4">
      <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
        Event type
        <select
          v-model="eventTypeKey"
          class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="">All types</option>
          <option v-for="type in eventTypes" :key="type.id" :value="type.key">
            {{ type.label }}
          </option>
        </select>
      </label>

      <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
        Related session
        <select
          v-model="relatedSessionEntityId"
          class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="">All sessions</option>
          <option v-for="session in sessions" :key="session.entity_id" :value="session.entity_id">
            {{ session.list_caption }}
          </option>
        </select>
      </label>

      <label
        v-if="canFilterVisibility"
        class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]"
      >
        Visibility
        <select
          v-model="visibility"
          class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="">All visible</option>
          <option value="shared">Shared</option>
          <option value="gm_only">GM only</option>
          <option value="private">Private</option>
        </select>
      </label>
    </div>

    <YEmptyState
      v-if="timelineQuery.isPending.value"
      heading="Loading timeline"
      text="Fetching visible events."
    />
    <YEmptyState
      v-else-if="!items.length"
      heading="No timeline events"
      text="Visible events matching these filters appear here."
    />
    <div v-else :class="compact ? 'space-y-2' : 'space-y-3'">
      <article
        v-for="event in items"
        :key="event.entity_id"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
      >
        <div class="flex flex-wrap items-center gap-1">
          <YStatusBadge :label="event.event_type_label" tone="info" />
          <YVisibilityBadge :visibility="event.default_visibility" />
          <YStatusBadge
            v-if="event.date_expression"
            :label="event.date_expression"
            tone="neutral"
          />
        </div>

        <button
          type="button"
          class="mt-2 text-left text-sm font-medium text-[var(--yife-link)] hover:underline"
          @click="openTimelineEvent(event)"
        >
          {{ event.list_caption }}
        </button>

        <div
          v-if="event.related_session_label || event.primary_location_label"
          class="mt-1 flex flex-wrap gap-2 text-xs text-[var(--yife-text-muted)]"
        >
          <span v-if="event.related_session_label">Session: {{ event.related_session_label }}</span>
          <span v-if="event.primary_location_label">Location: {{ event.primary_location_label }}</span>
        </div>
      </article>
    </div>
  </YPanelSurface>
</template>
