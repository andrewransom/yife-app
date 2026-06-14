<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue';
import { Pencil, Plus, Save, X } from 'lucide-vue-next';
import { useAppSymbolIconKeysQuery } from '~/composables/campaigns/useAppSymbolIconKeysQuery';
import { useSaveCampaignSymbolMutation } from '~/composables/campaigns/useCampaignSettingsMutations';
import { useCampaignSymbolsQuery } from '~/composables/entities/useCampaignSymbolsQuery';
import { nextSortOrder, slugifyCampaignSettingKey } from '~/utils/campaign-settings';

const props = defineProps<{
  campaignId: string;
  canManage: boolean;
}>();

const symbolsQuery = useCampaignSymbolsQuery(props.campaignId, {
  includeInactive: true,
});
const iconKeysQuery = useAppSymbolIconKeysQuery();
const saveSymbol = useSaveCampaignSymbolMutation();
const formError = ref('');
const editingId = ref<string | null>(null);
const draft = reactive({
  label: '',
  key: '',
  iconKey: 'book-open',
  sortOrder: 10,
  isActive: true,
});
const symbols = computed(() => symbolsQuery.data.value ?? []);
const iconKeys = computed(() => iconKeysQuery.data.value ?? []);
const isSaving = computed(() => saveSymbol.isPending.value);

watch(
  iconKeys,
  (items) => {
    if (!items.length) {
      return;
    }

    if (!items.some((item) => item.key === draft.iconKey)) {
      draft.iconKey = items[0]?.key ?? 'book-open';
    }
  },
  { immediate: true },
);

function resetDraft() {
  editingId.value = null;
  draft.label = '';
  draft.key = '';
  draft.iconKey = iconKeys.value[0]?.key ?? 'book-open';
  draft.sortOrder = 10;
  draft.isActive = true;
  formError.value = '';
}

function startCreate() {
  resetDraft();
  draft.sortOrder = nextSortOrder(symbols.value);
}

function startEdit(symbol: (typeof symbols.value)[number]) {
  editingId.value = symbol.id;
  draft.label = symbol.label;
  draft.key = symbol.key;
  draft.iconKey = symbol.icon_key;
  draft.sortOrder = symbol.sort_order;
  draft.isActive = symbol.is_active;
  formError.value = '';
}

async function submit() {
  formError.value = '';

  if (!draft.label.trim()) {
    formError.value = 'Symbol label is required.';
    return;
  }

  try {
    await saveSymbol.mutateAsync({
      campaignId: props.campaignId,
      symbolId: editingId.value,
      input: {
        key: slugifyCampaignSettingKey(draft.key || draft.label, 'symbol'),
        label: draft.label.trim(),
        icon_key: draft.iconKey,
        sort_order: Number(draft.sortOrder) || 10,
        is_active: draft.isActive,
      },
    });
    resetDraft();
  } catch (error) {
    formError.value = error instanceof Error ? error.message : 'Symbol could not be saved.';
  }
}
</script>

<template>
  <YPanelSurface heading="Symbols">
    <div class="space-y-3">
      <div class="flex items-center justify-between gap-2">
        <p class="text-sm text-[var(--yife-text-muted)]">
          Constrained to seeded app icon keys.
        </p>
        <YDenseButton v-if="canManage" variant="ghost" :disabled="isSaving" @click="startCreate">
          <Plus class="size-4" aria-hidden="true" />
          Add symbol
        </YDenseButton>
      </div>

      <div class="space-y-2">
        <div
          v-for="symbol in symbols"
          :key="symbol.id"
          class="flex items-center gap-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 py-1.5 text-sm"
        >
          <span class="rounded-[4px] border border-[var(--yife-border)] px-2 py-1 text-xs">
            {{ symbol.icon_key }}
          </span>
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <span class="font-medium">{{ symbol.label }}</span>
              <span class="text-xs text-[var(--yife-text-muted)]">{{ symbol.key }}</span>
              <span v-if="!symbol.is_active" class="text-xs text-[var(--yife-warning)]">
                Inactive
              </span>
            </div>
          </div>
          <span class="text-xs text-[var(--yife-text-muted)]">{{ symbol.sort_order }}</span>
          <YDenseButton
            v-if="canManage"
            variant="ghost"
            :disabled="isSaving"
            @click="startEdit(symbol)"
          >
            <Pencil class="size-4" aria-hidden="true" />
            Edit
          </YDenseButton>
        </div>
      </div>

      <div class="grid gap-3 border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3 md:grid-cols-2">
        <YFormField label="Label" name="symbolLabel">
          <UInput v-model="draft.label" size="sm" autocomplete="off" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Key" name="symbolKey" hint="Blank uses a slug from the label.">
          <UInput v-model="draft.key" size="sm" autocomplete="off" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Icon key" name="symbolIconKey">
          <select
            v-model="draft.iconKey"
            :disabled="!canManage"
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option v-for="iconKey in iconKeys" :key="iconKey.key" :value="iconKey.key">
              {{ iconKey.key }}
            </option>
          </select>
        </YFormField>

        <YFormField label="Sort order" name="symbolSortOrder">
          <UInput v-model="draft.sortOrder" type="number" size="sm" :disabled="!canManage" />
        </YFormField>

        <YFormField label="Active" name="symbolActive">
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
            Save symbol
          </YDenseButton>
        </div>
      </div>
    </div>
  </YPanelSurface>
</template>
