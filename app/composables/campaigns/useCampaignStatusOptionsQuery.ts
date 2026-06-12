import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { campaignQueryKeys } from './keys';
import type { CampaignStatusOption } from './types';

export function useCampaignStatusOptionsQuery() {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: campaignQueryKeys.statuses(),
    queryFn: async () => {
      const { data, error } = await client
        .from('status_definitions')
        .select('id,key,label,sort_order')
        .eq('subject_key', 'campaign')
        .is('entity_type_id', null)
        .is('campaign_id', null)
        .eq('is_active', true)
        .order('sort_order', { ascending: true })
        .returns<CampaignStatusOption[]>();

      if (error) {
        throw error;
      }

      return data ?? [];
    },
  });
}
