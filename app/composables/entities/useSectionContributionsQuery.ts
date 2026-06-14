import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { SectionContribution } from './types';

export function useSectionContributionsQuery(
  sectionId: MaybeRefOrGetter<string | null>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.sectionContributions(
        toValue(sectionId) ?? 'none',
        options?.previewAsPlayer ? Boolean(toValue(options.previewAsPlayer)) : false,
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(sectionId)) && (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(sectionId);

      if (!id) {
        throw new Error('Section id is required.');
      }

      const { data, error } = await client.rpc('get_section_contributions', {
        p_section_id: id,
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as SectionContribution[];
    },
  });
}
