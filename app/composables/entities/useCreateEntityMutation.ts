import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { useUiStore } from '~/stores/ui';
import type { Json } from '~/types/database.types';
import { entityQueryKeys } from './keys';
import type { CreateEntityInput } from './types';

export function useCreateEntityMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();
  const uiStore = useUiStore();

  return useMutation({
    mutationFn: async ({ campaignId, entityTypeKey, input }: CreateEntityInput) => {
      const { data, error } = await client.rpc('create_campaign_entity', {
        p_campaign_id: campaignId,
        p_entity_type_key: entityTypeKey,
        p_input: input as Json,
      });

      if (error) {
        throw error;
      }

      const created = data?.[0];

      if (!created) {
        throw new Error('Entity was not returned after creation.');
      }

      return created;
    },
    onSuccess: async (created) => {
      uiStore.selectEntity(created.entity_id);
      await queryClient.invalidateQueries({
        queryKey: entityQueryKeys.summaries(created.campaign_id),
      });
      await queryClient.invalidateQueries({
        queryKey: entityQueryKeys.detail(created.entity_id),
      });
    },
  });
}
