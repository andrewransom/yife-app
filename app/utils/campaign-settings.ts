import type { CampaignOption } from '~/composables/entities/types';

export type CampaignSettingsOptionGroupMeta = {
  key: string;
  label: string;
  section: 'core' | 'advanced';
};

export const campaignSettingsOptionGroups: CampaignSettingsOptionGroupMeta[] = [
  { key: 'npc_role', label: 'NPC Role', section: 'core' },
  { key: 'party_disposition', label: 'Party Disposition', section: 'core' },
  { key: 'hook_category', label: 'Hook Category', section: 'advanced' },
  { key: 'faction_type', label: 'Faction Type', section: 'core' },
  { key: 'faction_scope', label: 'Faction Scope', section: 'advanced' },
  { key: 'location_type', label: 'Location Type', section: 'core' },
  { key: 'location_terrain', label: 'Location Terrain', section: 'advanced' },
  { key: 'location_danger_level', label: 'Location Danger Level', section: 'advanced' },
  { key: 'location_accessibility', label: 'Location Accessibility', section: 'advanced' },
  { key: 'location_party_disposition', label: 'Location Party Disposition', section: 'advanced' },
  { key: 'storyline_category', label: 'Storyline Category', section: 'core' },
  { key: 'storyline_priority', label: 'Storyline Priority', section: 'core' },
  { key: 'encounter_type', label: 'Encounter Type', section: 'core' },
  { key: 'encounter_difficulty', label: 'Encounter Difficulty', section: 'advanced' },
  { key: 'timeline_event_type', label: 'Timeline Event Type', section: 'core' },
];

export const paletteTokenOptions = [
  { value: 'red', label: 'Red', textColorToken: 'white' },
  { value: 'amber', label: 'Amber', textColorToken: 'black' },
  { value: 'green', label: 'Green', textColorToken: 'white' },
  { value: 'blue', label: 'Blue', textColorToken: 'white' },
  { value: 'violet', label: 'Violet', textColorToken: 'white' },
  { value: 'slate', label: 'Slate', textColorToken: 'white' },
] as const;

const paletteTokenStyleMap: Record<string, { backgroundColor: string; color: string }> = {
  red: { backgroundColor: '#dc2626', color: '#ffffff' },
  amber: { backgroundColor: '#d97706', color: '#0f172a' },
  green: { backgroundColor: '#16a34a', color: '#ffffff' },
  blue: { backgroundColor: '#2563eb', color: '#ffffff' },
  violet: { backgroundColor: '#7c3aed', color: '#ffffff' },
  slate: { backgroundColor: '#475569', color: '#ffffff' },
};

export const characterQuickStatVisibilityOptions = [
  { value: 'shared', label: 'Shared' },
  { value: 'private', label: 'Private' },
  { value: 'character_owner_gm', label: 'Character owner + GM' },
  { value: 'gm_only', label: 'GM only' },
] as const;

export function slugifyCampaignSettingKey(value: string, fallbackPrefix = 'item') {
  const normalized = value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');

  return normalized || `${fallbackPrefix}_${Date.now()}`;
}

export function nextSortOrder(items: Array<{ sort_order: number }>) {
  if (!items.length) {
    return 10;
  }

  return Math.max(...items.map((item) => item.sort_order)) + 10;
}

export function getPaletteTextColorToken(colorToken: string) {
  return paletteTokenOptions.find((option) => option.value === colorToken)?.textColorToken ?? 'white';
}

export function getPaletteTokenStyle(colorToken: string) {
  return paletteTokenStyleMap[colorToken] ?? paletteTokenStyleMap.slate;
}

export function groupCampaignOptions(options: CampaignOption[]) {
  const optionsByGroup = new Map<string, CampaignOption[]>();

  for (const option of options) {
    const current = optionsByGroup.get(option.group_key) ?? [];
    current.push(option);
    optionsByGroup.set(option.group_key, current);
  }

  return campaignSettingsOptionGroups.map((group) => ({
    ...group,
    options: (optionsByGroup.get(group.key) ?? []).slice().sort((left, right) => {
      if (left.sort_order !== right.sort_order) {
        return left.sort_order - right.sort_order;
      }

      return left.label.localeCompare(right.label);
    }),
  }));
}

export function canManageCampaignSettings(roleKeys: string[]) {
  return roleKeys.includes('owner') || roleKeys.includes('game_master');
}
