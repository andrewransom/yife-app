import { computed } from 'vue';
import { canRunProtectedQueries } from '~/utils/protected-bootstrap';
import { useCurrentUser } from './useCurrentUser';
import { useEnsureUserProfile } from './useEnsureUserProfile';

export function useProtectedAppBootstrap() {
  const user = useCurrentUser();
  const defaultsQuery = useEnsureUserProfile({
    enabled: computed(() => Boolean(user.value)),
  });

  const isReady = computed(() =>
    canRunProtectedQueries({
      hasUser: Boolean(user.value),
      isPending: defaultsQuery.isPending.value,
      isSuccess: defaultsQuery.isSuccess.value,
      isError: defaultsQuery.isError.value,
    }),
  );

  return {
    user,
    defaults: defaultsQuery.data,
    error: defaultsQuery.error,
    isInitializing: computed(() => Boolean(user.value) && defaultsQuery.isPending.value),
    isReady,
    isError: defaultsQuery.isError,
    retry: defaultsQuery.refetch,
  };
}
