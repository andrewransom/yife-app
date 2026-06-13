<script setup lang="ts">
import { computed } from 'vue';
import { Link2 } from 'lucide-vue-next';
import type { EntityDetail } from '~/composables/entities/types';

const props = withDefaults(
  defineProps<{
    detail?: EntityDetail | null;
    isLoading?: boolean;
    isUnavailable?: boolean;
  }>(),
  {
    detail: null,
    isLoading: false,
    isUnavailable: false,
  },
);

type SectionSummary = {
  id: string;
  section_key: string;
  label: string;
  visibility: 'shared' | 'gm_only' | 'private';
  edit_policy: string;
  content_mode: string;
};

const sections = computed<SectionSummary[]>(() =>
  Array.isArray(props.detail?.sections) ? (props.detail.sections as SectionSummary[]) : [],
);

function formatDate(value: string | null | undefined) {
  if (!value) {
    return '';
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(`${value}T00:00:00`));
}

const metadata = computed(() => {
  const items = [
    props.detail?.status_label,
    formatDate(props.detail?.relevant_date),
    props.detail?.location_type_label,
    props.detail?.encounter_type_label,
    props.detail?.quest_priority_label,
    props.detail?.timeline_date_expression,
    props.detail?.controlling_user_display_label
      ? `Controller: ${props.detail.controlling_user_display_label}`
      : '',
    props.detail?.parent_entity_label ? `Parent: ${props.detail.parent_entity_label}` : '',
    props.detail?.related_session_label ? `Session: ${props.detail.related_session_label}` : '',
    props.detail?.related_plot_arc_label ? `Arc: ${props.detail.related_plot_arc_label}` : '',
    props.detail?.is_major ? 'Major' : '',
  ];

  return items.filter((item): item is string => Boolean(item));
});
</script>

<template>
  <YPanelSurface v-if="isLoading" heading="Opening record">
    <YEmptyState heading="Loading" text="Fetching entity detail." />
  </YPanelSurface>

  <YPanelSurface v-else-if="isUnavailable || !detail" heading="Record unavailable">
    <YEmptyState
      heading="Unavailable"
      text="This record is unavailable or you do not have access."
    />
  </YPanelSurface>

  <div v-else class="grid gap-3 lg:grid-cols-[minmax(0,1fr)_16rem]">
    <YPanelSurface>
      <template #actions>
        <YVisibilityBadge :visibility="detail.default_visibility" />
      </template>
      <div class="border-b border-[var(--yife-border)] pb-3">
        <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">
          {{ detail.entity_type_label }}
        </p>
        <h2 class="mt-1 text-xl font-semibold">{{ detail.list_caption }}</h2>
        <div class="mt-2 flex flex-wrap gap-1">
          <YStatusBadge v-for="item in metadata" :key="item" :label="item" tone="info" />
          <YStatusBadge
            v-if="detail.npc_real_status_label"
            :label="`Real: ${detail.npc_real_status_label}`"
            tone="warning"
          />
        </div>
      </div>

      <div class="grid gap-2 pt-3">
        <section
          v-for="section in sections"
          :key="section.id"
          class="border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
        >
          <div class="flex items-center gap-2">
            <h3 class="min-w-0 flex-1 truncate text-sm font-semibold">{{ section.label }}</h3>
            <YVisibilityBadge :visibility="section.visibility" />
          </div>
          <p class="mt-2 text-xs text-[var(--yife-text-muted)]">
            Empty section. Rich text editing starts in the next milestone.
          </p>
        </section>
      </div>
    </YPanelSurface>

    <YPanelSurface heading="Context" muted>
      <div class="space-y-3 text-sm text-[var(--yife-text-muted)]">
        <div class="flex items-center gap-2">
          <Link2 class="size-4" aria-hidden="true" />
          Related records arrive with relationship tools.
        </div>
        <YStatusBadge label="Read-only shell" tone="info" />
      </div>
    </YPanelSurface>
  </div>
</template>
