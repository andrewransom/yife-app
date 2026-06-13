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
