import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import type { CampaignQuickStatField } from './types';
import { campaignQueryKeys } from './keys';

export function useCampaignQuickStatFieldsQuery(
  campaignId: MaybeRefOrGetter<string>,
  templateId: MaybeRefOrGetter<string | null | undefined>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      campaignQueryKeys.quickStatFields(
        toValue(campaignId),
        toValue(templateId) || 'missing',
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(templateId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client
        .from('campaign_quick_stat_fields')
        .select('*')
        .eq('template_id', toValue(templateId) || '')
        .order('sort_order', { ascending: true })
        .order('label', { ascending: true });

      if (error) {
        throw error;
      }

      return (data ?? []) as CampaignQuickStatField[];
    },
  });
}
