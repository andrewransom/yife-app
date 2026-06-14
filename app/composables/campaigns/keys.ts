export const campaignQueryKeys = {
  mine: () => ['campaigns', 'mine'] as const,
  byId: (campaignId: string) => ['campaigns', 'mine', campaignId] as const,
  membership: (campaignId: string) => ['campaigns', campaignId, 'membership'] as const,
  statuses: () => ['campaigns', 'statuses'] as const,
  settingsRoot: (campaignId: string) => ['campaigns', campaignId, 'settings'] as const,
  optionGroups: (campaignId: string) =>
    [...campaignQueryKeys.settingsRoot(campaignId), 'option-groups'] as const,
  presetPacks: () => ['campaign-settings', 'preset-packs'] as const,
  symbolIconKeys: () => ['campaign-settings', 'symbol-icon-keys'] as const,
  quickStatTemplate: (campaignId: string, templateKind: string) =>
    [...campaignQueryKeys.settingsRoot(campaignId), 'quick-stat-template', templateKind] as const,
  quickStatFields: (campaignId: string, templateId: string) =>
    [...campaignQueryKeys.settingsRoot(campaignId), 'quick-stat-fields', templateId] as const,
};
