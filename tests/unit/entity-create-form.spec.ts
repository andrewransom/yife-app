import { nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import EntityCreateForm from '../../app/components/entities/EntityCreateForm.vue';

const mockStatuses = ref([{ id: 'status-open', key: 'open', label: 'Open' }]);
const mockOptions = ref([{ id: 'priority-high', key: 'high', label: 'High' }]);
const mockMembers = ref<{ user_id: string; display_name: string | null; display_name_override: string | null }[]>([]);
const mockMutateAsync = vi.fn();

vi.mock('../../app/composables/auth/useCurrentUser', () => ({
  useCurrentUser: () => ref({ id: 'user-1' }),
}));

vi.mock('../../app/composables/campaigns/useCampaignMemberProfilesQuery', () => ({
  useCampaignMemberProfilesQuery: () => ({
    data: mockMembers,
  }),
}));

vi.mock('../../app/composables/entities/useCampaignOptionsQuery', () => ({
  useCampaignOptionsQuery: () => ({
    data: mockOptions,
  }),
}));

vi.mock('../../app/composables/entities/useCreateEntityMutation', () => ({
  useCreateEntityMutation: () => ({
    isPending: ref(false),
    mutateAsync: mockMutateAsync,
  }),
}));

vi.mock('../../app/composables/entities/useEntityStatusOptionsQuery', () => ({
  useEntityStatusOptionsQuery: () => ({
    data: mockStatuses,
  }),
}));

function mountForm() {
  return mount(EntityCreateForm, {
    props: {
      campaignId: 'campaign-1',
      entityTypes: [
        {
          entity_type_key: 'storyline',
          label: 'Storyline',
          can_create: true,
        },
        {
          entity_type_key: 'npc',
          label: 'NPC',
          can_create: true,
        },
      ],
      initialTypeKey: 'storyline',
    },
    global: {
      stubs: {
        YFormField: {
          props: ['label', 'name'],
          template: '<label><span>{{ label }}</span><slot /></label>',
        },
        YDenseButton: {
          props: ['type', 'disabled', 'loading', 'color', 'variant'],
          emits: ['click'],
          template:
            '<button :type="type || \'button\'" :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
        },
        UInput: {
          props: ['modelValue', 'type', 'size', 'autocomplete'],
          emits: ['update:modelValue'],
          template:
            '<input :type="type || \'text\'" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
        },
        Save: {
          template: '<span />',
        },
      },
    },
  });
}

describe('EntityCreateForm', () => {
  beforeEach(() => {
    mockMutateAsync.mockReset();
    mockMutateAsync.mockResolvedValue({
      entity_id: 'storyline-1',
    });
    mockMembers.value = [];
    mockStatuses.value = [{ id: 'status-open', key: 'open', label: 'Open' }];
    mockOptions.value = [{ id: 'priority-high', key: 'high', label: 'High' }];
  });

  it('uses the storyline create surface with quest/thread subtypes', async () => {
    const wrapper = mountForm();
    await nextTick();

    const selects = wrapper.findAll('select');

    expect(selects[0]?.text()).toContain('Storyline');
    expect(selects[0]?.text()).not.toContain('Plot Arc');
    expect(selects[0]?.text()).not.toContain('Quest');
    expect(selects[2]?.text()).toContain('Quest');
    expect(selects[2]?.text()).toContain('Thread');
  });

  it('preselects storyline defaults for the canonical create surface', async () => {
    const wrapper = mountForm();
    await nextTick();

    const selects = wrapper.findAll('select');

    expect((selects[1]?.element as HTMLSelectElement).value).toBe('status-open');
    expect((selects[2]?.element as HTMLSelectElement).value).toBe('quest');
    expect((selects[3]?.element as HTMLSelectElement).value).toBe('priority-high');
    expect(wrapper.text()).toContain('Major storyline');
  });
});
