import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useUiStore } from '~/stores/ui';
import { useCampaignMembershipSummaryQuery } from './useCampaignMembershipSummaryQuery';

type RoleViewMode = 'gm' | 'player' | 'mixed';
type RoleViewPreference = 'gm' | 'player';

export function useCampaignRoleViewContext(
  campaignId: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const uiStore = useUiStore();
  const membershipQuery = useCampaignMembershipSummaryQuery(campaignId, options);

  const roleKeys = computed(() => membershipQuery.data.value?.role_keys ?? []);
  const isOwner = computed(() => roleKeys.value.includes('owner'));
  const isGameMaster = computed(() => isOwner.value || roleKeys.value.includes('game_master'));
  const isPlayer = computed(() => roleKeys.value.includes('player'));
  const workspaceMode = computed<RoleViewMode>(() => {
    if (isGameMaster.value && isPlayer.value) {
      return 'mixed';
    }

    if (isGameMaster.value) {
      return 'gm';
    }

    return 'player';
  });
  const selectedViewPreference = computed<RoleViewPreference>(() => {
    const id = toValue(campaignId);
    const stored = uiStore.getCampaignRoleViewPreference(id || null);

    if (workspaceMode.value !== 'mixed') {
      return workspaceMode.value === 'gm' ? 'gm' : 'player';
    }

    return stored === 'player' ? 'player' : 'gm';
  });
  const activeRoleView = computed<RoleViewPreference>(() => {
    if (workspaceMode.value === 'mixed') {
      return selectedViewPreference.value;
    }

    return workspaceMode.value === 'gm' ? 'gm' : 'player';
  });
  const isPlayerPreview = computed(
    () => workspaceMode.value === 'mixed' && activeRoleView.value === 'player',
  );

  function setSelectedViewPreference(view: RoleViewPreference) {
    const id = toValue(campaignId);

    if (!id || workspaceMode.value !== 'mixed') {
      return;
    }

    uiStore.setCampaignRoleViewPreference(id, view);
  }

  return {
    membershipQuery,
    roleKeys,
    isOwner,
    isGameMaster,
    isPlayer,
    workspaceMode,
    selectedViewPreference,
    activeRoleView,
    isPlayerPreview,
    setSelectedViewPreference,
  };
}
