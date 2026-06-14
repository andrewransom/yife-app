import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import type { Json } from '~/types/database.types';
import { entityQueryKeys } from './keys';
import type { SaveRichTextInput } from './types';

type SaveSectionInput = {
  entityId: string;
  sectionId: string;
  expectedVersion: number;
  content: SaveRichTextInput;
};

type CreateNoteInput = {
  campaignId: string;
  visibility: string;
  attachToCampaign: boolean;
  entityIds: string[];
  content: SaveRichTextInput;
};

type UpdateNoteInput = {
  entityId: string;
  noteId: string;
  visibility: string;
  expectedVersion: number;
  attachToCampaign: boolean;
  entityIds: string[];
  currentAttachToCampaign: boolean;
  currentEntityIds: string[];
  content: SaveRichTextInput;
};

type DeleteNoteInput = {
  entityId: string;
  noteId: string;
  campaignId: string;
};

type CreateContributionInput = {
  entityId: string;
  sectionId: string;
  visibility: string;
  content: SaveRichTextInput;
};

type UpdateContributionInput = {
  entityId: string;
  sectionId: string;
  contributionId: string;
  visibility: string;
  expectedVersion: number;
  content: SaveRichTextInput;
};

type DeleteContributionInput = {
  entityId: string;
  sectionId: string;
  contributionId: string;
};

function invalidateEntityRichTextQueries(
  queryClient: ReturnType<typeof useQueryClient>,
  entityId: string,
  campaignId?: string,
  sectionId?: string,
) {
  const tasks = [
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.sections(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.notes(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.backlinks(entityId) }),
    queryClient.invalidateQueries({ queryKey: entityQueryKeys.detail(entityId) }),
  ];

  if (campaignId) {
    tasks.push(queryClient.invalidateQueries({ queryKey: entityQueryKeys.campaignNotes(campaignId) }));
  }

  if (sectionId) {
    tasks.push(
      queryClient.invalidateQueries({ queryKey: entityQueryKeys.sectionContributions(sectionId) }),
    );
  }

  return Promise.all(tasks);
}

export function useSaveEntitySectionMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ sectionId, expectedVersion, content }: SaveSectionInput) => {
      const { data, error } = await client.rpc('save_entity_section_body', {
        p_section_id: sectionId,
        p_body_json: content.bodyJson as Json,
        p_body_text: content.bodyText,
        p_body_preview: content.bodyPreview ?? '',
        p_mentions: content.mentions,
        p_expected_version: expectedVersion,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (_, variables) => {
      await invalidateEntityRichTextQueries(queryClient, variables.entityId, undefined, variables.sectionId);
    },
  });
}

export function useCreateNoteMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ campaignId, visibility, attachToCampaign, entityIds, content }: CreateNoteInput) => {
      const { data, error } = await client.rpc('create_note', {
        p_campaign_id: campaignId,
        p_visibility: visibility,
        p_body_json: content.bodyJson as Json,
        p_body_text: content.bodyText,
        p_body_preview: content.bodyPreview ?? '',
        p_mentions: content.mentions,
        p_attach_to_campaign: attachToCampaign,
        p_entity_ids: entityIds,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      await invalidateEntityRichTextQueries(
        queryClient,
        variables.entityIds[0] ?? 'none',
        data?.campaign_id ?? variables.campaignId,
      );
      await Promise.all(
        variables.entityIds.slice(1).map((id) =>
          invalidateEntityRichTextQueries(queryClient, id, data?.campaign_id ?? variables.campaignId),
        ),
      );
    },
  });
}

export function useUpdateNoteMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      noteId,
      visibility,
      expectedVersion,
      attachToCampaign,
      entityIds,
      currentAttachToCampaign,
      currentEntityIds,
      content,
    }: UpdateNoteInput) => {
      const { data, error } = await client.rpc('update_note_body', {
        p_note_id: noteId,
        p_visibility: visibility,
        p_body_json: content.bodyJson as Json,
        p_body_text: content.bodyText,
        p_body_preview: content.bodyPreview ?? '',
        p_mentions: content.mentions,
        p_expected_version: expectedVersion,
      });

      if (error) {
        throw error;
      }

      for (const entityId of entityIds.filter((id) => !currentEntityIds.includes(id))) {
        const { error: attachError } = await client.rpc('attach_note_target', {
          p_note_id: noteId,
          p_target_type: 'entity',
          p_entity_id: entityId,
        });

        if (attachError) {
          throw attachError;
        }
      }

      if (currentAttachToCampaign !== attachToCampaign) {
        const { error: attachmentError } = await client.rpc(
          attachToCampaign ? 'attach_note_target' : 'detach_note_target',
          {
            p_note_id: noteId,
            p_target_type: 'campaign',
            p_entity_id: undefined,
          },
        );

        if (attachmentError) {
          throw attachmentError;
        }
      }

      for (const entityId of currentEntityIds.filter((id) => !entityIds.includes(id))) {
        const { error: detachError } = await client.rpc('detach_note_target', {
          p_note_id: noteId,
          p_target_type: 'entity',
          p_entity_id: entityId,
        });

        if (detachError) {
          throw detachError;
        }
      }
      return data?.[0] ?? null;
    },
    onSuccess: async (data, variables) => {
      const allEntityIds = new Set([variables.entityId, ...variables.entityIds, ...variables.currentEntityIds]);

      await Promise.all(
        Array.from(allEntityIds).map((id) =>
          invalidateEntityRichTextQueries(queryClient, id, data?.campaign_id),
        ),
      );
    },
  });
}

export function useDeleteNoteMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ noteId }: DeleteNoteInput) => {
      const { error } = await client.rpc('soft_delete_note', {
        p_note_id: noteId,
      });

      if (error) {
        throw error;
      }
    },
    onSuccess: async (_, variables) => {
      await invalidateEntityRichTextQueries(
        queryClient,
        variables.entityId,
        variables.campaignId,
      );
    },
  });
}

export function useCreateContributionMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ sectionId, visibility, content }: CreateContributionInput) => {
      const { data, error } = await client.rpc('create_entity_section_contribution', {
        p_section_id: sectionId,
        p_visibility: visibility,
        p_body_json: content.bodyJson as Json,
        p_body_text: content.bodyText,
        p_body_preview: content.bodyPreview ?? '',
        p_mentions: content.mentions,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (_, variables) => {
      await invalidateEntityRichTextQueries(
        queryClient,
        variables.entityId,
        undefined,
        variables.sectionId,
      );
    },
  });
}

export function useUpdateContributionMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      contributionId,
      visibility,
      expectedVersion,
      content,
    }: UpdateContributionInput) => {
      const { data, error } = await client.rpc('update_entity_section_contribution', {
        p_contribution_id: contributionId,
        p_visibility: visibility,
        p_body_json: content.bodyJson as Json,
        p_body_text: content.bodyText,
        p_body_preview: content.bodyPreview ?? '',
        p_mentions: content.mentions,
        p_expected_version: expectedVersion,
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
    onSuccess: async (_, variables) => {
      await invalidateEntityRichTextQueries(
        queryClient,
        variables.entityId,
        undefined,
        variables.sectionId,
      );
    },
  });
}

export function useDeleteContributionMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ contributionId }: DeleteContributionInput) => {
      const { error } = await client.rpc('soft_delete_entity_section_contribution', {
        p_contribution_id: contributionId,
      });

      if (error) {
        throw error;
      }
    },
    onSuccess: async (_, variables) => {
      await invalidateEntityRichTextQueries(
        queryClient,
        variables.entityId,
        undefined,
        variables.sectionId,
      );
    },
  });
}
