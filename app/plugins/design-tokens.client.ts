import { designTokens } from '~/design/tokens';

export default defineNuxtPlugin(() => {
  const root = document.documentElement;
  const light = designTokens.color.light;

  root.style.setProperty('--yife-canvas', light.canvas);
  root.style.setProperty('--yife-surface', light.surface);
  root.style.setProperty('--yife-surface-muted', light.surfaceMuted);
  root.style.setProperty('--yife-border', light.border);
  root.style.setProperty('--yife-text', light.text);
  root.style.setProperty('--yife-text-muted', light.textMuted);
  root.style.setProperty('--yife-primary', light.primary);
  root.style.setProperty('--yife-primary-text', light.primaryText);
  root.style.setProperty('--yife-secondary', light.secondary);
  root.style.setProperty('--yife-accent', light.accent);
  root.style.setProperty('--yife-success', light.success);
  root.style.setProperty('--yife-info', light.info);
  root.style.setProperty('--yife-warning', light.warning);
  root.style.setProperty('--yife-error', light.error);
  root.style.setProperty('--yife-focus', light.focus);
});
