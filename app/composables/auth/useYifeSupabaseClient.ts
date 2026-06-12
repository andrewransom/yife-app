import { useSupabaseClient } from '#imports';
import type { Database } from '~/types/database.types';

export function useYifeSupabaseClient() {
  return useSupabaseClient<Database>();
}
