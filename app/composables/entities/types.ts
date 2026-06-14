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
type GeneratedEntitySection =
  Database['public']['Functions']['get_entity_sections']['Returns'][number];
type GeneratedSectionContribution =
  Database['public']['Functions']['get_section_contributions']['Returns'][number];
type GeneratedEntityNote = Database['public']['Functions']['get_entity_notes']['Returns'][number];
type GeneratedEntityBacklink =
  Database['public']['Functions']['get_entity_backlinks']['Returns'][number];
type GeneratedEntityRelationship =
  Database['public']['Functions']['get_entity_relationships']['Returns'][number];
type GeneratedEntityRelatedRecord =
  Database['public']['Functions']['get_entity_related_records']['Returns'][number];
type GeneratedTimelineEvent =
  Database['public']['Functions']['get_timeline_events']['Returns'][number];
type GeneratedEntityReferenceResolution =
  Database['public']['Functions']['resolve_entity_references']['Returns'][number];
type GeneratedPartyMember = Database['public']['Tables']['party_members']['Row'];
type GeneratedRelationshipType = Pick<
  Database['public']['Tables']['relationship_types']['Row'],
  'id' | 'key' | 'label' | 'inverse_label' | 'default_directionality' | 'sort_order'
>;

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
export type EntityQuickStat = NullableFields<
  GeneratedEntityQuickStat,
  'value_id' | 'value_number' | 'value_text'
>;
export type CharacterHook = NullableFields<
  GeneratedCharacterHook,
  | 'category_option_id'
  | 'category_label'
  | 'gm_note_text'
  | 'promoted_storyline_entity_id'
  | 'promoted_storyline_label'
>;
export type EncounterStatblock = NullableFields<
  GeneratedEncounterStatblock,
  'linked_npc_entity_id' | 'linked_npc_label'
>;
export type EntitySection = NullableFields<GeneratedEntitySection, 'body_preview'>;
export type SectionContribution = NullableFields<
  GeneratedSectionContribution,
  'author_display_label' | 'body_preview'
>;
export type EntityNote = NullableFields<
  GeneratedEntityNote,
  'author_display_label' | 'body_preview'
>;
export type EntityBacklink = NullableFields<
  GeneratedEntityBacklink,
  'author_display_label' | 'source_entity_id' | 'source_preview'
>;
export type EntityRelationship = NullableFields<
  GeneratedEntityRelationship,
  'inverse_label' | 'related_entity_id' | 'related_entity_type_key'
>;
export type EntityRelatedRecord = NullableFields<
  GeneratedEntityRelatedRecord,
  | 'mention_count'
  | 'related_entity_id'
  | 'related_entity_type_key'
  | 'source_contribution_id'
  | 'source_note_id'
  | 'source_section_id'
>;
export type TimelineEvent = NullableFields<
  GeneratedTimelineEvent,
  | 'primary_location_entity_id'
  | 'primary_location_label'
  | 'related_session_entity_id'
  | 'related_session_label'
>;
export type RelationshipType = GeneratedRelationshipType;
export type EntityReferenceResolution = GeneratedEntityReferenceResolution;
export type PartyMember = Pick<
  GeneratedPartyMember,
  'character_entity_id' | 'role_label' | 'is_active' | 'sort_order'
> & {
  character_label: string | null;
  character_visibility: string | null;
};
export type SessionAttendanceUser = {
  user_id: string;
  display_label: string | null;
  role_keys: string[];
};
export type SessionAttendanceCharacter = {
  character_entity_id: string;
  display_label: string | null;
  visibility: string | null;
};
export type SessionAttendance = {
  session_entity_id: string;
  attending_users: SessionAttendanceUser[];
  attending_characters: SessionAttendanceCharacter[];
  can_manage: boolean;
};
export type CurrentSession = {
  session_entity_id: string;
  list_caption: string;
  session_date: string | null;
  status_key: string | null;
  status_label: string | null;
  selection_reason: 'manual_override' | 'nearest_upcoming_planned' | 'most_recent_completed';
};
export type CampaignActivityItem = {
  campaign_id: string;
  activity_type: string;
  subject_type: string;
  subject_id: string;
  subject_entity_id: string | null;
  actor_user_id: string | null;
  actor_display_label: string | null;
  occurred_at: string;
  label: string;
  visibility: string;
  subject_label: string;
};
export type CreateEntityResult =
  Database['public']['Functions']['create_campaign_entity']['Returns'][number];

export type CreateEntityInput = {
  campaignId: string;
  entityTypeKey: string;
  input: Record<string, unknown>;
};

export type SaveRichTextInput = {
  bodyJson: Record<string, unknown>;
  bodyText: string;
  bodyPreview: string | null;
  mentions: { entity_id: string; label: string }[];
};

export type CreateEntityRelationshipInput = {
  sourceEntityId: string;
  targetEntityId: string;
  relationshipTypeId: string;
  visibility: 'shared' | 'gm_only';
};

export type UpdateEntityRelationshipInput = {
  relationshipId: string;
  sourceEntityId: string;
  targetEntityId: string;
  relationshipTypeId: string;
  visibility: 'shared' | 'gm_only';
};

export type DeleteEntityRelationshipInput = {
  relationshipId: string;
  sourceEntityId: string;
  targetEntityId: string;
};

export type UpdateSessionInput = {
  sessionEntityId: string;
  title?: string | null;
  sessionDate?: string | null;
  statusId?: string | null;
  sessionNumberLabel?: string | null;
  startTime?: string | null;
  endTime?: string | null;
  publicSummary?: string | null;
  gmSummary?: string | null;
  nextSessionTeaser?: string | null;
};

export type UpdateStorylineInput = {
  storylineEntityId: string;
  title?: string | null;
  statusId?: string | null;
  storylineType?: 'quest' | 'thread' | null;
  priorityOptionId?: string | null;
  storylineCategoryOptionId?: string | null;
  isMajor?: boolean | null;
  parentStorylineEntityId?: string | null;
  publicSummary?: string | null;
  gmSummary?: string | null;
  primaryLocationEntityId?: string | null;
  rewardText?: string | null;
  completedAt?: string | null;
  sortOrder?: number | null;
};

export type UpdateEncounterInput = {
  encounterEntityId: string;
  title?: string | null;
  statusId?: string | null;
  encounterTypeOptionId?: string | null;
  difficultyOptionId?: string | null;
  relatedSessionEntityId?: string | null;
  relatedStorylineEntityId?: string | null;
  sortOrder?: number | null;
};

export type UpdateSessionAttendanceInput = {
  sessionEntityId: string;
  userIds: string[];
  characterEntityIds: string[];
};
