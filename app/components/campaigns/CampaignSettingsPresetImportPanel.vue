<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { Download, RefreshCcw } from 'lucide-vue-next';
import { useImportCampaignPresetPackMutation } from '~/composables/campaigns/useCampaignSettingsMutations';
import { useOptionPresetPacksQuery } from '~/composables/campaigns/useOptionPresetPacksQuery';

const props = defineProps<{
  campaignId: string;
  canManage: boolean;
}>();

const selectedPackKey = ref('');
const formError = ref('');
const presetPacksQuery = useOptionPresetPacksQuery();
const importPresetPack = useImportCampaignPresetPackMutation();
const presetPacks = computed(() => presetPacksQuery.data.value ?? []);
const isImporting = computed(() => importPresetPack.isPending.value);

watch(
  presetPacks,
  (packs) => {
    if (!selectedPackKey.value) {
      selectedPackKey.value = packs[0]?.key ?? '';
    }
  },
  { immediate: true },
);

async function handleImport() {
  formError.value = '';

  if (!selectedPackKey.value) {
    formError.value = 'Choose a preset pack.';
    return;
  }

  try {
    await importPresetPack.mutateAsync({
      campaignId: props.campaignId,
      presetPackKey: selectedPackKey.value,
    });
  } catch (error) {
    formError.value = error instanceof Error ? error.message : 'Preset import failed.';
  }
}
</script>

<template>
  <YPanelSurface heading="Preset Packs">
    <div class="space-y-3">
      <p class="text-sm text-[var(--yife-text-muted)]">
        Import seeded palette, symbol, option, and quick stat defaults. Duplicate keys are skipped.
      </p>

      <div class="grid gap-3 md:grid-cols-[1fr_auto]">
        <YFormField label="Preset pack" name="presetPack">
          <select
            v-model="selectedPackKey"
            :disabled="!canManage || !presetPacks.length || isImporting"
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
          >
            <option value="" disabled>Select pack</option>
            <option v-for="pack in presetPacks" :key="pack.id" :value="pack.key">
              {{ pack.label }}
            </option>
          </select>
        </YFormField>

        <div class="flex items-end justify-end">
          <YDenseButton
            color="primary"
            :disabled="!canManage || !selectedPackKey || isImporting"
            :loading="isImporting"
            @click="handleImport"
          >
            <Download class="size-4" aria-hidden="true" />
            Import
          </YDenseButton>
        </div>
      </div>

      <div class="flex flex-wrap gap-2 text-xs text-[var(--yife-text-muted)]">
        <span
          v-for="pack in presetPacks"
          :key="pack.id"
          class="rounded-[4px] border border-[var(--yife-border)] px-2 py-1"
        >
          {{ pack.label }}
        </span>
      </div>

      <p v-if="formError" class="text-sm text-[var(--yife-error)]">{{ formError }}</p>
      <p
        v-else-if="importPresetPack.isSuccess.value"
        class="text-sm text-[var(--yife-success)]"
      >
        Preset import complete.
      </p>

      <div v-if="canManage" class="flex justify-end">
        <YDenseButton
          variant="ghost"
          :disabled="presetPacksQuery.isFetching.value"
          @click="presetPacksQuery.refetch()"
        >
          <RefreshCcw class="size-4" aria-hidden="true" />
          Refresh
        </YDenseButton>
      </div>
    </div>
  </YPanelSurface>
</template>
