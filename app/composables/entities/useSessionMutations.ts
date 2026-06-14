import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type {
  UpdateEncounterInput,
  UpdateSessionAttendanceInput,
  UpdateSessionInput,
  UpdateStorylineInput,
} from './types';

function invalidateSessionScopedQueries(
  queryClient: ReturnType<typeof useQueryClient>,
  campaignId: string | null,
  entityIds: string[],
) {
  const tasks = entityIds.flatMap((entityId) => [
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.detail(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.sessionAttendance(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.relatedRecords(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.relationships(entityId) }),
    queryClient.invalidateQueries({
      queryKey: entityQueryKeys.activity(campaignId ?? 'none', { relatedEntityId: entityId }),
    }),
  ]);

  if (campaignId) {
    tasks.push(
      queryClient.invalidateQueries({ queryKey: entityQueryKeys.summaries(campaignId) }),
      queryClient.invalidateQueries({ queryKey: entityQueryKeys.sessions(campaignId) }),
      queryClient.invalidateQueries({ queryKey: entityQueryKeys.storylines(campaignId) }),
      queryClient.invalidateQueries({ queryKey: entityQueryKeys.encounters(campaignId) }),
      queryClient.invalidateQueries({ queryKey: entityQueryKeys.currentSession(campaignId) }),
      queryClient.invalidateQueries({ queryKey: entityQueryKeys.activity(campaignId) }),
      queryClient.invalidateQueries({ queryKey: ['campaigns', campaignId, 'timeline-events'] }),
    );
  }

  return Promise.all(tasks);
}

export function useUpdateSessionAttendanceMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      sessionEntityId,
      userIds,
      characterEntityIds,
    }: UpdateSessionAttendanceInput) => {
      const { data, error } = await client.rpc('update_session_attendance', {
        p_session_entity_id: sessionEntityId,
        p_user_ids: userIds,
        p_character_entity_ids: characterEntityIds,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateSessionScopedQueries(queryClient, data?.campaign_id ?? null, [
        variables.sessionEntityId,
      ]);
    },
  });
}

export function useUpdateSessionMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: UpdateSessionInput) => {
      const { data, error } = await client.rpc('update_session', {
        p_session_entity_id: input.sessionEntityId,
        p_title: input.title === null ? '' : input.title ?? undefined,
        p_session_date: input.sessionDate ?? undefined,
        p_status_id: input.statusId ?? undefined,
        p_session_number_label:
          input.sessionNumberLabel === null ? '' : input.sessionNumberLabel ?? undefined,
        p_start_time: input.startTime ?? undefined,
        p_clear_start_time: input.startTime === null,
        p_end_time: input.endTime ?? undefined,
        p_clear_end_time: input.endTime === null,
        p_public_summary: input.publicSummary === null ? '' : input.publicSummary ?? undefined,
        p_gm_summary: input.gmSummary === null ? '' : input.gmSummary ?? undefined,
        p_next_session_teaser:
          input.nextSessionTeaser === null ? '' : input.nextSessionTeaser ?? undefined,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateSessionScopedQueries(queryClient, data?.campaign_id ?? null, [
        variables.sessionEntityId,
      ]);
    },
  });
}

export function useUpdateStorylineMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: UpdateStorylineInput) => {
      const { data, error } = await client.rpc('update_storyline', {
        p_storyline_entity_id: input.storylineEntityId,
        p_title: input.title ?? undefined,
        p_status_id: input.statusId ?? undefined,
        p_storyline_type: input.storylineType ?? undefined,
        p_priority_option_id: input.priorityOptionId ?? undefined,
        p_clear_priority_option: input.priorityOptionId === null,
        p_storyline_category_option_id: input.storylineCategoryOptionId ?? undefined,
        p_clear_storyline_category_option: input.storylineCategoryOptionId === null,
        p_is_major: input.isMajor ?? undefined,
        p_parent_storyline_entity_id: input.parentStorylineEntityId ?? undefined,
        p_clear_parent_storyline: input.parentStorylineEntityId === null,
        p_public_summary: input.publicSummary === null ? '' : input.publicSummary ?? undefined,
        p_gm_summary: input.gmSummary === null ? '' : input.gmSummary ?? undefined,
        p_primary_location_entity_id: input.primaryLocationEntityId ?? undefined,
        p_clear_primary_location: input.primaryLocationEntityId === null,
        p_reward_text: input.rewardText === null ? '' : input.rewardText ?? undefined,
        p_completed_at: input.completedAt ?? undefined,
        p_clear_completed_at: input.completedAt === null,
        p_sort_order: input.sortOrder ?? undefined,
        p_clear_sort_order: input.sortOrder === null,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateSessionScopedQueries(
        queryClient,
        data?.campaign_id ?? null,
        [variables.storylineEntityId, variables.parentStorylineEntityId ?? ''].filter(Boolean),
      );
    },
  });
}

export function useUpdateEncounterMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: UpdateEncounterInput) => {
      const { data, error } = await client.rpc('update_encounter', {
        p_encounter_entity_id: input.encounterEntityId,
        p_title: input.title === null ? '' : input.title ?? undefined,
        p_status_id: input.statusId ?? undefined,
        p_encounter_type_option_id: input.encounterTypeOptionId ?? undefined,
        p_difficulty_option_id: input.difficultyOptionId ?? undefined,
        p_clear_difficulty_option: input.difficultyOptionId === null,
        p_related_session_entity_id: input.relatedSessionEntityId ?? undefined,
        p_clear_related_session: input.relatedSessionEntityId === null,
        p_related_storyline_entity_id: input.relatedStorylineEntityId ?? undefined,
        p_clear_related_storyline: input.relatedStorylineEntityId === null,
        p_sort_order: input.sortOrder ?? undefined,
        p_clear_sort_order: input.sortOrder === null,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateSessionScopedQueries(
        queryClient,
        data?.campaign_id ?? null,
        [
          variables.encounterEntityId,
          variables.relatedSessionEntityId ?? '',
          variables.relatedStorylineEntityId ?? '',
        ].filter(Boolean),
      );
    },
  });
}
