<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue';
import { Pencil, Plus, Save, X } from 'lucide-vue-next';
import { useCampaignQuickStatFieldsQuery } from '~/composables/campaigns/useCampaignQuickStatFieldsQuery';
import { useCampaignQuickStatTemplateQuery } from '~/composables/campaigns/useCampaignQuickStatTemplateQuery';
import {
  useSaveCampaignQuickStatFieldMutation,
  useSaveCampaignQuickStatTemplateMutation,
} from '~/composables/campaigns/useCampaignSettingsMutations';
import {
  characterQuickStatVisibilityOptions,
  nextSortOrder,
  slugifyCampaignSettingKey,
} from '~/utils/campaign-settings';

const props = defineProps<{
  campaignId: string;
  templateKind: 'character' | 'npc_statblock';
  heading: string;
  description: string;
  canManage: boolean;
}>();

const templateQuery = useCampaignQuickStatTemplateQuery(props.campaignId, () => props.templateKind);
const template = computed(() => templateQuery.data.value);
const fieldsQuery = useCampaignQuickStatFieldsQuery(
  () => props.campaignId,
  computed(() => template.value?.id ?? null),
  {
    enabled: computed(() => Boolean(template.value?.id)),
  },
);
const saveTemplate = useSaveCampaignQuickStatTemplateMutation();
const saveField = useSaveCampaignQuickStatFieldMutation();
const templateError = ref('');
const fieldError = ref('');
const templateLabel = ref('');
const editingFieldId = ref<string | null>(null);
const fieldDraft = reactive({
  label: '',
  key: '',
  compactLabel: '',
  valueType: 'number',
  defaultVisibility: props.templateKind === 'character' ? 'character_owner_gm' : 'gm_only',
  minValue: '',
  maxValue: '',
  sortOrder: 10,
  isActive: true,
});

const fields = computed(() => fieldsQuery.data.value ?? []);
const isSavingTemplate = computed(() => saveTemplate.isPending.value);
const isSavingField = computed(() => saveField.isPending.value);

watch(
  template,
  (value) => {
    templateLabel.value = value?.label ?? props.heading;
  },
  { immediate: true },
);

function resetFieldDraft() {
  editingFieldId.value = null;
  fieldDraft.label = '';
  fieldDraft.key = '';
  fieldDraft.compactLabel = '';
  fieldDraft.valueType = 'number';
  fieldDraft.defaultVisibility =
    props.templateKind === 'character' ? 'character_owner_gm' : 'gm_only';
  fieldDraft.minValue = '';
  fieldDraft.maxValue = '';
  fieldDraft.sortOrder = nextSortOrder(fields.value);
  fieldDraft.isActive = true;
  fieldError.value = '';
}

function startEditField(field: (typeof fields.value)[number]) {
  editingFieldId.value = field.id;
  fieldDraft.label = field.label;
  fieldDraft.key = field.key;
  fieldDraft.compactLabel = field.compact_label;
  fieldDraft.valueType = field.value_type;
  fieldDraft.defaultVisibility = field.default_visibility;
  fieldDraft.minValue = field.min_value === null ? '' : String(field.min_value);
  fieldDraft.maxValue = field.max_value === null ? '' : String(field.max_value);
  fieldDraft.sortOrder = field.sort_order;
  fieldDraft.isActive = field.is_active;
  fieldError.value = '';
}

async function submitTemplate() {
  templateError.value = '';

  if (!templateLabel.value.trim()) {
    templateError.value = 'Template label is required.';
    return;
  }

  try {
    await saveTemplate.mutateAsync({
      campaignId: props.campaignId,
      templateId: template.value?.id ?? null,
      input: {
        template_kind: props.templateKind,
        label: templateLabel.value.trim(),
        is_active: true,
      },
    });
  } catch (error) {
    templateError.value =
      error instanceof Error ? error.message : 'Template could not be saved.';
  }
}

async function submitField() {
  fieldError.value = '';

  if (!template.value?.id) {
    fieldError.value = 'Save the template before adding fields.';
    return;
  }

  if (!fieldDraft.label.trim()) {
    fieldError.value = 'Field label is required.';
    return;
  }

  if (!fieldDraft.compactLabel.trim()) {
    fieldError.value = 'Compact label is required.';
    return;
  }

  try {
    await saveField.mutateAsync({
      campaignId: props.campaignId,
      fieldId: editingFieldId.value,
      input: {
        template_id: template.value.id,
        key: slugifyCampaignSettingKey(fieldDraft.key || fieldDraft.label, 'stat'),
        label: fieldDraft.label.trim(),
        compact_label: fieldDraft.compactLabel.trim(),
        value_type: fieldDraft.valueType,
        default_visibility:
          props.templateKind === 'character' ? fieldDraft.defaultVisibility : 'gm_only',
        min_value: fieldDraft.minValue === '' ? null : Number(fieldDraft.minValue),
        max_value: fieldDraft.maxValue === '' ? null : Number(fieldDraft.maxValue),
        sort_order: Number(fieldDraft.sortOrder) || 10,
        is_active: fieldDraft.isActive,
      },
    });
    resetFieldDraft();
  } catch (error) {
    fieldError.value = error instanceof Error ? error.message : 'Field could not be saved.';
  }
}
</script>

<template>
  <YPanelSurface :heading="heading">
    <div class="space-y-3">
      <p class="text-sm text-[var(--yife-text-muted)]">{{ description }}</p>

      <div
        class="grid gap-3 border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3 md:grid-cols-[1fr_auto]"
      >
        <YFormField label="Template label" name="templateLabel">
          <UInput v-model="templateLabel" size="sm" autocomplete="off" :disabled="!canManage" />
        </YFormField>

        <div class="flex items-end justify-end">
          <YDenseButton
            color="primary"
            :disabled="!canManage || isSavingTemplate"
            :loading="isSavingTemplate"
            @click="submitTemplate"
          >
            <Save class="size-4" aria-hidden="true" />
            Save template
          </YDenseButton>
        </div>

        <p v-if="templateError" class="md:col-span-2 text-sm text-[var(--yife-error)]">
          {{ templateError }}
        </p>
      </div>

      <div class="flex items-center justify-between gap-2">
        <h3 class="text-sm font-medium">Fields</h3>
        <YDenseButton v-if="canManage" variant="ghost" :disabled="isSavingField" @click="resetFieldDraft">
          <Plus class="size-4" aria-hidden="true" />
          Add field
        </YDenseButton>
      </div>

      <div class="space-y-2">
        <div
          v-for="field in fields"
          :key="field.id"
          class="flex items-center gap-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 py-1.5 text-sm"
        >
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <span class="font-medium">{{ field.label }}</span>
              <span class="text-xs text-[var(--yife-text-muted)]">{{ field.compact_label }}</span>
              <span class="text-xs text-[var(--yife-text-muted)]">{{ field.value_type }}</span>
              <span v-if="!field.is_active" class="text-xs text-[var(--yife-warning)]">
                Inactive
              </span>
            </div>
          </div>
          <span class="text-xs text-[var(--yife-text-muted)]">{{ field.sort_order }}</span>
          <YDenseButton
            v-if="canManage"
            variant="ghost"
            :disabled="isSavingField"
            @click="startEditField(field)"
          >
            <Pencil class="size-4" aria-hidden="true" />
            Edit
          </YDenseButton>
        </div>

        <YEmptyState
          v-if="!fields.length"
          heading="No fields"
          text="Save a compact template field to define quick stats."
        />
      </div>

      <div class="grid gap-3 border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3 md:grid-cols-2">
        <YFormField label="Field label" name="fieldLabel">
          <UInput v-model="fieldDraft.label" size="sm" autocomplete="off" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Key" name="fieldKey" hint="Blank uses a slug from the label.">
          <UInput v-model="fieldDraft.key" size="sm" autocomplete="off" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Compact label" name="fieldCompactLabel">
          <UInput
            v-model="fieldDraft.compactLabel"
            size="sm"
            autocomplete="off"
            :disabled="!canManage"
          />
        </YFormField>

        <YFormField label="Value type" name="fieldValueType">
          <select
            v-model="fieldDraft.valueType"
            :disabled="!canManage"
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option value="number">Number</option>
            <option value="text">Text</option>
          </select>
        </YFormField>

        <YFormField
          v-if="templateKind === 'character'"
          label="Default visibility"
          name="fieldVisibility"
        >
          <select
            v-model="fieldDraft.defaultVisibility"
            :disabled="!canManage"
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option
              v-for="visibility in characterQuickStatVisibilityOptions"
              :key="visibility.value"
              :value="visibility.value"
            >
              {{ visibility.label }}
            </option>
          </select>
        </YFormField>

        <YFormField v-else label="Default visibility" name="fieldVisibility">
          <div class="flex h-8 items-center text-sm text-[var(--yife-text-muted)]">GM only</div>
        </YFormField>

        <YFormField label="Sort order" name="fieldSortOrder">
          <UInput v-model="fieldDraft.sortOrder" type="number" size="sm" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Min value" name="fieldMinValue">
          <UInput
            v-model="fieldDraft.minValue"
            :type="fieldDraft.valueType === 'number' ? 'number' : 'text'"
            size="sm"
            :disabled="!canManage || fieldDraft.valueType !== 'number'"
          />
        </YFormField>

        <YFormField label="Max value" name="fieldMaxValue">
          <UInput
            v-model="fieldDraft.maxValue"
            :type="fieldDraft.valueType === 'number' ? 'number' : 'text'"
            size="sm"
            :disabled="!canManage || fieldDraft.valueType !== 'number'"
          />
        </YFormField>

        <YFormField label="Active" name="fieldActive">
          <label class="flex h-8 items-center gap-2 text-sm">
            <input v-model="fieldDraft.isActive" type="checkbox" :disabled="!canManage" />
            Use for new values
          </label>
        </YFormField>

        <p v-if="fieldError" class="md:col-span-2 text-sm text-[var(--yife-error)]">
          {{ fieldError }}
        </p>

        <div class="flex items-center justify-end gap-2 md:col-span-2">
          <YDenseButton variant="ghost" :disabled="isSavingField" @click="resetFieldDraft">
            <X class="size-4" aria-hidden="true" />
            Cancel
          </YDenseButton>
          <YDenseButton
            color="primary"
            :disabled="!canManage || isSavingField"
            :loading="isSavingField"
            @click="submitField"
          >
            <Save class="size-4" aria-hidden="true" />
            Save field
          </YDenseButton>
        </div>
      </div>
    </div>
  </YPanelSurface>
</template>
