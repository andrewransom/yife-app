<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { Pencil, Plus, Save, Trash2, X } from 'lucide-vue-next';
import { useYifeToast } from '~/composables/auth/useYifeToast';
import { useCampaignEntitySummariesQuery } from '~/composables/entities/useCampaignEntitySummariesQuery';
import {
  useCreateEntityRelationshipMutation,
  useDeleteEntityRelationshipMutation,
  useUpdateEntityRelationshipMutation,
} from '~/composables/entities/useEntityRelationshipMutations';
import { useEntityRelationshipsQuery } from '~/composables/entities/useEntityRelationshipsQuery';
import { useRelationshipTypesQuery } from '~/composables/entities/useRelationshipTypesQuery';
import type { EntityRelationship } from '~/composables/entities/types';
import { useUiStore } from '~/stores/ui';

const props = withDefaults(
  defineProps<{
    campaignId: string;
    entityId: string;
    canManage?: boolean;
    activeRoleView?: 'gm' | 'player';
    isPlayerPreview?: boolean;
    isCharacterController?: boolean;
  }>(),
  {
    canManage: false,
    activeRoleView: 'gm',
    isPlayerPreview: false,
    isCharacterController: false,
  },
);

const uiStore = useUiStore();
const toast = useYifeToast();
const relationshipsQuery = useEntityRelationshipsQuery(() => props.entityId, {
  enabled: computed(() => Boolean(props.entityId)),
  previewAsPlayer: computed(() => props.isPlayerPreview === true),
});
const typesQuery = useRelationshipTypesQuery(() => props.campaignId, {
  enabled: computed(() => Boolean(props.campaignId)),
});
const summariesQuery = useCampaignEntitySummariesQuery(() => props.campaignId, {
  enabled: computed(() => Boolean(props.campaignId)),
});
const createRelationship = useCreateEntityRelationshipMutation();
const updateRelationship = useUpdateEntityRelationshipMutation();
const deleteRelationship = useDeleteEntityRelationshipMutation();

const isCreating = ref(false);
const createTargetEntityId = ref('');
const createRelationshipTypeId = ref('');
const createVisibility = ref<'shared' | 'gm_only'>('shared');
const editingRelationshipId = ref<string | null>(null);
const editRelationshipTypeId = ref('');
const editVisibility = ref<'shared' | 'gm_only'>('shared');

const canManageRelationships = computed(() => props.canManage && props.activeRoleView === 'gm');
const relationships = computed(() =>
  (relationshipsQuery.data.value ?? []).filter((relationship) => {
    if (props.activeRoleView !== 'player') {
      return true;
    }

    if (relationship.visibility === 'shared') {
      return true;
    }

    return relationship.visibility === 'character_owner_gm' && props.isCharacterController;
  }),
);
const relationshipTypes = computed(() => typesQuery.data.value ?? []);
const availableTargets = computed(() =>
  (summariesQuery.data.value ?? []).filter((summary) => summary.entity_id !== props.entityId),
);

function beginCreate() {
  if (!canManageRelationships.value) {
    return;
  }

  isCreating.value = true;
  createTargetEntityId.value = '';
  createRelationshipTypeId.value = relationshipTypes.value[0]?.id ?? '';
  createVisibility.value = 'shared';
}

function cancelCreate() {
  isCreating.value = false;
  createTargetEntityId.value = '';
  createRelationshipTypeId.value = '';
  createVisibility.value = 'shared';
}

async function submitCreate() {
  if (!createTargetEntityId.value || !createRelationshipTypeId.value) {
    toast.error('Choose a related record and relationship type');
    return;
  }

  try {
    await createRelationship.mutateAsync({
      sourceEntityId: props.entityId,
      targetEntityId: createTargetEntityId.value,
      relationshipTypeId: createRelationshipTypeId.value,
      visibility: createVisibility.value,
    });
    toast.success('Relationship created');
    cancelCreate();
  } catch (error) {
    toast.error(error instanceof Error ? error.message : 'Relationship create failed');
  }
}

function beginEdit(relationship: EntityRelationship) {
  editingRelationshipId.value = relationship.relationship_id;
  editRelationshipTypeId.value = relationship.relationship_type_id;
  editVisibility.value = relationship.visibility as 'shared' | 'gm_only';
}

function cancelEdit() {
  editingRelationshipId.value = null;
  editRelationshipTypeId.value = '';
  editVisibility.value = 'shared';
}

watch(
  () => props.entityId,
  () => {
    cancelCreate();
    cancelEdit();
  },
);

async function submitEdit(relationship: EntityRelationship) {
  try {
    await updateRelationship.mutateAsync({
      relationshipId: relationship.relationship_id,
      sourceEntityId: relationship.source_entity_id,
      targetEntityId: relationship.target_entity_id,
      relationshipTypeId: editRelationshipTypeId.value,
      visibility: editVisibility.value,
    });
    toast.success('Relationship updated');
    cancelEdit();
  } catch (error) {
    toast.error(error instanceof Error ? error.message : 'Relationship update failed');
  }
}

async function removeRelationship(relationship: EntityRelationship) {
  try {
    await deleteRelationship.mutateAsync({
      relationshipId: relationship.relationship_id,
      sourceEntityId: relationship.source_entity_id,
      targetEntityId: relationship.target_entity_id,
    });
    toast.success('Relationship deleted');
    cancelEdit();
  } catch (error) {
    toast.error(error instanceof Error ? error.message : 'Relationship delete failed');
  }
}

function openEntity(entityId: string | null) {
  if (!entityId) {
    return;
  }

  uiStore.selectEntity(entityId);
}
</script>

<template>
  <YPanelSurface heading="Relationships" muted>
    <template #actions>
      <YIconButton
        v-if="canManageRelationships"
        :icon="Plus"
        label="Add relationship"
        @click="beginCreate"
      />
    </template>

    <div
      v-if="isCreating"
      class="mb-3 space-y-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
    >
      <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
        Related record
        <select
          v-model="createTargetEntityId"
          class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="">Choose a record</option>
          <option
            v-for="summary in availableTargets"
            :key="summary.entity_id"
            :value="summary.entity_id"
          >
            {{ summary.list_caption }}
          </option>
        </select>
      </label>

      <div class="grid gap-2 sm:grid-cols-2">
        <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
          Type
          <select
            v-model="createRelationshipTypeId"
            class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option value="">Choose a type</option>
            <option v-for="type in relationshipTypes" :key="type.id" :value="type.id">
              {{ type.label }}
            </option>
          </select>
        </label>

        <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
          Visibility
          <select
            v-model="createVisibility"
            class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option value="shared">Shared</option>
            <option value="gm_only">GM only</option>
          </select>
        </label>
      </div>

      <div class="flex items-center gap-2">
        <YDenseButton
          color="primary"
          :loading="createRelationship.isPending.value"
          @click="submitCreate"
        >
          Save
        </YDenseButton>
        <YDenseButton variant="ghost" @click="cancelCreate">Cancel</YDenseButton>
      </div>
    </div>

    <YEmptyState
      v-if="relationshipsQuery.isPending.value"
      heading="Loading relationships"
      text="Fetching explicit links."
    />
    <YEmptyState
      v-else-if="!relationships.length"
      heading="No relationships"
      text="Explicit links appear here."
    />
    <div v-else class="space-y-2">
      <article
        v-for="relationship in relationships"
        :key="relationship.relationship_id"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
      >
        <div class="flex flex-wrap items-center gap-1">
          <YStatusBadge :label="relationship.label" tone="info" />
          <YVisibilityBadge :visibility="relationship.visibility" />
          <YStatusBadge
            v-if="relationship.relation_direction === 'incoming'"
            label="Incoming"
            tone="neutral"
          />
        </div>

        <div class="mt-2 flex items-start justify-between gap-2">
          <div class="min-w-0 flex-1">
            <button
              v-if="
                relationship.related_entity_id &&
                  relationship.related_resolution_state === 'visible'
              "
              type="button"
              class="min-w-0 truncate text-left text-sm font-medium text-[var(--yife-link)] hover:underline"
              @click="openEntity(relationship.related_entity_id)"
            >
              {{ relationship.related_entity_label }}
            </button>
            <p v-else class="text-sm font-medium text-[var(--yife-text-muted)]">
              {{ relationship.related_entity_label }}
            </p>
            <p
              v-if="relationship.related_resolution_state !== 'visible'"
              class="mt-1 text-xs text-[var(--yife-text-muted)]"
            >
              {{ relationship.related_resolution_state }}
            </p>
          </div>

          <div
            v-if="canManageRelationships && relationship.can_edit"
            class="flex items-center gap-1"
          >
            <YIconButton
              :icon="Pencil"
              label="Edit relationship"
              @click="beginEdit(relationship)"
            />
            <YIconButton
              :icon="Trash2"
              label="Delete relationship"
              color="error"
              @click="removeRelationship(relationship)"
            />
          </div>
        </div>

        <div
          v-if="editingRelationshipId === relationship.relationship_id && canManageRelationships"
          class="mt-3 space-y-2 border-t border-[var(--yife-border)] pt-3"
        >
          <div class="grid gap-2 sm:grid-cols-2">
            <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
              Type
              <select
                v-model="editRelationshipTypeId"
                class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
              >
                <option v-for="type in relationshipTypes" :key="type.id" :value="type.id">
                  {{ type.label }}
                </option>
              </select>
            </label>

            <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
              Visibility
              <select
                v-model="editVisibility"
                class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
              >
                <option value="shared">Shared</option>
                <option value="gm_only">GM only</option>
              </select>
            </label>
          </div>

          <div class="flex items-center gap-2">
            <YIconButton
              :icon="Save"
              label="Save relationship"
              color="primary"
              @click="submitEdit(relationship)"
            />
            <YIconButton :icon="X" label="Cancel edit" @click="cancelEdit" />
          </div>
        </div>
      </article>
    </div>
  </YPanelSurface>
</template>
