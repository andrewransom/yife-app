<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import { Pencil, Plus, Save, X } from 'lucide-vue-next';
import { useSaveCampaignPaletteColorMutation } from '~/composables/campaigns/useCampaignSettingsMutations';
import { useCampaignPaletteColorsQuery } from '~/composables/entities/useCampaignPaletteColorsQuery';
import {
  getPaletteTokenStyle,
  nextSortOrder,
  paletteTokenOptions,
  slugifyCampaignSettingKey,
} from '~/utils/campaign-settings';

const props = defineProps<{
  campaignId: string;
  canManage: boolean;
}>();

const colorsQuery = useCampaignPaletteColorsQuery(props.campaignId, {
  includeInactive: true,
});
const savePaletteColor = useSaveCampaignPaletteColorMutation();
const formError = ref('');
const editingId = ref<string | null>(null);
const draft = reactive({
  label: '',
  key: '',
  colorToken: 'red',
  sortOrder: 10,
  isActive: true,
});
const colors = computed(() => colorsQuery.data.value ?? []);
const isSaving = computed(() => savePaletteColor.isPending.value);

function resetDraft() {
  editingId.value = null;
  draft.label = '';
  draft.key = '';
  draft.colorToken = 'red';
  draft.sortOrder = 10;
  draft.isActive = true;
  formError.value = '';
}

function startCreate() {
  resetDraft();
  draft.sortOrder = nextSortOrder(colors.value);
}

function startEdit(color: (typeof colors.value)[number]) {
  editingId.value = color.id;
  draft.label = color.label;
  draft.key = color.key;
  draft.colorToken = color.color_token;
  draft.sortOrder = color.sort_order;
  draft.isActive = color.is_active;
  formError.value = '';
}

async function submit() {
  formError.value = '';

  if (!draft.label.trim()) {
    formError.value = 'Palette label is required.';
    return;
  }

  try {
    await savePaletteColor.mutateAsync({
      campaignId: props.campaignId,
      paletteColorId: editingId.value,
      input: {
        key: slugifyCampaignSettingKey(draft.key || draft.label, 'palette'),
        label: draft.label.trim(),
        color_token: draft.colorToken,
        sort_order: Number(draft.sortOrder) || 10,
        is_active: draft.isActive,
      },
    });
    resetDraft();
  } catch (error) {
    formError.value = error instanceof Error ? error.message : 'Palette color could not be saved.';
  }
}
</script>

<template>
  <YPanelSurface heading="Palette Colors">
    <div class="space-y-3">
      <div class="flex items-center justify-between gap-2">
        <p class="text-sm text-[var(--yife-text-muted)]">
          Constrained to known campaign color tokens.
        </p>
        <YDenseButton v-if="canManage" variant="ghost" :disabled="isSaving" @click="startCreate">
          <Plus class="size-4" aria-hidden="true" />
          Add color
        </YDenseButton>
      </div>

      <div class="space-y-2">
        <div
          v-for="color in colors"
          :key="color.id"
          class="flex items-center gap-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 py-1.5 text-sm"
        >
          <span
            class="inline-flex min-w-18 items-center justify-center rounded-[4px] px-2 py-1 text-xs font-medium"
            :style="getPaletteTokenStyle(color.color_token)"
          >
            {{ color.color_token }}
          </span>
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <span class="font-medium">{{ color.label }}</span>
              <span class="text-xs text-[var(--yife-text-muted)]">{{ color.key }}</span>
              <span v-if="!color.is_active" class="text-xs text-[var(--yife-warning)]">
                Inactive
              </span>
            </div>
          </div>
          <span class="text-xs text-[var(--yife-text-muted)]">{{ color.sort_order }}</span>
          <YDenseButton
            v-if="canManage"
            variant="ghost"
            :disabled="isSaving"
            @click="startEdit(color)"
          >
            <Pencil class="size-4" aria-hidden="true" />
            Edit
          </YDenseButton>
        </div>
      </div>

      <div class="grid gap-3 border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3 md:grid-cols-2">
        <YFormField label="Label" name="paletteLabel">
          <UInput v-model="draft.label" size="sm" autocomplete="off" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Key" name="paletteKey" hint="Blank uses a slug from the label.">
          <UInput v-model="draft.key" size="sm" autocomplete="off" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Color token" name="paletteToken">
          <select
            v-model="draft.colorToken"
            :disabled="!canManage"
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option v-for="option in paletteTokenOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </YFormField>

        <YFormField label="Sort order" name="paletteSortOrder">
          <UInput v-model="draft.sortOrder" type="number" size="sm" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Active" name="paletteActive">
          <label class="flex h-8 items-center gap-2 text-sm">
            <input v-model="draft.isActive" type="checkbox" :disabled="!canManage" />
            Use for new selections
          </label>
        </YFormField>

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
            Save color
          </YDenseButton>
        </div>
      </div>
    </div>
  </YPanelSurface>
</template>
