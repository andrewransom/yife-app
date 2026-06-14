import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type {
  CreateEntityRelationshipInput,
  DeleteEntityRelationshipInput,
  UpdateEntityRelationshipInput,
} from './types';

function invalidateRelationshipQueries(
  queryClient: ReturnType<typeof useQueryClient>,
  entityIds: string[],
  campaignId: string | null,
) {
  const uniqueIds = Array.from(new Set(entityIds));

  const tasks = uniqueIds.flatMap((entityId) => [
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.relationships(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.relatedRecords(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.detail(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.timelineDetail(entityId) }),
  ]);

  if (campaignId) {
    tasks.push(
      queryClient.invalidateQueries({
        queryKey: ['campaigns', campaignId, 'timeline-events'],
      }),
    );
  }

  return Promise.all(tasks);
}

export function useCreateEntityRelationshipMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CreateEntityRelationshipInput) => {
      const { data, error } = await client.rpc('create_entity_relationship', {
        p_source_entity_id: input.sourceEntityId,
        p_target_entity_id: input.targetEntityId,
        p_relationship_type_id: input.relationshipTypeId,
        p_visibility: input.visibility,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateRelationshipQueries(
        queryClient,
        [variables.sourceEntityId, variables.targetEntityId],
        data?.campaign_id ?? null,
      );
    },
  });
}

export function useUpdateEntityRelationshipMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: UpdateEntityRelationshipInput) => {
      const { data, error } = await client.rpc('update_entity_relationship', {
        p_relationship_id: input.relationshipId,
        p_relationship_type_id: input.relationshipTypeId,
        p_visibility: input.visibility,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateRelationshipQueries(
        queryClient,
        [variables.sourceEntityId, variables.targetEntityId],
        data?.campaign_id ?? null,
      );
    },
  });
}

export function useDeleteEntityRelationshipMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: DeleteEntityRelationshipInput) => {
      const { data, error } = await client.rpc('soft_delete_entity_relationship', {
        p_relationship_id: input.relationshipId,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateRelationshipQueries(
        queryClient,
        [variables.sourceEntityId, variables.targetEntityId],
        data?.campaign_id ?? null,
      );
    },
  });
}
