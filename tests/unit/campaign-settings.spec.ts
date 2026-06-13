import { describe, expect, it } from 'vitest';
import type { CampaignOption } from '../../app/composables/entities/types';
import {
  canManageCampaignSettings,
  campaignSettingsOptionGroups,
  getPaletteTextColorToken,
  getPaletteTokenStyle,
  groupCampaignOptions,
  nextSortOrder,
  slugifyCampaignSettingKey,
} from '../../app/utils/campaign-settings';

function option(overrides: Partial<CampaignOption> = {}): CampaignOption {
  return {
    default_palette_color_id: null,
    default_palette_color_token: null,
    default_symbol_icon_key: null,
    default_symbol_id: null,
    description: null,
    group_id: 'group-1',
    group_key: 'storyline_priority',
    id: 'option-1',
    is_active: true,
    key: 'normal',
    label: 'Normal',
    sort_order: 20,
    ...overrides,
  } as CampaignOption;
}

describe('campaign settings utilities', () => {
  it('slugifies keys to lowercase underscore format', () => {
    expect(slugifyCampaignSettingKey('Omen / Prophecy')).toBe('omen_prophecy');
  });

  it('derives the next sort order in tens', () => {
    expect(nextSortOrder([])).toBe(10);
    expect(nextSortOrder([{ sort_order: 10 }, { sort_order: 40 }])).toBe(50);
  });

  it('groups and sorts campaign options by configured phase 04.5 group order', () => {
    const grouped = groupCampaignOptions([
      option({
        group_key: 'encounter_type',
        label: 'Combat',
        key: 'combat',
        sort_order: 30,
      }),
      option({
        id: 'option-2',
        group_key: 'storyline_priority',
        label: 'High',
        key: 'high',
        sort_order: 10,
      }),
    ]);

    expect(grouped.find((group) => group.key === 'storyline_priority')?.options[0]?.label).toBe(
      'High',
    );
    expect(grouped.find((group) => group.key === 'encounter_type')?.options[0]?.key).toBe(
      'combat',
    );
    expect(grouped.map((group) => group.key)).toEqual(
      campaignSettingsOptionGroups.map((group) => group.key),
    );
  });

  it('reports management permissions for owners and game masters only', () => {
    expect(canManageCampaignSettings(['owner'])).toBe(true);
    expect(canManageCampaignSettings(['game_master'])).toBe(true);
    expect(canManageCampaignSettings(['player'])).toBe(false);
  });

  it('maps palette tokens to constrained text colors and swatches', () => {
    expect(getPaletteTextColorToken('amber')).toBe('black');
    expect(getPaletteTokenStyle('blue')).toEqual({
      backgroundColor: '#2563eb',
      color: '#ffffff',
    });
  });
});
