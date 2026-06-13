import type { Database } from '~/types/database.types';

export type MyCampaign = Database['public']['Functions']['get_my_campaigns']['Returns'][number];
export type CampaignMembershipSummary =
  Database['public']['Functions']['get_campaign_membership_summary']['Returns'][number];
export type CampaignMemberProfile =
  Database['public']['Functions']['get_safe_member_profiles']['Returns'][number];
export type CreateCampaignResult =
  Database['public']['Functions']['create_campaign']['Returns'][number];
export type CampaignStatusOption = Pick<
  Database['public']['Tables']['status_definitions']['Row'],
  'id' | 'key' | 'label' | 'sort_order'
>;
export type CampaignOptionGroup = Database['public']['Tables']['campaign_option_groups']['Row'];
export type OptionPresetPack = Database['public']['Tables']['option_preset_packs']['Row'];
export type CampaignQuickStatTemplate =
  Database['public']['Tables']['campaign_quick_stat_templates']['Row'];
export type CampaignQuickStatField =
  Database['public']['Tables']['campaign_quick_stat_fields']['Row'];
export type AppSymbolIconKey = Database['public']['Tables']['app_symbol_icon_keys']['Row'];
