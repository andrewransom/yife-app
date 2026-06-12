import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useMyCampaignsQuery } from './useMyCampaignsQuery';

export function useCampaignByIdQuery(
  campaignId: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const campaignsQuery = useMyCampaignsQuery({
    enabled: computed(() => {
      const id = toValue(campaignId);
      return Boolean(id) && (options?.enabled === undefined || toValue(options.enabled));
    }),
  });

  return {
    ...campaignsQuery,
    data: computed(() =>
      campaignsQuery.data.value?.find((campaign) => campaign.campaign_id === toValue(campaignId)),
    ),
  };
}
