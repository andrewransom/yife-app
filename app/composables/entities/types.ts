import type { Database } from '~/types/database.types';

type NullableFields<T, K extends keyof T> = Omit<T, K> & {
  [P in K]: T[P] | null;
};

type GeneratedEntitySummary =
  Database['public']['Functions']['get_campaign_entity_summaries']['Returns'][number];
type GeneratedEntityDetail =
  Database['public']['Functions']['get_entity_detail']['Returns'][number];
type GeneratedEntityQuickStat =
  Database['public']['Functions']['get_entity_quick_stats']['Returns'][number];
type GeneratedCharacterHook =
  Database['public']['Functions']['get_character_hooks']['Returns'][number];
type GeneratedEncounterStatblock =
  Database['public']['Functions']['get_encounter_statblocks']['Returns'][number];
type GeneratedPartyMember = Database['public']['Tables']['party_members']['Row'];

export type EntitySummary = NullableFields<
  GeneratedEntitySummary,
  | 'archived_at'
  | 'controlling_user_display_label'
  | 'deleted_at'
  | 'encounter_type_label'
  | 'is_major'
  | 'location_type_label'
  | 'npc_apparent_status_label'
  | 'parent_entity_id'
  | 'parent_entity_label'
  | 'primary_image_alt_text'
  | 'primary_image_asset_id'
  | 'primary_image_grid_bucket'
  | 'primary_image_grid_height'
  | 'primary_image_grid_path'
  | 'primary_image_grid_width'
  | 'primary_image_is_decorative'
  | 'primary_image_thumb_bucket'
  | 'primary_image_thumb_height'
  | 'primary_image_thumb_path'
  | 'primary_image_thumb_width'
  | 'related_session_entity_id'
  | 'related_session_label'
  | 'related_storyline_entity_id'
  | 'related_storyline_label'
  | 'relevant_date'
  | 'sort_key'
  | 'status_key'
  | 'status_label'
  | 'storyline_category_label'
  | 'storyline_priority_label'
  | 'storyline_type'
  | 'timeline_date_expression'
  | 'timeline_event_type_label'
>;

export type EntityDetail = NullableFields<
  GeneratedEntityDetail,
  | 'archived_at'
  | 'controlling_user_display_label'
  | 'controlling_user_id'
  | 'encounter_type_label'
  | 'is_major'
  | 'location_type_label'
  | 'npc_apparent_status_label'
  | 'npc_real_status_label'
  | 'parent_entity_id'
  | 'parent_entity_label'
  | 'related_session_entity_id'
  | 'related_session_label'
  | 'related_storyline_entity_id'
  | 'related_storyline_label'
  | 'relevant_date'
  | 'sort_key'
  | 'status_key'
  | 'status_label'
  | 'storyline_category_label'
  | 'storyline_priority_label'
  | 'storyline_type'
  | 'timeline_date_expression'
  | 'timeline_event_type_label'
>;
export type EntityTypeOption =
  Database['public']['Functions']['get_entity_type_options']['Returns'][number];
export type EntityStatusOption =
  Database['public']['Functions']['get_entity_status_options']['Returns'][number];
export type CampaignOption =
  Database['public']['Functions']['get_campaign_options']['Returns'][number];
export type CampaignPaletteColor =
  Database['public']['Functions']['get_campaign_palette_colors']['Returns'][number];
export type CampaignSymbol =
  Database['public']['Functions']['get_campaign_symbols']['Returns'][number];
export type EntityQuickStat =
  NullableFields<
    GeneratedEntityQuickStat,
    'value_id' | 'value_number' | 'value_text'
  >;
export type CharacterHook =
  NullableFields<
    GeneratedCharacterHook,
    | 'category_option_id'
    | 'category_label'
    | 'gm_note_text'
    | 'promoted_storyline_entity_id'
    | 'promoted_storyline_label'
  >;
export type EncounterStatblock =
  NullableFields<GeneratedEncounterStatblock, 'linked_npc_entity_id' | 'linked_npc_label'>;
export type PartyMember = Pick<
  GeneratedPartyMember,
  'character_entity_id' | 'role_label' | 'is_active' | 'sort_order'
> & {
  character_label: string | null;
  character_visibility: string | null;
};
export type CreateEntityResult =
  Database['public']['Functions']['create_campaign_entity']['Returns'][number];

export type CreateEntityInput = {
  campaignId: string;
  entityTypeKey: string;
  input: Record<string, unknown>;
};
