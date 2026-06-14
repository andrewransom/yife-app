<script setup lang="ts">
import { computed } from 'vue';
import { useEntityNotesQuery } from '~/composables/entities/useEntityNotesQuery';

const props = defineProps<{
  entityId: string;
  limit?: number;
  activeRoleView?: 'gm' | 'player';
  isPlayerPreview?: boolean;
  isCharacterController?: boolean;
}>();

const notesQuery = useEntityNotesQuery(() => props.entityId, {
  enabled: computed(() => Boolean(props.entityId)),
  previewAsPlayer: computed(() => props.isPlayerPreview === true),
});

const notes = computed(() =>
  (notesQuery.data.value ?? [])
    .filter((note) => {
      if (props.activeRoleView !== 'player') {
        return true;
      }

      if (note.visibility === 'shared') {
        return true;
      }

      return note.visibility === 'character_owner_gm' && props.isCharacterController;
    })
    .slice(0, props.limit ?? 3),
);

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}
</script>

<template>
  <YPanelSurface heading="Notes" muted>
    <YEmptyState
      v-if="notesQuery.isPending.value"
      heading="Loading notes"
      text="Fetching attached notes."
    />
    <YEmptyState v-else-if="!notes.length" heading="No notes" text="Attached notes appear here." />
    <div v-else class="space-y-2">
      <article
        v-for="note in notes"
        :key="note.id"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
      >
        <div class="flex flex-wrap items-center gap-1">
          <YVisibilityBadge :visibility="note.visibility" />
          <span class="text-xs text-[var(--yife-text-muted)]">{{
            formatDateTime(note.updated_at)
          }}</span>
        </div>
        <p class="mt-2 text-sm text-[var(--yife-text)]">
          {{ note.body_preview || note.body_text || 'Untitled note' }}
        </p>
      </article>
    </div>
  </YPanelSurface>
</template>
