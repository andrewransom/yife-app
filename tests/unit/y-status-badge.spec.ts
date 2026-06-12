import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import YStatusBadge from '../../app/components/yife/YStatusBadge.vue';

describe('YStatusBadge', () => {
  it('renders a compact status label', () => {
    const wrapper = mount(YStatusBadge, {
      props: {
        label: 'Active',
        tone: 'success',
      },
      global: {
        stubs: {
          UBadge: {
            props: ['color', 'variant', 'size'],
            template:
              '<span data-testid="badge" :data-color="color" :data-variant="variant" :data-size="size"><slot /></span>',
          },
        },
      },
    });

    expect(wrapper.get('[data-testid="badge"]').text()).toBe('Active');
    expect(wrapper.get('[data-testid="badge"]').attributes('data-color')).toBe('success');
    expect(wrapper.get('[data-testid="badge"]').attributes('data-size')).toBe('sm');
  });
});
