import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import EntityDetailShell from '../../app/components/entities/EntityDetailShell.vue';
import type {
  CharacterHook,
  EncounterStatblock,
  EntityDetail,
  EntityQuickStat,
  PartyMember,
} from '../../app/composables/entities/types';

const mockQuickStats = ref<EntityQuickStat[]>([]);
const mockHooks = ref<CharacterHook[]>([]);
const mockPartyMembers = ref<PartyMember[]>([]);
const mockEncounterStatblocks = ref<EncounterStatblock[]>([]);
const mockPromote = vi.fn();
const mockSelectEntity = vi.fn();
const useQueryMock = vi.fn();

vi.mock('@tanstack/vue-query', () => ({
  useQuery: (input: unknown) => useQueryMock(input),
  useMutation: vi.fn(),
  useQueryClient: vi.fn(),
}));

vi.mock('~/composables/entities/usePromoteCharacterHookMutation', () => ({
  usePromoteCharacterHookMutation: () => ({
    isPending: ref(false),
    mutateAsync: mockPromote,
  }),
}));

vi.mock('~/stores/ui', () => ({
  useUiStore: () => ({
    selectEntity: mockSelectEntity,
  }),
}));

vi.mock('~/composables/auth/useYifeSupabaseClient', () => ({
  useYifeSupabaseClient: () => ({}),
}));

function mountShell(detail: EntityDetail) {
  return mount(EntityDetailShell, {
    props: {
      detail,
    },
    global: {
      stubs: {
        YPanelSurface: {
          props: ['heading', 'muted'],
          template:
            '<section><header><slot name="actions" />{{ heading }}</header><slot /></section>',
        },
        YEmptyState: {
          props: ['heading', 'text'],
          template: '<div>{{ heading }} {{ text }}<slot /></div>',
        },
        YVisibilityBadge: {
          props: ['visibility'],
          template: '<span data-testid="visibility">{{ visibility }}</span>',
        },
        YStatusBadge: {
          props: ['label', 'tone'],
          template: '<span data-testid="status">{{ label }}</span>',
        },
        YIconButton: {
          props: ['label', 'disabled'],
          emits: ['click'],
          template:
            '<button type="button" :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
        },
      },
    },
  });
}

describe('EntityDetailShell', () => {
  beforeEach(() => {
    mockQuickStats.value = [];
    mockHooks.value = [];
    mockPartyMembers.value = [];
    mockEncounterStatblocks.value = [];
    mockPromote.mockReset();
    mockSelectEntity.mockReset();
    useQueryMock.mockReset();
    useQueryMock
      .mockReturnValueOnce({
        data: mockQuickStats,
        isPending: ref(false),
      })
      .mockReturnValueOnce({
        data: mockHooks,
        isPending: ref(false),
      })
      .mockReturnValueOnce({
        data: mockPartyMembers,
        isPending: ref(false),
      })
      .mockReturnValueOnce({
        data: mockEncounterStatblocks,
        isPending: ref(false),
      });
  });

  it('renders character quick stats, sheet link, and hooks', async () => {
    mockQuickStats.value = [
      {
        compact_label: 'HP',
        field_id: 'hp',
        field_key: 'hp',
        label: 'Hit Points',
        sort_order: 10,
        value_id: 'value-hp',
        value_number: 18,
        value_text: null,
        visibility: 'character_owner_gm',
        value_type: 'number',
      },
    ];
    mockHooks.value = [
      {
        category_label: 'Debt',
        category_option_id: 'cat-1',
        description_text: 'Owes a favor to the harbor guild.',
        gm_note_text: 'Collector is secretly a cultist.',
        id: 'hook-1',
        promoted_storyline_entity_id: null,
        promoted_storyline_label: null,
        sort_order: 10,
        status_key: 'active',
        status_label: 'Active',
        updated_at: '2026-06-13T00:00:00Z',
        visibility: 'shared',
      },
    ];

    const wrapper = mountShell({
      archived_at: null,
      campaign_id: 'campaign-1',
      controlling_user_display_label: 'Tamsin',
      controlling_user_id: 'user-1',
      default_visibility: 'shared',
      encounter_type_label: null,
      entity_id: 'character-1',
      entity_type_key: 'character',
      entity_type_label: 'Character',
      is_major: null,
      list_caption: 'Ari Voss',
      location_type_label: null,
      npc_apparent_status_label: null,
      npc_real_status_label: null,
      parent_entity_id: null,
      parent_entity_label: null,
      related_session_entity_id: null,
      related_session_label: null,
      related_storyline_entity_id: null,
      related_storyline_label: null,
      relevant_date: null,
      sections: [
        {
          id: 'details',
          section_key: 'details',
          label: 'Details',
          visibility: 'shared',
          edit_policy: 'gm_edit',
          content_mode: 'rich_text',
          body_preview: 'Brief public description.',
          version_number: 1,
        },
      ],
      sort_key: null,
      status_key: 'active',
      status_label: 'Active',
      storyline_category_label: null,
      storyline_priority_label: null,
      storyline_type: null,
      timeline_date_expression: null,
      timeline_event_type_label: null,
      typed_data: {
        species_ancestry_text: 'Elf',
        pronouns: 'they/them',
        public_summary: 'A careful scout.',
        gm_summary: 'Working with a hidden patron.',
        character_sheet_url: 'https://example.com/character-sheet',
      },
      updated_at: '2026-06-13T01:00:00Z',
    });

    expect(wrapper.text()).toContain('Ari Voss');
    expect(wrapper.text()).toContain('Character Sheet');
    expect(wrapper.text()).toContain('https://example.com/character-sheet');
    expect(wrapper.text()).toContain('HP');
    expect(wrapper.text()).toContain('18');
    expect(wrapper.text()).toContain('Owes a favor to the harbor guild.');
    expect(wrapper.text()).toContain('Collector is secretly a cultist.');
    expect(wrapper.text()).toContain('Brief public description.');

    await wrapper.get('button').trigger('click');
    expect(mockPromote).toHaveBeenCalledWith({
      characterEntityId: 'character-1',
      hookId: 'hook-1',
      visibility: 'shared',
    });
  });

  it('renders party members with active flags', () => {
    mockPartyMembers.value = [
      {
        character_entity_id: 'character-2',
        character_label: 'Bran Holt',
        character_visibility: 'shared',
        is_active: true,
        role_label: 'Scout',
        sort_order: 10,
      },
    ];

    const wrapper = mountShell({
      archived_at: null,
      campaign_id: 'campaign-1',
      controlling_user_display_label: null,
      controlling_user_id: null,
      default_visibility: 'shared',
      encounter_type_label: null,
      entity_id: 'party-1',
      entity_type_key: 'party',
      entity_type_label: 'Party',
      is_major: null,
      list_caption: 'Ashen Company',
      location_type_label: null,
      npc_apparent_status_label: null,
      npc_real_status_label: null,
      parent_entity_id: null,
      parent_entity_label: null,
      related_session_entity_id: null,
      related_session_label: null,
      related_storyline_entity_id: null,
      related_storyline_label: null,
      relevant_date: null,
      sections: [],
      sort_key: null,
      status_key: 'active',
      status_label: 'Active',
      storyline_category_label: null,
      storyline_priority_label: null,
      storyline_type: null,
      timeline_date_expression: null,
      timeline_event_type_label: null,
      typed_data: {
        public_summary: 'A mercenary band with a bad reputation.',
        home_location: {
          id: 'location-1',
          label: 'Stone Wharf',
        },
      },
      updated_at: '2026-06-13T01:00:00Z',
    });

    expect(wrapper.text()).toContain('Ashen Company');
    expect(wrapper.text()).toContain('Stone Wharf');
    expect(wrapper.text()).toContain('Bran Holt');
    expect(wrapper.text()).toContain('Active');
    expect(wrapper.text()).toContain('Scout');
  });
});
