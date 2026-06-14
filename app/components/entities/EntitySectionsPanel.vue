<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import { Edit3, Plus, Save, X } from 'lucide-vue-next';
import { useCreateContributionMutation, useDeleteContributionMutation, useSaveEntitySectionMutation, useUpdateContributionMutation } from '~/composables/entities/useRichTextMutations';
import { useEntitySectionsQuery } from '~/composables/entities/useEntitySectionsQuery';
import { useSectionContributionsQuery } from '~/composables/entities/useSectionContributionsQuery';
import { useYifeToast } from '~/composables/auth/useYifeToast';
import type { EntitySection, SectionContribution } from '~/composables/entities/types';
import { createDefaultRichTextDocument, extractRichText, isStaleConflictError } from '~/utils/rich-text';

const props = defineProps<{
  campaignId: string;
  entityId: string;
  canAddContribution?: boolean;
  activeRoleView?: 'gm' | 'player';
  isPlayerPreview?: boolean;
  isCharacterController?: boolean;
}>();

const toast = useYifeToast();
const sectionsQuery = useEntitySectionsQuery(() => props.entityId, {
  enabled: computed(() => Boolean(props.entityId)),
  previewAsPlayer: computed(() => props.isPlayerPreview === true),
});
const saveSection = useSaveEntitySectionMutation();
const createContribution = useCreateContributionMutation();
const updateContribution = useUpdateContributionMutation();
const deleteContribution = useDeleteContributionMutation();

const editingSectionId = ref<string | null>(null);
const sectionDraft = ref<Record<string, unknown>>(createDefaultRichTextDocument());
const composingContributionFor = ref<string | null>(null);
const contributionDraft = ref<Record<string, unknown>>(createDefaultRichTextDocument());
const editingContributionId = ref<string | null>(null);
const contributionEditDraft = ref<Record<string, unknown>>(createDefaultRichTextDocument());
const contributionQueries = reactive<Record<string, ReturnType<typeof useSectionContributionsQuery>>>({});

const sections = computed(() => sectionsQuery.data.value ?? []);
const visibleSections = computed(() =>
  sections.value.filter((section) => {
    if (props.activeRoleView !== 'player') {
      return true;
    }

    if (section.visibility === 'shared') {
      return true;
    }

    if (section.visibility === 'character_owner_gm') {
      return props.isCharacterController === true;
    }

    return false;
  }),
);

function contributionQuery(sectionId: string) {
  if (!contributionQueries[sectionId]) {
    contributionQueries[sectionId] = useSectionContributionsQuery(() => sectionId, {
      enabled: computed(() => true),
      previewAsPlayer: computed(() => props.isPlayerPreview === true),
    });
  }

  return contributionQueries[sectionId];
}

function supportsContributions(section: EntitySection) {
  return section.content_mode === 'contribution_feed' || section.edit_policy === 'append_contributions';
}

function canShowContributionComposer(section: EntitySection) {
  return supportsContributions(section) && props.canAddContribution !== false;
}

function visibleContributions(sectionId: string) {
  return (contributionQuery(sectionId).data.value ?? []).filter((contribution) => {
    if (props.activeRoleView !== 'player') {
      return true;
    }

    if (contribution.visibility === 'shared') {
      return true;
    }

    if (contribution.visibility === 'character_owner_gm') {
      return props.isCharacterController === true;
    }

    return false;
  });
}

function asDocument(value: unknown) {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : createDefaultRichTextDocument();
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}

function beginSectionEdit(section: EntitySection) {
  editingSectionId.value = section.id;
  sectionDraft.value = asDocument(section.body_json);
}

function cancelSectionEdit() {
  editingSectionId.value = null;
  sectionDraft.value = createDefaultRichTextDocument();
}

async function submitSection(section: EntitySection) {
  try {
    const content = extractRichText(sectionDraft.value);
    await saveSection.mutateAsync({
      entityId: props.entityId,
      sectionId: section.id,
      expectedVersion: section.version_number,
      content,
    });
    toast.success('Section saved');
    cancelSectionEdit();
  } catch (error) {
    toast.error(
      isStaleConflictError(error) ? 'Section changed. Reload before saving again.' : 'Section save failed',
    );
  }
}

function beginContribution(section: EntitySection) {
  composingContributionFor.value = section.id;
  contributionDraft.value = createDefaultRichTextDocument();
}

function cancelContribution() {
  composingContributionFor.value = null;
  contributionDraft.value = createDefaultRichTextDocument();
}

async function submitContribution(section: EntitySection) {
  try {
    await createContribution.mutateAsync({
      entityId: props.entityId,
      sectionId: section.id,
      visibility: section.visibility,
      content: extractRichText(contributionDraft.value),
    });
    toast.success('Contribution saved');
    cancelContribution();
  } catch {
    toast.error('Contribution save failed');
  }
}

function beginContributionEdit(contribution: SectionContribution) {
  editingContributionId.value = contribution.id;
  contributionEditDraft.value = asDocument(contribution.body_json);
}

function cancelContributionEdit() {
  editingContributionId.value = null;
  contributionEditDraft.value = createDefaultRichTextDocument();
}

async function submitContributionEdit(sectionId: string, contribution: SectionContribution) {
  try {
    await updateContribution.mutateAsync({
      entityId: props.entityId,
      sectionId,
      contributionId: contribution.id,
      visibility: contribution.visibility,
      expectedVersion: contribution.version_number,
      content: extractRichText(contributionEditDraft.value),
    });
    toast.success('Contribution updated');
    cancelContributionEdit();
  } catch (error) {
    toast.error(
      isStaleConflictError(error)
        ? 'Contribution changed. Reload before saving again.'
        : 'Contribution update failed',
    );
  }
}

async function removeContribution(sectionId: string, contributionId: string) {
  try {
    await deleteContribution.mutateAsync({
      entityId: props.entityId,
      sectionId,
      contributionId,
    });
    toast.success('Contribution deleted');
  } catch {
    toast.error('Contribution delete failed');
  }
}
</script>

<template>
  <YPanelSurface heading="Sections">
    <YEmptyState
      v-if="sectionsQuery.isPending.value"
      heading="Loading sections"
      text="Fetching section content."
    />
    <div v-else class="space-y-3">
      <section
        v-for="section in visibleSections"
        :key="section.id"
        class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
      >
        <div class="flex items-center gap-2">
          <h3 class="min-w-0 flex-1 truncate text-sm font-semibold">{{ section.label }}</h3>
          <YVisibilityBadge :visibility="section.visibility" />
          <YStatusBadge v-if="supportsContributions(section)" label="Contributions" tone="info" />
          <YIconButton
            v-if="section.can_edit"
            :icon="Edit3"
            label="Edit section"
            @click="beginSectionEdit(section)"
          />
          <YIconButton
            v-if="canShowContributionComposer(section)"
            :icon="Plus"
            label="Add contribution"
            @click="beginContribution(section)"
          />
        </div>

        <div v-if="editingSectionId === section.id" class="mt-3 space-y-2">
          <YRichTextEditor
            v-model="sectionDraft"
            :campaign-id="campaignId"
            :active-role-view="activeRoleView"
          />
          <div class="flex gap-2">
            <YIconButton :icon="Save" label="Save section" @click="submitSection(section)" />
            <YIconButton :icon="X" label="Cancel section edit" @click="cancelSectionEdit" />
          </div>
          <p class="text-xs text-[var(--yife-text-muted)]">
            Save is version-checked. If someone else changed this content, reload is required.
          </p>
        </div>
        <YRichTextViewer
          v-else
          :campaign-id="campaignId"
          :document="section.body_json as Record<string, unknown>"
          class="mt-3"
        />

        <div v-if="supportsContributions(section)" class="mt-3 space-y-2">
          <template v-if="visibleContributions(section.id).length">
            <article
              v-for="contribution in visibleContributions(section.id)"
              :key="contribution.id"
              class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
            >
              <div class="flex flex-wrap items-center gap-2">
                <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">
                  {{ contribution.author_display_label || 'Member' }}
                </p>
                <YVisibilityBadge :visibility="contribution.visibility" />
                <YStatusBadge
                  :label="formatDateTime(contribution.updated_at)"
                  tone="neutral"
                />
                <div class="ml-auto flex gap-2" v-if="contribution.can_edit">
                  <button
                    type="button"
                    class="text-xs font-medium text-[var(--yife-link)] hover:underline"
                    @click="beginContributionEdit(contribution)"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    class="text-xs font-medium text-[var(--yife-error)] hover:underline"
                    @click="removeContribution(section.id, contribution.id)"
                  >
                    Delete
                  </button>
                </div>
              </div>

              <div v-if="editingContributionId === contribution.id" class="mt-3 space-y-2">
                <YRichTextEditor
                  v-model="contributionEditDraft"
                  :campaign-id="campaignId"
                  :active-role-view="activeRoleView"
                />
                <div class="flex gap-2">
                  <YIconButton
                    :icon="Save"
                    label="Save contribution"
                    @click="submitContributionEdit(section.id, contribution)"
                  />
                  <YIconButton
                    :icon="X"
                    label="Cancel contribution edit"
                    @click="cancelContributionEdit"
                  />
                </div>
              </div>
              <YRichTextViewer
                v-else
                :campaign-id="campaignId"
                :document="contribution.body_json as Record<string, unknown>"
                class="mt-2"
              />
            </article>
          </template>
          <p v-else class="text-sm text-[var(--yife-text-muted)]">No contributions yet.</p>

          <div
            v-if="composingContributionFor === section.id && canShowContributionComposer(section)"
            class="space-y-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3"
          >
            <YRichTextEditor
              v-model="contributionDraft"
              :campaign-id="campaignId"
              :active-role-view="activeRoleView"
            />
            <div class="flex gap-2">
              <YIconButton :icon="Save" label="Save contribution" @click="submitContribution(section)" />
              <YIconButton :icon="X" label="Cancel contribution" @click="cancelContribution" />
            </div>
          </div>
        </div>
      </section>
    </div>
  </YPanelSurface>
</template>
