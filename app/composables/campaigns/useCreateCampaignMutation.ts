import { navigateTo } from '#imports';
import { useQueryClient, useMutation } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { useUiStore } from '~/stores/ui';
import type { CreateCampaignFormOutput } from '~/utils/campaign-validation';
import { campaignQueryKeys } from './keys';

export function useCreateCampaignMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();
  const uiStore = useUiStore();

  return useMutation({
    mutationFn: async (input: CreateCampaignFormOutput) => {
      const { data, error } = await client.rpc('create_campaign', {
        p_name: input.name,
        p_start_date: input.startDate,
        p_description: input.description,
        p_end_date: input.endDate,
      });

      if (error) {
        throw error;
      }

      const created = data?.[0];

      if (!created) {
        throw new Error('Campaign was not returned after creation.');
      }

      return created;
    },
    onSuccess: async (created) => {
      uiStore.selectCampaign(created.campaign_id);
      await queryClient.invalidateQueries({ queryKey: campaignQueryKeys.mine() });
      await navigateTo(`/campaigns/${created.campaign_id}`);
    },
  });
}
