import { defineStore } from 'pinia';

type ActiveViewPreference = 'directory' | 'detail' | 'timeline' | 'session';

export const useUiStore = defineStore('ui', {
  state: () => ({
    selectedCampaignId: null as string | null,
    activeViewPreference: 'directory' as ActiveViewPreference,
    selectedEntityId: null as string | null,
    isCommandPaletteOpen: false,
    isRightPanelCollapsed: false,
  }),
  actions: {
    selectCampaign(campaignId: string | null) {
      this.selectedCampaignId = campaignId;
      if (!campaignId) {
        this.selectedEntityId = null;
      }
    },
    selectEntity(entityId: string | null) {
      this.selectedEntityId = entityId;
    },
    setActiveViewPreference(view: ActiveViewPreference) {
      this.activeViewPreference = view;
    },
    setCommandPaletteOpen(isOpen: boolean) {
      this.isCommandPaletteOpen = isOpen;
    },
    toggleRightPanel() {
      this.isRightPanelCollapsed = !this.isRightPanelCollapsed;
    },
  },
});
