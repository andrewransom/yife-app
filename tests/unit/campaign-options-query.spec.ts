import { computed } from 'vue';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { useCampaignOptionsQuery } from '../../app/composables/entities/useCampaignOptionsQuery';

const rpcMock = vi.fn();
const useQueryMock = vi.fn((options) => options);

vi.mock('@tanstack/vue-query', () => ({
  useQuery: (options: unknown) => useQueryMock(options),
}));

vi.mock('../../app/composables/auth/useYifeSupabaseClient', () => ({
  useYifeSupabaseClient: () => ({
    rpc: rpcMock,
  }),
}));

describe('useCampaignOptionsQuery', () => {
  beforeEach(() => {
    rpcMock.mockReset();
    useQueryMock.mockClear();
  });

  it('allows querying all option groups when groupKey is null', async () => {
    rpcMock.mockResolvedValue({
      data: [{ id: 'option-1', label: 'High' }],
      error: null,
    });

    const query = useCampaignOptionsQuery(computed(() => 'campaign-1'), computed(() => null), {
      includeInactive: computed(() => true),
    });

    expect(query.enabled.value).toBe(true);

    const result = await query.queryFn();

    expect(rpcMock).toHaveBeenCalledWith('get_campaign_options', {
      p_campaign_id: 'campaign-1',
      p_group_key: undefined,
      p_include_inactive: true,
    });
    expect(result).toEqual([{ id: 'option-1', label: 'High' }]);
  });
});
