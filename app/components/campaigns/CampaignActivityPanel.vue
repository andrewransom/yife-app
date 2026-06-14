<script setup lang="ts">
import { computed } from 'vue';
import { FileText, Link2, NotebookText, ScrollText } from 'lucide-vue-next';
import { useCampaignActivityQuery } from '~/composables/entities/useCampaignActivityQuery';
import type { CampaignActivityItem } from '~/composables/entities/types';
import { useUiStore } from '~/stores/ui';

const props = withDefaults(
  defineProps<{
    campaignId: string;
    relatedEntityId?: string | null;
    heading?: string;
    limit?: number;
    activeRoleView?: 'gm' | 'player';
    isPlayerPreview?: boolean;
  }>(),
  {
    relatedEntityId: null,
    heading: 'Recent Activity',
    limit: 8,
    activeRoleView: 'gm',
    isPlayerPreview: false,
  },
);

const uiStore = useUiStore();
const activityQuery = useCampaignActivityQuery(
  () => props.campaignId,
  {
    relatedEntityId: () => props.relatedEntityId,
    limit: () => props.limit,
  },
  {
    enabled: computed(() => Boolean(props.campaignId)),
    previewAsPlayer: computed(() => props.isPlayerPreview === true),
  },
);

const items = computed(() => activityQuery.data.value ?? []);

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}

function openSubject(item: CampaignActivityItem) {
  if (item.subject_entity_id) {
    uiStore.selectEntity(item.subject_entity_id);
  }
}

function activityIcon(activityType: string) {
  if (activityType.startsWith('relationship')) {
    return Link2;
  }

  if (activityType.startsWith('note')) {
    return NotebookText;
  }

  if (activityType.startsWith('section') || activityType.startsWith('contribution')) {
    return FileText;
  }

  return ScrollText;
}
</script>

<template>
  <YPanelSurface :heading="heading" muted>
    <YEmptyState
      v-if="activityQuery.isPending.value"
      heading="Loading activity"
      text="Fetching visible changes."
    />
    <YEmptyState
      v-else-if="!items.length"
      heading="No activity yet"
      text="Visible updates appear here."
    />
    <div v-else class="space-y-2">
      <article
        v-for="item in items"
        :key="`${item.activity_type}:${item.subject_id}:${item.occurred_at}`"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
      >
        <div class="flex items-start gap-2">
          <component
            :is="activityIcon(item.activity_type)"
            class="mt-0.5 size-4 shrink-0 text-[var(--yife-text-muted)]"
            aria-hidden="true"
          />
          <div class="min-w-0 flex-1">
            <button
              v-if="item.subject_entity_id"
              type="button"
              class="w-full text-left text-sm font-medium text-[var(--yife-link)] hover:underline"
              @click="openSubject(item)"
            >
              {{ item.label }}
            </button>
            <p v-else class="text-sm font-medium">
              {{ item.label }}
            </p>
            <div
              class="mt-1 flex flex-wrap items-center gap-2 text-xs text-[var(--yife-text-muted)]"
            >
              <span>{{ item.actor_display_label || 'Unknown actor' }}</span>
              <span>{{ formatDateTime(item.occurred_at) }}</span>
              <YVisibilityBadge :visibility="item.visibility" />
            </div>
          </div>
        </div>
      </article>
    </div>
  </YPanelSurface>
</template>
