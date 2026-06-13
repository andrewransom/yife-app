import { designTokens } from '~/design/tokens';

export default defineNuxtPlugin(() => {
  const root = document.documentElement;

  function applyThemeTokens() {
    const tokens = root.classList.contains('dark')
      ? designTokens.color.dark
      : designTokens.color.light;

    root.style.setProperty('--yife-canvas', tokens.canvas);
    root.style.setProperty('--yife-surface', tokens.surface);
    root.style.setProperty('--yife-surface-muted', tokens.surfaceMuted);
    root.style.setProperty('--yife-border', tokens.border);
    root.style.setProperty('--yife-text', tokens.text);
    root.style.setProperty('--yife-text-muted', tokens.textMuted);
    root.style.setProperty('--yife-primary', tokens.primary);
    root.style.setProperty('--yife-primary-text', tokens.primaryText);
    root.style.setProperty('--yife-secondary', tokens.secondary);
    root.style.setProperty('--yife-accent', tokens.accent);
    root.style.setProperty('--yife-success', tokens.success);
    root.style.setProperty('--yife-info', tokens.info);
    root.style.setProperty('--yife-warning', tokens.warning);
    root.style.setProperty('--yife-error', tokens.error);
    root.style.setProperty('--yife-focus', tokens.focus);
    root.style.setProperty('--ui-primary', tokens.primary);
    root.style.setProperty('--ui-secondary', tokens.secondary);
    root.style.setProperty('--ui-success', tokens.success);
    root.style.setProperty('--ui-info', tokens.info);
    root.style.setProperty('--ui-warning', tokens.warning);
    root.style.setProperty('--ui-error', tokens.error);
    root.style.setProperty('--ui-bg', tokens.canvas);
    root.style.setProperty('--ui-bg-muted', tokens.surfaceMuted);
    root.style.setProperty('--ui-bg-elevated', tokens.surface);
    root.style.setProperty('--ui-border', tokens.border);
    root.style.setProperty('--ui-text', tokens.text);
    root.style.setProperty('--ui-text-muted', tokens.textMuted);
  }

  applyThemeTokens();

  new MutationObserver(applyThemeTokens).observe(root, {
    attributeFilter: ['class'],
    attributes: true,
  });
});
