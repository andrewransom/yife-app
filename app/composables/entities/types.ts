import type { Database } from '~/types/database.types';

type NullableFields<T, K extends keyof T> = Omit<T, K> & {
  [P in K]: T[P] | null;
};

type GeneratedEntitySummary =
  Database['public']['Functions']['get_campaign_entity_summaries']['Returns'][number];
type GeneratedEntityDetail =
  Database['public']['Functions']['get_entity_detail']['Returns'][number];

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
  | 'quest_priority_label'
  | 'related_plot_arc_entity_id'
  | 'related_plot_arc_label'
  | 'related_session_entity_id'
  | 'related_session_label'
  | 'relevant_date'
  | 'sort_key'
  | 'status_key'
  | 'status_label'
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
  | 'quest_priority_label'
  | 'related_plot_arc_entity_id'
  | 'related_plot_arc_label'
  | 'related_session_entity_id'
  | 'related_session_label'
  | 'relevant_date'
  | 'sort_key'
  | 'status_key'
  | 'status_label'
  | 'timeline_date_expression'
  | 'timeline_event_type_label'
>;
export type EntityTypeOption =
  Database['public']['Functions']['get_entity_type_options']['Returns'][number];
export type EntityStatusOption =
  Database['public']['Functions']['get_entity_status_options']['Returns'][number];
export type EntityOptionDefinition =
  Database['public']['Functions']['get_entity_option_definitions']['Returns'][number];
export type CreateEntityResult =
  Database['public']['Functions']['create_campaign_entity']['Returns'][number];

export type CreateEntityInput = {
  campaignId: string;
  entityTypeKey: string;
  input: Record<string, unknown>;
};
