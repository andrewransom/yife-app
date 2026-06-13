<script setup lang="ts">
import { computed } from 'vue';
import { Plus, Search } from 'lucide-vue-next';
import type {
  EntityStatusOption,
  EntitySummary,
  EntityTypeOption,
} from '~/composables/entities/types';
import { filterEntitySummaries } from '~/utils/entity-directory';

const props = withDefaults(
  defineProps<{
    summaries: EntitySummary[];
    entityTypes: EntityTypeOption[];
    statuses?: EntityStatusOption[];
    selectedEntityId?: string | null;
    selectedTypeKey?: string;
    statusKey?: string;
    search?: string;
    isLoading?: boolean;
    canCreate?: boolean;
  }>(),
  {
    statuses: () => [],
    selectedEntityId: null,
    selectedTypeKey: 'all',
    statusKey: '',
    search: '',
    isLoading: false,
    canCreate: false,
  },
);

const emit = defineEmits<{
  'update:selectedTypeKey': [value: string];
  'update:statusKey': [value: string];
  'update:search': [value: string];
  select: [entityId: string];
  create: [];
}>();

const filteredSummaries = computed(() =>
  filterEntitySummaries(props.summaries, {
    entityTypeKey: props.selectedTypeKey,
    statusKey: props.statusKey,
    search: props.search,
  }),
);
</script>

<template>
  <div class="flex h-full min-h-0 flex-col">
    <div class="border-b border-[var(--yife-border)] p-2">
      <div class="flex items-center gap-1">
        <label class="relative min-w-0 flex-1">
          <Search
            class="pointer-events-none absolute left-2 top-1/2 size-3 -translate-y-1/2 text-[var(--yife-text-muted)]"
            aria-hidden="true"
          />
          <input
            class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-7 text-sm"
            :value="search"
            placeholder="Find"
            @input="emit('update:search', ($event.target as HTMLInputElement).value)"
          />
          <span class="sr-only">Search entities</span>
        </label>
        <YIconButton
          :icon="Plus"
          label="Create entity"
          :disabled="!canCreate"
          @click="emit('create')"
        />
      </div>
      <div class="mt-2">
        <EntityTypeFilterGroup
          :model-value="selectedTypeKey"
          :entity-types="entityTypes"
          @update:model-value="emit('update:selectedTypeKey', $event)"
        />
      </div>
      <div v-if="statuses.length" class="mt-2">
        <EntityStatusFilter
          :model-value="statusKey"
          :statuses="statuses"
          @update:model-value="emit('update:statusKey', $event)"
        />
      </div>
    </div>

    <div v-if="isLoading" class="p-2">
      <YEntityRowSkeleton v-for="index in 5" :key="index" title="Loading" caption="Entity" />
    </div>

    <YEmptyState
      v-else-if="!filteredSummaries.length"
      heading="No records"
      text="Create or adjust filters."
      class="m-2"
    />

    <div v-else class="min-h-0 flex-1 overflow-auto">
      <EntityDirectoryRow
        v-for="summary in filteredSummaries"
        :key="summary.entity_id"
        :summary="summary"
        :active="summary.entity_id === selectedEntityId"
        @select="emit('select', $event)"
      />
    </div>
  </div>
</template>
