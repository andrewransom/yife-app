<script setup lang="ts">
import { computed } from 'vue';
import { navigateTo } from '#imports';
import { useUiStore } from '~/stores/ui';
import { useMyCampaignsQuery } from '~/composables/campaigns/useMyCampaignsQuery';

const props = withDefaults(
  defineProps<{
    currentCampaignId?: string | null;
    enabled?: boolean;
  }>(),
  {
    currentCampaignId: null,
    enabled: true,
  },
);

const uiStore = useUiStore();
const campaignsQuery = useMyCampaignsQuery({
  enabled: computed(() => props.enabled),
});
const campaigns = computed(() => campaignsQuery.data.value ?? []);
const isPending = computed(() => campaignsQuery.isPending.value);

const selectedCampaign = computed(() =>
  campaigns.value.find((campaign) => campaign.campaign_id === props.currentCampaignId),
);

const contextLabel = computed(() => {
  if (!selectedCampaign.value) {
    return 'No campaign selected';
  }

  const role = selectedCampaign.value.role_keys[0] ?? 'member';
  return `${selectedCampaign.value.status_label} · ${role}`;
});

async function switchCampaign(event: Event) {
  const campaignId = (event.target as HTMLSelectElement).value;

  if (!campaignId || campaignId === props.currentCampaignId) {
    return;
  }

  uiStore.selectCampaign(campaignId);
  await navigateTo(`/campaigns/${campaignId}`);
}
</script>

<template>
  <div class="min-w-0">
    <label class="sr-only" for="campaign-switcher">Campaign</label>
    <select
      id="campaign-switcher"
      class="h-8 max-w-56 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
      :value="currentCampaignId || ''"
      :disabled="isPending || !campaigns.length"
      @change="switchCampaign"
    >
      <option value="" disabled>Campaign</option>
      <option
        v-for="campaign in campaigns"
        :key="campaign.campaign_id"
        :value="campaign.campaign_id"
      >
        {{ campaign.name }}
      </option>
    </select>
    <p class="mt-0.5 truncate text-[11px] text-[var(--yife-text-muted)]">{{ contextLabel }}</p>
  </div>
</template>
