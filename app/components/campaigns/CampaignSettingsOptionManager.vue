<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import { Pencil, Plus, Save, X } from 'lucide-vue-next';
import { useCampaignOptionGroupsQuery } from '~/composables/campaigns/useCampaignOptionGroupsQuery';
import { useSaveCampaignOptionMutation } from '~/composables/campaigns/useCampaignSettingsMutations';
import { useCampaignOptionsQuery } from '~/composables/entities/useCampaignOptionsQuery';
import { useCampaignPaletteColorsQuery } from '~/composables/entities/useCampaignPaletteColorsQuery';
import { useCampaignSymbolsQuery } from '~/composables/entities/useCampaignSymbolsQuery';
import type { CampaignOption } from '~/composables/entities/types';
import {
  groupCampaignOptions,
  nextSortOrder,
  slugifyCampaignSettingKey,
} from '~/utils/campaign-settings';

const props = defineProps<{
  campaignId: string;
  canManage: boolean;
}>();

type OptionDraft = {
  id: string | null;
  groupId: string;
  groupKey: string;
  label: string;
  key: string;
  description: string;
  sortOrder: number;
  defaultPaletteColorId: string;
  defaultSymbolId: string;
  isActive: boolean;
};

const formError = ref('');
const editingGroupKey = ref('');
const isAdvancedOpen = ref(false);
const draft = reactive<OptionDraft>({
  id: null,
  groupId: '',
  groupKey: '',
  label: '',
  key: '',
  description: '',
  sortOrder: 10,
  defaultPaletteColorId: '',
  defaultSymbolId: '',
  isActive: true,
});

const optionGroupsQuery = useCampaignOptionGroupsQuery(props.campaignId);
const optionsQuery = useCampaignOptionsQuery(props.campaignId, null, {
  includeInactive: true,
});
const paletteColorsQuery = useCampaignPaletteColorsQuery(props.campaignId, {
  includeInactive: true,
});
const symbolsQuery = useCampaignSymbolsQuery(props.campaignId, {
  includeInactive: true,
});
const saveOption = useSaveCampaignOptionMutation();

const optionGroups = computed(() => optionGroupsQuery.data.value ?? []);
const optionGroupsByKey = computed(
  () => new Map(optionGroups.value.map((group) => [group.key, group])),
);
const groupedOptions = computed(() => groupCampaignOptions(optionsQuery.data.value ?? []));
const coreGroups = computed(() => groupedOptions.value.filter((group) => group.section === 'core'));
const advancedGroups = computed(() =>
  groupedOptions.value.filter((group) => group.section === 'advanced'),
);
const paletteColors = computed(() => paletteColorsQuery.data.value ?? []);
const symbols = computed(() => symbolsQuery.data.value ?? []);
const isSaving = computed(() => saveOption.isPending.value);

function resetDraft() {
  draft.id = null;
  draft.groupId = '';
  draft.groupKey = '';
  draft.label = '';
  draft.key = '';
  draft.description = '';
  draft.sortOrder = 10;
  draft.defaultPaletteColorId = '';
  draft.defaultSymbolId = '';
  draft.isActive = true;
  editingGroupKey.value = '';
  formError.value = '';
}

function startCreate(groupKey: string) {
  const group = optionGroupsByKey.value.get(groupKey);

  if (!group) {
    return;
  }

  const existingOptions = groupedOptions.value.find((item) => item.key === groupKey)?.options ?? [];
  draft.id = null;
  draft.groupId = group.id;
  draft.groupKey = group.key;
  draft.label = '';
  draft.key = '';
  draft.description = '';
  draft.sortOrder = nextSortOrder(existingOptions);
  draft.defaultPaletteColorId = '';
  draft.defaultSymbolId = '';
  draft.isActive = true;
  editingGroupKey.value = groupKey;
  formError.value = '';
  if (advancedGroups.value.some((item) => item.key === groupKey)) {
    isAdvancedOpen.value = true;
  }
}

function startEdit(option: CampaignOption) {
  draft.id = option.id;
  draft.groupId = option.group_id;
  draft.groupKey = option.group_key;
  draft.label = option.label;
  draft.key = option.key;
  draft.description = option.description ?? '';
  draft.sortOrder = option.sort_order;
  draft.defaultPaletteColorId = option.default_palette_color_id ?? '';
  draft.defaultSymbolId = option.default_symbol_id ?? '';
  draft.isActive = option.is_active;
  editingGroupKey.value = option.group_key;
  formError.value = '';
  if (advancedGroups.value.some((item) => item.key === option.group_key)) {
    isAdvancedOpen.value = true;
  }
}

async function submit() {
  formError.value = '';

  if (!draft.groupId || !draft.groupKey) {
    formError.value = 'Option group is required.';
    return;
  }

  if (!draft.label.trim()) {
    formError.value = 'Option label is required.';
    return;
  }

  try {
    await saveOption.mutateAsync({
      campaignId: props.campaignId,
      optionId: draft.id,
      input: {
        group_id: draft.groupId,
        key: slugifyCampaignSettingKey(draft.key || draft.label, draft.groupKey),
        label: draft.label.trim(),
        description: draft.description.trim() || null,
        default_palette_color_id: draft.defaultPaletteColorId || null,
        default_symbol_id: draft.defaultSymbolId || null,
        is_active: draft.isActive,
        sort_order: Number(draft.sortOrder) || 10,
      },
    });
    resetDraft();
  } catch (error) {
    formError.value = error instanceof Error ? error.message : 'Option could not be saved.';
  }
}
</script>

<template>
  <YPanelSurface heading="Option Lists">
    <div class="space-y-4">
      <p class="text-sm text-[var(--yife-text-muted)]">
        One reusable manager for all 04.5 non-status option groups. Existing records keep inactive
        values.
      </p>

      <div class="space-y-3">
        <section
          v-for="group in coreGroups"
          :key="group.key"
          class="border border-[var(--yife-border)] bg-[var(--yife-surface-muted)]"
        >
          <header
            class="flex min-h-9 items-center justify-between gap-2 border-b border-[var(--yife-border)] px-3"
          >
            <h3 class="text-sm font-medium">{{ group.label }}</h3>
            <YDenseButton
              v-if="canManage"
              variant="ghost"
              :disabled="isSaving"
              @click="startCreate(group.key)"
            >
              <Plus class="size-4" aria-hidden="true" />
              Add option
            </YDenseButton>
          </header>
          <div class="space-y-2 p-3">
            <div
              v-for="option in group.options"
              :key="option.id"
              class="flex items-center gap-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 py-1.5 text-sm"
            >
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-medium">{{ option.label }}</span>
                  <span class="text-xs text-[var(--yife-text-muted)]">{{ option.key }}</span>
                  <span v-if="!option.is_active" class="text-xs text-[var(--yife-warning)]">
                    Inactive
                  </span>
                </div>
                <p v-if="option.description" class="text-xs text-[var(--yife-text-muted)]">
                  {{ option.description }}
                </p>
              </div>
              <span class="text-xs text-[var(--yife-text-muted)]">{{ option.sort_order }}</span>
              <YDenseButton
                v-if="canManage"
                variant="ghost"
                :disabled="isSaving"
                @click="startEdit(option)"
              >
                <Pencil class="size-4" aria-hidden="true" />
                Edit
              </YDenseButton>
            </div>

            <YEmptyState
              v-if="!group.options.length"
              heading="No options"
              text="Import a preset pack or add a campaign-owned value."
            />
          </div>
        </section>
      </div>

      <details
        :open="isAdvancedOpen"
        class="border border-[var(--yife-border)] bg-[var(--yife-surface)]"
        @toggle="isAdvancedOpen = ($event.target as HTMLDetailsElement).open"
      >
        <summary class="cursor-pointer px-3 py-2 text-sm font-medium">Advanced option groups</summary>
        <div class="space-y-3 border-t border-[var(--yife-border)] p-3">
          <section
            v-for="group in advancedGroups"
            :key="group.key"
            class="border border-[var(--yife-border)] bg-[var(--yife-surface-muted)]"
          >
            <header
              class="flex min-h-9 items-center justify-between gap-2 border-b border-[var(--yife-border)] px-3"
            >
              <h3 class="text-sm font-medium">{{ group.label }}</h3>
              <YDenseButton
                v-if="canManage"
                variant="ghost"
                :disabled="isSaving"
                @click="startCreate(group.key)"
              >
                <Plus class="size-4" aria-hidden="true" />
                Add option
              </YDenseButton>
            </header>
            <div class="space-y-2 p-3">
              <div
                v-for="option in group.options"
                :key="option.id"
                class="flex items-center gap-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 py-1.5 text-sm"
              >
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="font-medium">{{ option.label }}</span>
                    <span class="text-xs text-[var(--yife-text-muted)]">{{ option.key }}</span>
                    <span v-if="!option.is_active" class="text-xs text-[var(--yife-warning)]">
                      Inactive
                    </span>
                  </div>
                </div>
                <span class="text-xs text-[var(--yife-text-muted)]">{{ option.sort_order }}</span>
                <YDenseButton
                  v-if="canManage"
                  variant="ghost"
                  :disabled="isSaving"
                  @click="startEdit(option)"
                >
                  <Pencil class="size-4" aria-hidden="true" />
                  Edit
                </YDenseButton>
              </div>

              <YEmptyState
                v-if="!group.options.length"
                heading="No options"
                text="Import a preset pack or add a campaign-owned value."
              />
            </div>
          </section>
        </div>
      </details>

      <div
        v-if="editingGroupKey"
        class="grid gap-3 border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3 md:grid-cols-2"
      >
        <YFormField label="Label" name="optionLabel">
          <UInput v-model="draft.label" size="sm" autocomplete="off" />
        </YFormField>

        <YFormField label="Key" name="optionKey" hint="Blank uses a slug from the label.">
          <UInput v-model="draft.key" size="sm" autocomplete="off" />
        </YFormField>

        <YFormField label="Sort order" name="optionSortOrder">
          <UInput v-model="draft.sortOrder" type="number" size="sm" />
        </YFormField>

        <YFormField label="Active" name="optionActive">
          <label class="flex h-8 items-center gap-2 text-sm">
            <input v-model="draft.isActive" type="checkbox" />
            Use for new selections
          </label>
        </YFormField>

        <YFormField label="Default palette" name="optionPalette">
          <select
            v-model="draft.defaultPaletteColorId"
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option value="">None</option>
            <option
              v-for="paletteColor in paletteColors"
              :key="paletteColor.id"
              :value="paletteColor.id"
            >
              {{ paletteColor.label }}{{ paletteColor.is_active ? '' : ' (inactive)' }}
            </option>
          </select>
        </YFormField>

        <YFormField label="Default symbol" name="optionSymbol">
          <select
            v-model="draft.defaultSymbolId"
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option value="">None</option>
            <option v-for="symbol in symbols" :key="symbol.id" :value="symbol.id">
              {{ symbol.label }}{{ symbol.is_active ? '' : ' (inactive)' }}
            </option>
          </select>
        </YFormField>

        <div class="md:col-span-2">
          <YFormField label="Description" name="optionDescription">
            <UTextarea v-model="draft.description" :rows="2" size="sm" />
          </YFormField>
        </div>

        <p v-if="formError" class="md:col-span-2 text-sm text-[var(--yife-error)]">
          {{ formError }}
        </p>

        <div class="flex items-center justify-end gap-2 md:col-span-2">
          <YDenseButton variant="ghost" :disabled="isSaving" @click="resetDraft">
            <X class="size-4" aria-hidden="true" />
            Cancel
          </YDenseButton>
          <YDenseButton
            color="primary"
            :disabled="!canManage || isSaving"
            :loading="isSaving"
            @click="submit"
          >
            <Save class="size-4" aria-hidden="true" />
            Save option
          </YDenseButton>
        </div>
      </div>
    </div>
  </YPanelSurface>
</template>
