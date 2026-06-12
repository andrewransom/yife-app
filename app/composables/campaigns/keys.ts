export const campaignQueryKeys = {
  mine: () => ['campaigns', 'mine'] as const,
  byId: (campaignId: string) => ['campaigns', 'mine', campaignId] as const,
  membership: (campaignId: string) => ['campaigns', campaignId, 'membership'] as const,
  statuses: () => ['campaigns', 'statuses'] as const,
};
