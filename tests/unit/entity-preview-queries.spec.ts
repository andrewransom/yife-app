import { ref } from 'vue';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { useEntityDetailQuery } from '../../app/composables/entities/useEntityDetailQuery';
import { usePartyMembersQuery } from '../../app/composables/entities/usePartyMembersQuery';

const useQueryMock = vi.fn();
const rpcMock = vi.fn();

vi.mock('@tanstack/vue-query', () => ({
  useQuery: (input: unknown) => {
    useQueryMock(input);
    return input;
  },
}));

vi.mock('~/composables/auth/useYifeSupabaseClient', () => ({
  useYifeSupabaseClient: () => ({
    rpc: rpcMock,
  }),
}));

describe('preview-safe entity queries', () => {
  beforeEach(() => {
    useQueryMock.mockReset();
    rpcMock.mockReset();
    rpcMock.mockResolvedValue({ data: [], error: null });
  });

  it('passes player preview role to entity detail reads and keys the cache separately', async () => {
    const entityId = ref('entity-1');
    const query = useEntityDetailQuery(entityId, {
      previewAsPlayer: ref(true),
    }) as {
      queryKey: { value: readonly string[] };
      queryFn: () => Promise<unknown>;
    };

    expect(query.queryKey.value).toEqual(['entities', 'entity-1', 'detail', 'player-preview']);

    await query.queryFn();

    expect(rpcMock).toHaveBeenCalledWith('get_entity_detail', {
      p_entity_id: 'entity-1',
      p_role_view: 'player',
    });
  });

  it('uses the party-member RPC instead of direct table reads', async () => {
    const partyId = ref('party-1');
    const query = usePartyMembersQuery(partyId, {
      previewAsPlayer: ref(true),
    }) as {
      queryKey: { value: readonly string[] };
      queryFn: () => Promise<unknown>;
    };

    expect(query.queryKey.value).toEqual([
      'entities',
      'party-1',
      'party-members',
      'player-preview',
    ]);

    await query.queryFn();

    expect(rpcMock).toHaveBeenCalledWith('get_party_members', {
      p_party_entity_id: 'party-1',
      p_role_view: 'player',
    });
  });
});
