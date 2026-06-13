<script setup lang="ts">
import { computed } from 'vue';
import { CalendarDays, ChevronRight } from 'lucide-vue-next';
import type { EntitySummary } from '~/composables/entities/types';

const props = withDefaults(
  defineProps<{
    summary: EntitySummary;
    active?: boolean;
  }>(),
  {
    active: false,
  },
);

const emit = defineEmits<{
  select: [entityId: string];
}>();

function formatDate(value: string | null) {
  if (!value) {
    return '';
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(`${value}T00:00:00`));
}

const typeLabel = computed(() => props.summary.entity_type_key.replaceAll('_', ' '));
const meta = computed(() =>
  [
    props.summary.status_label,
    formatDate(props.summary.relevant_date),
    props.summary.location_type_label,
    props.summary.encounter_type_label,
    props.summary.storyline_type,
    props.summary.storyline_priority_label,
    props.summary.parent_entity_label ? `in ${props.summary.parent_entity_label}` : '',
    props.summary.related_session_label ? `session ${props.summary.related_session_label}` : '',
    props.summary.related_storyline_label
      ? `storyline ${props.summary.related_storyline_label}`
      : '',
    props.summary.timeline_date_expression,
  ]
    .filter(Boolean)
    .join(' · '),
);
</script>

<template>
  <button
    type="button"
    class="grid min-h-12 w-full grid-cols-[2rem_1fr_auto] items-center gap-2 border-b border-[var(--yife-border)] px-2 text-left last:border-b-0 hover:bg-[var(--yife-surface-muted)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[var(--yife-focus)]"
    :class="active ? 'bg-[var(--yife-surface-muted)]' : 'bg-transparent'"
    @click="emit('select', summary.entity_id)"
  >
    <span
      class="flex size-7 items-center justify-center rounded-[4px] bg-[var(--yife-primary)] text-xs font-semibold capitalize text-[var(--yife-primary-text)]"
      aria-hidden="true"
    >
      {{ summary.list_caption.slice(0, 1).toUpperCase() }}
    </span>
    <span class="min-w-0">
      <span class="block truncate text-sm font-medium">{{ summary.list_caption }}</span>
      <span class="flex min-w-0 items-center gap-1 truncate text-xs text-[var(--yife-text-muted)]">
        <CalendarDays v-if="summary.relevant_date" class="size-3 shrink-0" aria-hidden="true" />
        <span class="truncate capitalize">{{ meta || typeLabel }}</span>
      </span>
    </span>
    <span class="flex items-center gap-1">
      <YVisibilityBadge :visibility="summary.default_visibility" />
      <ChevronRight class="size-3 text-[var(--yife-text-muted)]" aria-hidden="true" />
    </span>
  </button>
</template>
