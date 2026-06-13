import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import type { AppSymbolIconKey } from './types';
import { campaignQueryKeys } from './keys';

export function useAppSymbolIconKeysQuery() {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: campaignQueryKeys.symbolIconKeys(),
    queryFn: async () => {
      const { data, error } = await client
        .from('app_symbol_icon_keys')
        .select('*')
        .order('key', { ascending: true });

      if (error) {
        throw error;
      }

      return (data ?? []) as AppSymbolIconKey[];
    },
  });
}
