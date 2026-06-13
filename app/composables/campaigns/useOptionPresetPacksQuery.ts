import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import type { OptionPresetPack } from './types';
import { campaignQueryKeys } from './keys';

export function useOptionPresetPacksQuery() {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: campaignQueryKeys.presetPacks(),
    queryFn: async () => {
      const { data, error } = await client
        .from('option_preset_packs')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', { ascending: true })
        .order('label', { ascending: true });

      if (error) {
        throw error;
      }

      return (data ?? []) as OptionPresetPack[];
    },
  });
}
