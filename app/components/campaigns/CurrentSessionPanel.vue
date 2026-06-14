<script setup lang="ts">
import { computed } from 'vue';
import { CalendarDays } from 'lucide-vue-next';
import { useCurrentSessionQuery } from '~/composables/entities/useCurrentSessionQuery';
import { useUiStore } from '~/stores/ui';

const props = withDefaults(
  defineProps<{
    campaignId: string;
    activeRoleView?: 'gm' | 'player';
    isPlayerPreview?: boolean;
  }>(),
  {
    activeRoleView: 'gm',
    isPlayerPreview: false,
  },
);

const uiStore = useUiStore();
const currentSessionQuery = useCurrentSessionQuery(() => props.campaignId, {
  enabled: computed(() => Boolean(props.campaignId)),
  previewAsPlayer: computed(() => props.isPlayerPreview === true),
});

const currentSession = computed(() => currentSessionQuery.data.value);
const sessionOptions = computed(() => currentSessionQuery.sessionsQuery.data.value ?? []);
const overrideValue = computed(
  () =>
    uiStore.getCurrentSessionOverride(props.campaignId) ??
    currentSession.value?.session_entity_id ??
    '',
);

function formatDate(value: string | null) {
  if (!value) {
    return 'No date';
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(`${value}T00:00:00`));
}

function openCurrentSession() {
  if (currentSession.value?.session_entity_id) {
    uiStore.selectEntity(currentSession.value.session_entity_id);
  }
}
</script>

<template>
  <YPanelSurface heading="Current Session" muted>
    <YEmptyState
      v-if="currentSessionQuery.isPending.value"
      heading="Loading session context"
      text="Resolving current session."
    />
    <YEmptyState
      v-else-if="!currentSession"
      :icon="CalendarDays"
      heading="No current session"
      text="Create a planned or completed session to anchor session workflows."
    />
    <div v-else class="space-y-3">
      <div class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3">
        <div class="flex flex-wrap items-center gap-2">
          <YStatusBadge :label="currentSession.status_label || 'Session'" tone="info" />
          <YStatusBadge
            :label="currentSession.selection_reason.replaceAll('_', ' ')"
            tone="neutral"
          />
        </div>
        <button
          type="button"
          class="mt-2 text-left text-sm font-semibold text-[var(--yife-link)] hover:underline"
          @click="openCurrentSession"
        >
          {{ currentSession.list_caption }}
        </button>
        <p class="mt-1 text-xs text-[var(--yife-text-muted)]">
          {{ formatDate(currentSession.session_date) }}
        </p>
      </div>

      <label
        v-if="sessionOptions.length > 1"
        class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]"
      >
        Override
        <select
          :value="overrideValue"
          class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          @change="
            currentSessionQuery.setOverride(($event.target as HTMLSelectElement).value || null)
          "
        >
          <option value="">Auto</option>
          <option
            v-for="session in sessionOptions"
            :key="session.entity_id"
            :value="session.entity_id"
          >
            {{ session.list_caption }}
          </option>
        </select>
      </label>
    </div>
  </YPanelSurface>
</template>
