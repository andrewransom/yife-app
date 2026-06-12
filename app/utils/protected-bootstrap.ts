export type ProtectedBootstrapState = {
  hasUser: boolean;
  isPending: boolean;
  isSuccess: boolean;
  isError: boolean;
};

export function canRunProtectedQueries(state: ProtectedBootstrapState) {
  return state.hasUser && state.isSuccess && !state.isPending && !state.isError;
}
