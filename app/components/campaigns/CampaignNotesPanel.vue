<script setup lang="ts">
import { computed, ref } from 'vue';
import { Pencil, Plus, Save, Trash2, X } from 'lucide-vue-next';
import { useYifeToast } from '~/composables/auth/useYifeToast';
import { useCampaignEntitySummariesQuery } from '~/composables/entities/useCampaignEntitySummariesQuery';
import { useCampaignNotesQuery } from '~/composables/entities/useCampaignNotesQuery';
import { useCreateNoteMutation, useDeleteNoteMutation, useUpdateNoteMutation } from '~/composables/entities/useRichTextMutations';
import type { EntityNote } from '~/composables/entities/types';
import { createDefaultRichTextDocument, extractRichText, isStaleConflictError } from '~/utils/rich-text';

const props = defineProps<{
  campaignId: string;
}>();

type NoteAttachment = {
  target_type: string;
  entity_id: string | null;
  label: string;
};

const toast = useYifeToast();
const notesQuery = useCampaignNotesQuery(() => props.campaignId, {
  enabled: computed(() => Boolean(props.campaignId)),
});
const summariesQuery = useCampaignEntitySummariesQuery(() => props.campaignId, {
  enabled: computed(() => Boolean(props.campaignId)),
});
const createNote = useCreateNoteMutation();
const updateNote = useUpdateNoteMutation();
const deleteNote = useDeleteNoteMutation();

const isCreating = ref(false);
const createVisibility = ref('shared');
const createAttachToCampaign = ref(true);
const createEntityIds = ref<string[]>([]);
const createDraft = ref<Record<string, unknown>>(createDefaultRichTextDocument());
const editingNoteId = ref<string | null>(null);
const editAttachToCampaign = ref(false);
const editEntityIds = ref<string[]>([]);
const editDraft = ref<Record<string, unknown>>(createDefaultRichTextDocument());
const hasCreateTarget = computed(() => createAttachToCampaign.value || createEntityIds.value.length > 0);
const hasEditTarget = computed(() => editAttachToCampaign.value || editEntityIds.value.length > 0);

function attachmentsFor(note: EntityNote): NoteAttachment[] {
  return Array.isArray(note.attachments)
    ? note.attachments.filter(
        (value): value is NoteAttachment =>
          Boolean(
            value &&
              typeof value === 'object' &&
              !Array.isArray(value) &&
              typeof (value as NoteAttachment).target_type === 'string' &&
              typeof (value as NoteAttachment).label === 'string',
          ),
      )
    : [];
}

function asDocument(value: unknown) {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : createDefaultRichTextDocument();
}

function toggleEntitySelection(list: string[], entityId: string, checked: boolean) {
  return checked ? Array.from(new Set([...list, entityId])) : list.filter((id) => id !== entityId);
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}

function beginCreate() {
  isCreating.value = true;
  createVisibility.value = 'shared';
  createAttachToCampaign.value = true;
  createEntityIds.value = [];
  createDraft.value = createDefaultRichTextDocument();
}

function cancelCreate() {
  isCreating.value = false;
  createAttachToCampaign.value = true;
  createEntityIds.value = [];
  createDraft.value = createDefaultRichTextDocument();
}

async function submitCreate() {
  if (!hasCreateTarget.value) {
    toast.error('Select at least one note attachment');
    return;
  }

  try {
    await createNote.mutateAsync({
      campaignId: props.campaignId,
      visibility: createVisibility.value,
      attachToCampaign: createAttachToCampaign.value,
      entityIds: createEntityIds.value,
      content: extractRichText(createDraft.value),
    });
    toast.success('Note created');
    cancelCreate();
  } catch {
    toast.error('Note creation failed');
  }
}

function beginEdit(note: EntityNote) {
  editingNoteId.value = note.id;
  editDraft.value = asDocument(note.body_json);
  editAttachToCampaign.value = attachmentsFor(note).some((attachment) => attachment.target_type === 'campaign');
  editEntityIds.value = attachmentsFor(note)
    .filter((attachment) => attachment.target_type === 'entity' && attachment.entity_id)
    .map((attachment) => attachment.entity_id as string);
}

function cancelEdit() {
  editingNoteId.value = null;
  editAttachToCampaign.value = false;
  editEntityIds.value = [];
  editDraft.value = createDefaultRichTextDocument();
}

async function submitEdit(note: EntityNote) {
  if (!hasEditTarget.value) {
    toast.error('Select at least one note attachment');
    return;
  }

  try {
    await updateNote.mutateAsync({
      entityId:
        editEntityIds.value[0] ??
        attachmentsFor(note).find((attachment) => attachment.target_type === 'entity')?.entity_id ??
        'none',
      noteId: note.id,
      visibility: note.visibility,
      expectedVersion: note.version_number,
      attachToCampaign: editAttachToCampaign.value,
      entityIds: editEntityIds.value,
      currentAttachToCampaign: attachmentsFor(note).some((attachment) => attachment.target_type === 'campaign'),
      currentEntityIds: attachmentsFor(note)
        .filter((attachment) => attachment.target_type === 'entity' && attachment.entity_id)
        .map((attachment) => attachment.entity_id as string),
      content: extractRichText(editDraft.value),
    });
    toast.success('Note updated');
    cancelEdit();
  } catch (error) {
    toast.error(
      isStaleConflictError(error) ? 'Note changed. Reload before saving again.' : 'Note update failed',
    );
  }
}

async function removeNote(note: EntityNote) {
  try {
    await deleteNote.mutateAsync({
      campaignId: props.campaignId,
      entityId:
        attachmentsFor(note)
          .find((attachment) => attachment.target_type === 'entity' && attachment.entity_id)
          ?.entity_id ?? 'none',
      noteId: note.id,
    });
    toast.success('Note deleted');
  } catch {
    toast.error('Note delete failed');
  }
}
</script>

<template>
  <YPanelSurface heading="Campaign Notes">
    <template #actions>
      <YIconButton :icon="Plus" label="Create note" @click="beginCreate" />
    </template>

    <div class="space-y-3">
      <div
        v-if="isCreating"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
      >
        <div class="mb-2 flex items-center gap-2">
          <label class="text-xs font-medium uppercase text-[var(--yife-text-muted)]" for="campaign-note-visibility">
            Visibility
          </label>
          <select
            id="campaign-note-visibility"
            v-model="createVisibility"
            class="h-8 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option value="shared">Shared</option>
            <option value="gm_only">GM Only</option>
            <option value="private">Private</option>
          </select>
        </div>
        <div class="mb-2 flex items-center gap-2 text-sm">
          <input
            id="campaign-note-attach-campaign"
            v-model="createAttachToCampaign"
            type="checkbox"
            class="rounded border-[var(--yife-border)]"
          />
          <label for="campaign-note-attach-campaign">Attach to campaign</label>
        </div>
        <div class="mb-2 space-y-1 text-sm">
          <label
            v-for="entity in summariesQuery.data.value ?? []"
            :key="entity.entity_id"
            class="flex items-center gap-2"
          >
            <input
              :checked="createEntityIds.includes(entity.entity_id)"
              type="checkbox"
              class="rounded border-[var(--yife-border)]"
              @change="createEntityIds = toggleEntitySelection(createEntityIds, entity.entity_id, ($event.target as HTMLInputElement).checked)"
            />
            <span>{{ entity.list_caption }}</span>
          </label>
        </div>
        <YRichTextEditor v-model="createDraft" :campaign-id="campaignId" />
        <div class="mt-2 flex gap-2">
          <YIconButton :icon="Save" label="Save note" :disabled="!hasCreateTarget" @click="submitCreate" />
          <YIconButton :icon="X" label="Cancel note" @click="cancelCreate" />
        </div>
      </div>

      <YEmptyState
        v-if="notesQuery.isPending.value"
        heading="Loading notes"
        text="Fetching visible campaign notes."
      />
      <YEmptyState
        v-else-if="!notesQuery.data.value?.length && !isCreating"
        heading="No notes"
        text="Create the first campaign-level note."
      />
      <article
        v-for="note in notesQuery.data.value"
        :key="note.id"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
      >
        <div class="flex flex-wrap items-center gap-2">
          <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">
            {{ note.author_display_label || 'Member' }}
          </p>
          <YVisibilityBadge :visibility="note.visibility" />
          <YStatusBadge :label="formatDateTime(note.updated_at)" tone="neutral" />
          <div class="ml-auto flex gap-2" v-if="note.can_edit">
            <YIconButton :icon="Pencil" label="Edit note" @click="beginEdit(note)" />
            <YIconButton :icon="Trash2" label="Delete note" @click="removeNote(note)" />
          </div>
        </div>

        <div class="mt-2 flex flex-wrap gap-1" v-if="attachmentsFor(note).length">
          <YStatusBadge
            v-for="attachment in attachmentsFor(note)"
            :key="`${attachment.target_type}-${attachment.entity_id ?? 'campaign'}`"
            :label="attachment.label"
            tone="info"
          />
        </div>

        <div v-if="editingNoteId === note.id" class="mt-3 space-y-2">
          <div class="flex items-center gap-2 text-sm">
            <input
              :checked="editAttachToCampaign"
              type="checkbox"
              class="rounded border-[var(--yife-border)]"
              @change="editAttachToCampaign = ($event.target as HTMLInputElement).checked"
            />
            <span>Attach to campaign</span>
          </div>
          <div class="space-y-1 text-sm">
            <label
              v-for="entity in summariesQuery.data.value ?? []"
              :key="entity.entity_id"
              class="flex items-center gap-2"
            >
              <input
                :checked="editEntityIds.includes(entity.entity_id)"
                type="checkbox"
                class="rounded border-[var(--yife-border)]"
                @change="editEntityIds = toggleEntitySelection(editEntityIds, entity.entity_id, ($event.target as HTMLInputElement).checked)"
              />
              <span>{{ entity.list_caption }}</span>
            </label>
          </div>
          <YRichTextEditor v-model="editDraft" :campaign-id="campaignId" />
          <div class="flex gap-2">
            <YIconButton :icon="Save" label="Save note" :disabled="!hasEditTarget" @click="submitEdit(note)" />
            <YIconButton :icon="X" label="Cancel note edit" @click="cancelEdit" />
          </div>
        </div>
        <YRichTextViewer
          v-else
          :campaign-id="campaignId"
          :document="note.body_json as Record<string, unknown>"
          class="mt-3"
        />
      </article>
    </div>
  </YPanelSurface>
</template>
