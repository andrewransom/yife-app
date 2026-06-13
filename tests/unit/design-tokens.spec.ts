import { describe, expect, it } from 'vitest';
import { designTokens } from '../../app/design/tokens';

describe('design tokens', () => {
  it('keeps Nuxt UI theme aliases tied to the token source', () => {
    expect(designTokens.nuxtUi.colors).toEqual([
      'primary',
      'secondary',
      'success',
      'info',
      'warning',
      'error',
      'neutral',
    ]);
    expect(designTokens.radius.lg).toBe('8px');
    expect(designTokens.component.rowHeight).toBe('2.75rem');
  });

  it('uses the standard blue palette for light and dark primary actions', () => {
    expect(designTokens.color.light.primary).toBe('#2563eb');
    expect(designTokens.color.light.surfaceMuted).toBe('#eff6ff');
    expect(designTokens.color.dark.primary).toBe('#60a5fa');
    expect(designTokens.color.dark.canvas).toBe('#020617');
  });
});
