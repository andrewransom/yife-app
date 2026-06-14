<script setup lang="ts">
import { computed } from 'vue';
import { useEntityBacklinksQuery } from '~/composables/entities/useEntityBacklinksQuery';

const props = defineProps<{
  entityId: string;
  activeRoleView?: 'gm' | 'player';
  isPlayerPreview?: boolean;
  isCharacterController?: boolean;
}>();

const backlinksQuery = useEntityBacklinksQuery(() => props.entityId, {
  enabled: computed(() => Boolean(props.entityId)),
  previewAsPlayer: computed(() => props.isPlayerPreview === true),
});
const backlinks = computed(() =>
  (backlinksQuery.data.value ?? []).filter((backlink) => {
    if (props.activeRoleView !== 'player') {
      return true;
    }

    if (backlink.visibility === 'shared') {
      return true;
    }

    return backlink.visibility === 'character_owner_gm' && props.isCharacterController;
  }),
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
  <YPanelSurface heading="Backlinks" muted>
    <YEmptyState
      v-if="backlinksQuery.isPending.value"
      heading="Loading backlinks"
      text="Finding visible references."
    />
    <YEmptyState
      v-else-if="!backlinks.length"
      heading="No backlinks"
      text="Visible mentions of this record appear here."
    />
    <div v-else class="space-y-2 text-sm">
      <article
        v-for="backlink in backlinks"
        :key="`${backlink.source_type}-${backlink.source_id}`"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-2"
      >
        <div class="flex flex-wrap items-center gap-2">
          <YStatusBadge :label="backlink.source_type" tone="info" />
          <YVisibilityBadge :visibility="backlink.visibility" />
          <span class="text-xs text-[var(--yife-text-muted)]">{{
            formatDateTime(backlink.updated_at)
          }}</span>
        </div>
        <p class="mt-1 font-medium">{{ backlink.source_label }}</p>
        <p v-if="backlink.source_preview" class="mt-1 text-[var(--yife-text-muted)]">
          {{ backlink.source_preview }}
        </p>
      </article>
    </div>
  </YPanelSurface>
</template>
