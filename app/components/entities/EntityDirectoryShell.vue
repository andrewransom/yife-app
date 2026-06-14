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
    storylineType?: string;
    storylineCategoryLabel?: string;
    storylinePriorityLabel?: string;
    storylineMajorMode?: 'all' | 'major' | 'minor';
    encounterTypeLabel?: string;
    relatedSessionEntityId?: string;
    isLoading?: boolean;
    canCreate?: boolean;
  }>(),
  {
    statuses: () => [],
    selectedEntityId: null,
    selectedTypeKey: 'all',
    statusKey: '',
    search: '',
    storylineType: '',
    storylineCategoryLabel: '',
    storylinePriorityLabel: '',
    storylineMajorMode: 'all',
    encounterTypeLabel: '',
    relatedSessionEntityId: '',
    isLoading: false,
    canCreate: false,
  },
);

const emit = defineEmits<{
  'update:selectedTypeKey': [value: string];
  'update:statusKey': [value: string];
  'update:search': [value: string];
  'update:storylineType': [value: string];
  'update:storylineCategoryLabel': [value: string];
  'update:storylinePriorityLabel': [value: string];
  'update:storylineMajorMode': [value: 'all' | 'major' | 'minor'];
  'update:encounterTypeLabel': [value: string];
  'update:relatedSessionEntityId': [value: string];
  select: [entityId: string];
  create: [];
}>();

const filteredSummaries = computed(() =>
  filterEntitySummaries(props.summaries, {
    entityTypeKey: props.selectedTypeKey,
    statusKey: props.statusKey,
    search: props.search,
    storylineType: props.storylineType,
    storylineCategoryLabel: props.storylineCategoryLabel,
    storylinePriorityLabel: props.storylinePriorityLabel,
    storylineMajorMode: props.storylineMajorMode,
    encounterTypeLabel: props.encounterTypeLabel,
    relatedSessionEntityId: props.relatedSessionEntityId,
  }),
);

const storylineCategories = computed(() =>
  Array.from(
    new Set(
      props.summaries
        .filter((summary) => summary.entity_type_key === 'storyline')
        .map((summary) => summary.storyline_category_label)
        .filter((value): value is string => Boolean(value)),
    ),
  ).sort((left, right) => left.localeCompare(right)),
);

const storylinePriorities = computed(() =>
  Array.from(
    new Set(
      props.summaries
        .filter((summary) => summary.entity_type_key === 'storyline')
        .map((summary) => summary.storyline_priority_label)
        .filter((value): value is string => Boolean(value)),
    ),
  ).sort((left, right) => left.localeCompare(right)),
);

const encounterTypes = computed(() =>
  Array.from(
    new Set(
      props.summaries
        .filter((summary) => summary.entity_type_key === 'encounter')
        .map((summary) => summary.encounter_type_label)
        .filter((value): value is string => Boolean(value)),
    ),
  ).sort((left, right) => left.localeCompare(right)),
);

const sessionOptions = computed(() =>
  props.summaries.filter((summary) => summary.entity_type_key === 'session'),
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
      <div v-if="selectedTypeKey === 'storyline'" class="mt-2 grid gap-2">
        <div class="grid gap-2 sm:grid-cols-2">
          <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
            Type
            <select
              :value="storylineType"
              class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
              @change="emit('update:storylineType', ($event.target as HTMLSelectElement).value)"
            >
              <option value="">All types</option>
              <option value="quest">Quest</option>
              <option value="thread">Thread</option>
            </select>
          </label>
          <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
            Scope
            <select
              :value="storylineMajorMode"
              class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
              @change="
                emit(
                  'update:storylineMajorMode',
                  ($event.target as HTMLSelectElement).value as 'all' | 'major' | 'minor',
                )
              "
            >
              <option value="all">All</option>
              <option value="major">Major only</option>
              <option value="minor">Minor only</option>
            </select>
          </label>
        </div>
        <div class="grid gap-2 sm:grid-cols-2">
          <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
            Category
            <select
              :value="storylineCategoryLabel"
              class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
              @change="
                emit('update:storylineCategoryLabel', ($event.target as HTMLSelectElement).value)
              "
            >
              <option value="">All categories</option>
              <option v-for="category in storylineCategories" :key="category" :value="category">
                {{ category }}
              </option>
            </select>
          </label>
          <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
            Priority
            <select
              :value="storylinePriorityLabel"
              class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
              @change="
                emit('update:storylinePriorityLabel', ($event.target as HTMLSelectElement).value)
              "
            >
              <option value="">All priorities</option>
              <option
                v-for="priority in storylinePriorities"
                :key="priority"
                :value="priority"
              >
                {{ priority }}
              </option>
            </select>
          </label>
        </div>
      </div>
      <div v-if="selectedTypeKey === 'encounter'" class="mt-2 grid gap-2">
        <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
          Encounter type
          <select
            :value="encounterTypeLabel"
            class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
            @change="
              emit('update:encounterTypeLabel', ($event.target as HTMLSelectElement).value)
            "
          >
            <option value="">All encounter types</option>
            <option v-for="type in encounterTypes" :key="type" :value="type">
              {{ type }}
            </option>
          </select>
        </label>
        <label class="block text-xs font-medium uppercase text-[var(--yife-text-muted)]">
          Related session
          <select
            :value="relatedSessionEntityId"
            class="mt-1 h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
            @change="
              emit('update:relatedSessionEntityId', ($event.target as HTMLSelectElement).value)
            "
          >
            <option value="">All sessions</option>
            <option
              v-for="session in sessionOptions"
              :key="session.entity_id"
              :value="session.entity_id"
            >
              {{ session.list_caption }}
            </option>
          </select>
        </label>
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
