import { describe, expect, it } from 'vitest';
import { createCampaignSchema } from '../../app/utils/campaign-validation';

describe('campaign creation validation', () => {
  it('accepts required campaign fields', () => {
    const result = createCampaignSchema.safeParse({
      name: 'Ember Coast',
      description: '',
      startDate: '2026-06-12',
      endDate: '',
    });

    expect(result.success).toBe(true);
    expect(result.success ? result.data.description : undefined).toBeUndefined();
  });

  it('rejects a campaign ending before it starts', () => {
    expect(
      createCampaignSchema.safeParse({
        name: 'Ember Coast',
        startDate: '2026-06-12',
        endDate: '2026-06-11',
      }).success,
    ).toBe(false);
  });
});
