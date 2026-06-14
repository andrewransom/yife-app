<script setup lang="ts">
import { computed } from 'vue';
import { useEntityRelatedRecordsQuery } from '~/composables/entities/useEntityRelatedRecordsQuery';
import type { EntityRelatedRecord } from '~/composables/entities/types';
import { useUiStore } from '~/stores/ui';

const props = defineProps<{
  entityId: string;
  activeRoleView?: 'gm' | 'player';
  isPlayerPreview?: boolean;
  isCharacterController?: boolean;
}>();

const uiStore = useUiStore();
const relatedRecordsQuery = useEntityRelatedRecordsQuery(() => props.entityId, {
  enabled: computed(() => Boolean(props.entityId)),
  previewAsPlayer: computed(() => props.isPlayerPreview === true),
});

const groups = computed(() => {
  const sourceOrder = ['explicit', 'structural', 'mention'] as const;
  const items = (relatedRecordsQuery.data.value ?? []).filter((item) => {
    if (props.activeRoleView !== 'player') {
      return true;
    }

    if (item.visibility === 'shared') {
      return true;
    }

    return item.visibility === 'character_owner_gm' && props.isCharacterController;
  });

  return sourceOrder
    .map((key) => ({
      key,
      label: key === 'explicit' ? 'Explicit' : key === 'structural' ? 'Structural' : 'Mention',
      items: items.filter((item) => item.relation_source === key),
    }))
    .filter((group) => group.items.length > 0);
});

function openEntity(record: EntityRelatedRecord) {
  if (!record.related_entity_id || record.related_resolution_state !== 'visible') {
    return;
  }

  uiStore.selectEntity(record.related_entity_id);
}
</script>

<template>
  <YPanelSurface heading="Related Records" muted>
    <YEmptyState
      v-if="relatedRecordsQuery.isPending.value"
      heading="Loading related records"
      text="Collecting explicit, structural, and mention links."
    />
    <YEmptyState
      v-else-if="!groups.length"
      heading="No related records"
      text="Cross-record links appear here."
    />
    <div v-else class="space-y-3">
      <section v-for="group in groups" :key="group.key" class="space-y-2">
        <div class="flex items-center gap-2">
          <h3 class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">
            {{ group.label }}
          </h3>
          <YStatusBadge :label="String(group.items.length)" tone="info" />
        </div>

        <article
          v-for="record in group.items"
          :key="
            [
              record.relation_source,
              record.related_entity_id ?? record.target_entity_id,
              record.source_note_id,
              record.source_section_id,
              record.source_contribution_id,
              record.relationship_type_key,
            ].join(':')
          "
          class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
        >
          <div class="flex flex-wrap items-center gap-1">
            <YStatusBadge :label="record.label" tone="info" />
            <YVisibilityBadge :visibility="record.visibility" />
            <YStatusBadge :label="record.source_type.replaceAll('_', ' ')" tone="neutral" />
            <YStatusBadge
              v-if="record.mention_count"
              :label="`${record.mention_count} mention${record.mention_count === 1 ? '' : 's'}`"
              tone="neutral"
            />
            <YStatusBadge v-if="record.can_edit" label="Editable" tone="success" />
          </div>

          <div class="mt-2">
            <button
              v-if="record.related_entity_id && record.related_resolution_state === 'visible'"
              type="button"
              class="text-left text-sm font-medium text-[var(--yife-link)] hover:underline"
              @click="openEntity(record)"
            >
              {{ record.related_entity_label }}
            </button>
            <p v-else class="text-sm font-medium text-[var(--yife-text-muted)]">
              {{ record.related_entity_label }}
            </p>
          </div>

          <p v-if="record.source_summary" class="mt-1 text-xs text-[var(--yife-text-muted)]">
            {{ record.source_summary }}
          </p>
          <p
            v-if="
              record.source_note_id || record.source_section_id || record.source_contribution_id
            "
            class="mt-1 text-[11px] text-[var(--yife-text-muted)]"
          >
            Source:
            {{
              record.source_contribution_id
                ? 'Contribution'
                : record.source_section_id
                  ? 'Section'
                  : 'Note'
            }}
          </p>
        </article>
      </section>
    </div>
  </YPanelSurface>
</template>
