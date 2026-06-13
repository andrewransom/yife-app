import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useCurrentUser } from '~/composables/auth/useCurrentUser';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from '~/composables/entities/keys';
import type { Database } from '~/types/database.types';
import { getPaletteTextColorToken } from '~/utils/campaign-settings';
import { campaignQueryKeys } from './keys';

type CampaignOptionInsert = Database['public']['Tables']['campaign_options']['Insert'];
type CampaignOptionUpdate = Database['public']['Tables']['campaign_options']['Update'];
type CampaignPaletteInsert = Database['public']['Tables']['campaign_palette_colors']['Insert'];
type CampaignPaletteUpdate = Database['public']['Tables']['campaign_palette_colors']['Update'];
type CampaignSymbolInsert = Database['public']['Tables']['campaign_symbols']['Insert'];
type CampaignSymbolUpdate = Database['public']['Tables']['campaign_symbols']['Update'];
type CampaignQuickStatTemplateInsert =
  Database['public']['Tables']['campaign_quick_stat_templates']['Insert'];
type CampaignQuickStatTemplateUpdate =
  Database['public']['Tables']['campaign_quick_stat_templates']['Update'];
type CampaignQuickStatFieldInsert =
  Database['public']['Tables']['campaign_quick_stat_fields']['Insert'];
type CampaignQuickStatFieldUpdate =
  Database['public']['Tables']['campaign_quick_stat_fields']['Update'];

function useCampaignSettingsInvalidation() {
  const queryClient = useQueryClient();

  return async (campaignId: string) => {
    await queryClient.invalidateQueries({
      queryKey: campaignQueryKeys.settingsRoot(campaignId),
    });
    await queryClient.invalidateQueries({
      queryKey: entityQueryKeys.optionsRoot(campaignId),
    });
    await queryClient.invalidateQueries({
      queryKey: entityQueryKeys.paletteColorsRoot(campaignId),
    });
    await queryClient.invalidateQueries({
      queryKey: entityQueryKeys.symbolsRoot(campaignId),
    });
    await queryClient.invalidateQueries({
      predicate: (query) =>
        Array.isArray(query.queryKey) &&
        query.queryKey[0] === 'entities' &&
        (query.queryKey[2] === 'quick-stats' || query.queryKey[2] === 'encounter-statblocks'),
    });
  };
}

function requireUserId(userId: string | undefined) {
  if (!userId) {
    throw new Error('Authentication required.');
  }

  return userId;
}

export function useImportCampaignPresetPackMutation() {
  const client = useYifeSupabaseClient();
  const invalidate = useCampaignSettingsInvalidation();

  return useMutation({
    mutationFn: async ({
      campaignId,
      presetPackKey,
    }: {
      campaignId: string;
      presetPackKey: string;
    }) => {
      const { error } = await client.rpc('import_campaign_preset_pack', {
        p_campaign_id: campaignId,
        p_preset_pack_key: presetPackKey,
      });

      if (error) {
        throw error;
      }

      return { campaignId };
    },
    onSuccess: async ({ campaignId }) => {
      await invalidate(campaignId);
    },
  });
}

export function useSaveCampaignOptionMutation() {
  const client = useYifeSupabaseClient();
  const currentUser = useCurrentUser();
  const invalidate = useCampaignSettingsInvalidation();

  return useMutation({
    mutationFn: async ({
      campaignId,
      optionId,
      input,
    }: {
      campaignId: string;
      optionId?: string | null;
      input: CampaignOptionInsert | CampaignOptionUpdate;
    }) => {
      const userId = requireUserId(currentUser.value?.id);

      if (optionId) {
        const { error } = await client
          .from('campaign_options')
          .update({
            ...input,
            updated_by: userId,
          })
          .eq('id', optionId)
          .eq('campaign_id', campaignId);

        if (error) {
          throw error;
        }

        return { campaignId };
      }

      const { error } = await client.from('campaign_options').insert({
        ...(input as CampaignOptionInsert),
        campaign_id: campaignId,
        created_by: userId,
        updated_by: userId,
      });

      if (error) {
        throw error;
      }

      return { campaignId };
    },
    onSuccess: async ({ campaignId }) => {
      await invalidate(campaignId);
    },
  });
}

export function useSaveCampaignPaletteColorMutation() {
  const client = useYifeSupabaseClient();
  const currentUser = useCurrentUser();
  const invalidate = useCampaignSettingsInvalidation();

  return useMutation({
    mutationFn: async ({
      campaignId,
      paletteColorId,
      input,
    }: {
      campaignId: string;
      paletteColorId?: string | null;
      input: CampaignPaletteInsert | CampaignPaletteUpdate;
    }) => {
      const userId = requireUserId(currentUser.value?.id);
      const baseInput = {
        ...input,
        text_color_token:
          input.color_token && typeof input.color_token === 'string'
            ? getPaletteTextColorToken(input.color_token)
            : input.text_color_token,
      };

      if (paletteColorId) {
        const { error } = await client
          .from('campaign_palette_colors')
          .update({
            ...baseInput,
            updated_by: userId,
          })
          .eq('id', paletteColorId)
          .eq('campaign_id', campaignId);

        if (error) {
          throw error;
        }

        return { campaignId };
      }

      const { error } = await client.from('campaign_palette_colors').insert({
        ...(baseInput as CampaignPaletteInsert),
        campaign_id: campaignId,
        created_by: userId,
        updated_by: userId,
      });

      if (error) {
        throw error;
      }

      return { campaignId };
    },
    onSuccess: async ({ campaignId }) => {
      await invalidate(campaignId);
    },
  });
}

export function useSaveCampaignSymbolMutation() {
  const client = useYifeSupabaseClient();
  const currentUser = useCurrentUser();
  const invalidate = useCampaignSettingsInvalidation();

  return useMutation({
    mutationFn: async ({
      campaignId,
      symbolId,
      input,
    }: {
      campaignId: string;
      symbolId?: string | null;
      input: CampaignSymbolInsert | CampaignSymbolUpdate;
    }) => {
      const userId = requireUserId(currentUser.value?.id);

      if (symbolId) {
        const { error } = await client
          .from('campaign_symbols')
          .update({
            ...input,
            updated_by: userId,
          })
          .eq('id', symbolId)
          .eq('campaign_id', campaignId);

        if (error) {
          throw error;
        }

        return { campaignId };
      }

      const { error } = await client.from('campaign_symbols').insert({
        ...(input as CampaignSymbolInsert),
        campaign_id: campaignId,
        created_by: userId,
        updated_by: userId,
      });

      if (error) {
        throw error;
      }

      return { campaignId };
    },
    onSuccess: async ({ campaignId }) => {
      await invalidate(campaignId);
    },
  });
}

export function useSaveCampaignQuickStatTemplateMutation() {
  const client = useYifeSupabaseClient();
  const currentUser = useCurrentUser();
  const invalidate = useCampaignSettingsInvalidation();

  return useMutation({
    mutationFn: async ({
      campaignId,
      templateId,
      input,
    }: {
      campaignId: string;
      templateId?: string | null;
      input: CampaignQuickStatTemplateInsert | CampaignQuickStatTemplateUpdate;
    }) => {
      const userId = requireUserId(currentUser.value?.id);

      if (templateId) {
        const { error } = await client
          .from('campaign_quick_stat_templates')
          .update({
            ...input,
            updated_by: userId,
          })
          .eq('id', templateId)
          .eq('campaign_id', campaignId);

        if (error) {
          throw error;
        }

        return { campaignId };
      }

      const { error } = await client.from('campaign_quick_stat_templates').insert({
        ...(input as CampaignQuickStatTemplateInsert),
        campaign_id: campaignId,
        created_by: userId,
        updated_by: userId,
      });

      if (error) {
        throw error;
      }

      return { campaignId };
    },
    onSuccess: async ({ campaignId }) => {
      await invalidate(campaignId);
    },
  });
}

export function useSaveCampaignQuickStatFieldMutation() {
  const client = useYifeSupabaseClient();
  const currentUser = useCurrentUser();
  const invalidate = useCampaignSettingsInvalidation();

  return useMutation({
    mutationFn: async ({
      campaignId,
      fieldId,
      input,
    }: {
      campaignId: string;
      fieldId?: string | null;
      input: CampaignQuickStatFieldInsert | CampaignQuickStatFieldUpdate;
    }) => {
      const userId = requireUserId(currentUser.value?.id);

      if (fieldId) {
        const { error } = await client
          .from('campaign_quick_stat_fields')
          .update({
            ...input,
            updated_by: userId,
          })
          .eq('id', fieldId)
          .eq('campaign_id', campaignId);

        if (error) {
          throw error;
        }

        return { campaignId };
      }

      const { error } = await client.from('campaign_quick_stat_fields').insert({
        ...(input as CampaignQuickStatFieldInsert),
        campaign_id: campaignId,
        created_by: userId,
        updated_by: userId,
      });

      if (error) {
        throw error;
      }

      return { campaignId };
    },
    onSuccess: async ({ campaignId }) => {
      await invalidate(campaignId);
    },
  });
}
