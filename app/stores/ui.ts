import { defineStore } from 'pinia';

type ActiveViewPreference = 'directory' | 'detail' | 'timeline' | 'session';
type CampaignRoleViewPreference = 'gm' | 'player';

export const useUiStore = defineStore('ui', {
  state: () => ({
    selectedCampaignId: null as string | null,
    activeViewPreference: 'directory' as ActiveViewPreference,
    campaignRoleViewPreferences: {} as Record<string, CampaignRoleViewPreference>,
    currentSessionOverrides: {} as Record<string, string | null>,
    selectedEntityId: null as string | null,
    isCommandPaletteOpen: false,
    isRightPanelCollapsed: false,
  }),
  actions: {
    selectCampaign(campaignId: string | null) {
      if (this.selectedCampaignId !== campaignId) {
        this.selectedEntityId = null;
      }
      this.selectedCampaignId = campaignId;
    },
    selectEntity(entityId: string | null) {
      this.selectedEntityId = entityId;
    },
    setActiveViewPreference(view: ActiveViewPreference) {
      this.activeViewPreference = view;
    },
    setCampaignRoleViewPreference(campaignId: string, view: CampaignRoleViewPreference) {
      this.campaignRoleViewPreferences = {
        ...this.campaignRoleViewPreferences,
        [campaignId]: view,
      };
    },
    setCurrentSessionOverride(campaignId: string, entityId: string | null) {
      this.currentSessionOverrides = {
        ...this.currentSessionOverrides,
        [campaignId]: entityId,
      };
    },
    getCurrentSessionOverride(campaignId: string | null) {
      return campaignId ? (this.currentSessionOverrides[campaignId] ?? null) : null;
    },
    getCampaignRoleViewPreference(campaignId: string | null) {
      return campaignId ? (this.campaignRoleViewPreferences[campaignId] ?? null) : null;
    },
    setCommandPaletteOpen(isOpen: boolean) {
      this.isCommandPaletteOpen = isOpen;
    },
    toggleRightPanel() {
      this.isRightPanelCollapsed = !this.isRightPanelCollapsed;
    },
  },
});
