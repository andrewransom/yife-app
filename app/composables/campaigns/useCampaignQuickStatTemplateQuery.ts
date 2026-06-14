import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import type { CampaignQuickStatTemplate } from './types';
import { campaignQueryKeys } from './keys';

export function useCampaignQuickStatTemplateQuery(
  campaignId: MaybeRefOrGetter<string>,
  templateKind: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      campaignQueryKeys.quickStatTemplate(toValue(campaignId), toValue(templateKind)),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        Boolean(toValue(templateKind)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client
        .from('campaign_quick_stat_templates')
        .select('*')
        .eq('campaign_id', toValue(campaignId))
        .eq('template_kind', toValue(templateKind))
        .order('is_active', { ascending: false })
        .order('created_at', { ascending: true })
        .limit(1);

      if (error) {
        throw error;
      }

      return (data?.[0] ?? null) as CampaignQuickStatTemplate | null;
    },
  });
}
