<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { ExternalLink, Link2, Sparkles } from 'lucide-vue-next';
import { useUiStore } from '~/stores/ui';
import { getPaletteTokenStyle } from '~/utils/campaign-settings';
import { useCharacterHooksQuery } from '~/composables/entities/useCharacterHooksQuery';
import { useEncounterStatblocksQuery } from '~/composables/entities/useEncounterStatblocksQuery';
import { useEntityQuickStatsQuery } from '~/composables/entities/useEntityQuickStatsQuery';
import { usePartyMembersQuery } from '~/composables/entities/usePartyMembersQuery';
import { usePromoteCharacterHookMutation } from '~/composables/entities/usePromoteCharacterHookMutation';
import type {
  CharacterHook,
  EncounterStatblock,
  EntityDetail,
  EntityQuickStat,
} from '~/composables/entities/types';

const props = withDefaults(
  defineProps<{
    detail?: EntityDetail | null;
    isLoading?: boolean;
    isUnavailable?: boolean;
  }>(),
  {
    detail: null,
    isLoading: false,
    isUnavailable: false,
  },
);

type Visibility = 'shared' | 'gm_only' | 'private' | 'character_owner_gm';
type SectionSummary = {
  id: string;
  section_key: string;
  label: string;
  visibility: Visibility;
  edit_policy: string;
  content_mode: string;
  body_preview?: string | null;
  version_number?: number | null;
};
type EntityRef = { id: string; label: string };
type PaletteColor = {
  id: string;
  key: string;
  label: string;
  color_token: string;
  text_color_token?: string | null;
};
type SymbolData = { id: string; key: string; label: string; icon_key: string };
type DetailItem = {
  label: string;
  value: string;
  visibility?: Visibility;
  href?: string;
  entityId?: string;
};
type DetailBlock = {
  label: string;
  value: string;
  visibility?: Visibility;
};
type EncounterStatblockValue = {
  field_id: string;
  field_key: string;
  label: string;
  compact_label: string;
  value_type: string;
  value_id: string | null;
  value_number: number | null;
  value_text: string | null;
};
type EncounterStatblockInstance = {
  id: string;
  label: string;
  current_hp: number | null;
  max_hp_override: number | null;
  is_defeated: boolean;
  sort_order: number;
};

const uiStore = useUiStore();
const promotionSelections = ref<Record<string, 'shared' | 'private'>>({});
const promotionError = ref('');
const promoteHook = usePromoteCharacterHookMutation();

const entityId = computed(() => props.detail?.entity_id ?? null);
const entityTypeKey = computed(() => props.detail?.entity_type_key ?? '');
const typedData = computed<Record<string, unknown>>(() => asRecord(props.detail?.typed_data));
const sections = computed<SectionSummary[]>(() =>
  Array.isArray(props.detail?.sections) ? (props.detail.sections as SectionSummary[]) : [],
);

const quickStatsQuery = useEntityQuickStatsQuery(entityId, {
  enabled: computed(() => ['character', 'npc'].includes(entityTypeKey.value)),
});
const characterHooksQuery = useCharacterHooksQuery(entityId, {
  enabled: computed(() => entityTypeKey.value === 'character'),
});
const partyMembersQuery = usePartyMembersQuery(entityId, {
  enabled: computed(() => entityTypeKey.value === 'party'),
});
const encounterStatblocksQuery = useEncounterStatblocksQuery(entityId, {
  enabled: computed(() => entityTypeKey.value === 'encounter'),
});

const quickStats = computed(() => quickStatsQuery.data.value ?? []);
const characterHooks = computed(() => characterHooksQuery.data.value ?? []);
const partyMembers = computed(() => partyMembersQuery.data.value ?? []);
const encounterStatblocks = computed(() => encounterStatblocksQuery.data.value ?? []);
const isQuickStatsLoading = computed(() => quickStatsQuery.isPending.value);
const isCharacterHooksLoading = computed(() => characterHooksQuery.isPending.value);
const isPartyMembersLoading = computed(() => partyMembersQuery.isPending.value);
const isEncounterStatblocksLoading = computed(() => encounterStatblocksQuery.isPending.value);

watch(
  characterHooks,
  (hooks) => {
    const nextSelections: Record<string, 'shared' | 'private'> = {};

    for (const hook of hooks) {
      if (hook.visibility === 'shared') {
        nextSelections[hook.id] = promotionSelections.value[hook.id] ?? 'shared';
      }
    }

    promotionSelections.value = nextSelections;
  },
  { immediate: true },
);

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function stringValue(value: unknown) {
  return typeof value === 'string' && value.trim().length ? value.trim() : null;
}

function numberValue(value: unknown) {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

function booleanValue(value: unknown) {
  return typeof value === 'boolean' ? value : null;
}

function entityRef(value: unknown): EntityRef | null {
  const record = asRecord(value);
  const id = stringValue(record.id);
  const label = stringValue(record.label);

  return id && label ? { id, label } : null;
}

function paletteColor(value: unknown): PaletteColor | null {
  const record = asRecord(value);
  const id = stringValue(record.id);
  const key = stringValue(record.key);
  const label = stringValue(record.label);
  const colorToken = stringValue(record.color_token);

  if (!id || !key || !label || !colorToken) {
    return null;
  }

  return {
    id,
    key,
    label,
    color_token: colorToken,
    text_color_token: stringValue(record.text_color_token),
  };
}

function symbolData(value: unknown): SymbolData | null {
  const record = asRecord(value);
  const id = stringValue(record.id);
  const key = stringValue(record.key);
  const label = stringValue(record.label);
  const iconKey = stringValue(record.icon_key);

  return id && key && label && iconKey ? { id, key, label, icon_key: iconKey } : null;
}

function formatDate(value: string | null | undefined) {
  if (!value) {
    return '';
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(`${value}T00:00:00`));
}

function formatDateTime(value: string | null | undefined) {
  if (!value) {
    return '';
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}

function formatStatValue(stat: EntityQuickStat) {
  if (stat.value_type === 'number') {
    return stat.value_number === null ? 'Unset' : String(stat.value_number);
  }

  return stat.value_text || 'Unset';
}

function formatEncounterValue(value: EncounterStatblockValue) {
  if (value.value_type === 'number') {
    return value.value_number === null ? 'Unset' : String(value.value_number);
  }

  return value.value_text || 'Unset';
}

function pushItem(
  items: DetailItem[],
  label: string,
  value: string | null,
  options?: { visibility?: Visibility; href?: string; entityId?: string },
) {
  if (!value) {
    return;
  }

  items.push({
    label,
    value,
    visibility: options?.visibility,
    href: options?.href,
    entityId: options?.entityId,
  });
}

function pushBlock(
  blocks: DetailBlock[],
  label: string,
  value: string | null,
  options?: { visibility?: Visibility },
) {
  if (!value) {
    return;
  }

  blocks.push({
    label,
    value,
    visibility: options?.visibility,
  });
}

function openEntity(id: string | null | undefined) {
  if (!id) {
    return;
  }

  uiStore.selectEntity(id);
}

const metadata = computed(() => {
  const items = [
    props.detail?.status_label,
    formatDate(props.detail?.relevant_date),
    props.detail?.location_type_label,
    props.detail?.encounter_type_label,
    props.detail?.storyline_type,
    props.detail?.storyline_priority_label,
    props.detail?.storyline_category_label,
    props.detail?.timeline_date_expression,
    props.detail?.controlling_user_display_label
      ? `Controller: ${props.detail.controlling_user_display_label}`
      : '',
    props.detail?.parent_entity_label ? `Parent: ${props.detail.parent_entity_label}` : '',
    props.detail?.related_session_label ? `Session: ${props.detail.related_session_label}` : '',
    props.detail?.related_storyline_label
      ? `Storyline: ${props.detail.related_storyline_label}`
      : '',
    props.detail?.is_major ? 'Major' : '',
  ];

  return items.filter((item): item is string => Boolean(item));
});

const detailItems = computed<DetailItem[]>(() => {
  const items: DetailItem[] = [];
  const data = typedData.value;

  switch (entityTypeKey.value) {
    case 'character':
      pushItem(items, 'Species / ancestry', stringValue(data.species_ancestry_text));
      pushItem(items, 'Pronouns', stringValue(data.pronouns));
      pushItem(items, 'Controller', props.detail?.controlling_user_display_label ?? null, {
        visibility: 'character_owner_gm',
      });
      pushItem(items, 'Character Sheet', stringValue(data.character_sheet_url), {
        href: stringValue(data.character_sheet_url) ?? undefined,
      });
      break;
    case 'npc':
      pushItem(items, 'Faction', entityRef(data.faction)?.label ?? null, {
        entityId: entityRef(data.faction)?.id,
      });
      pushItem(items, 'Role', stringValue(data.role_label));
      pushItem(items, 'Disposition', stringValue(data.party_disposition_label));
      pushItem(items, 'Relationship', stringValue(data.relationship_to_party_text));
      pushItem(items, 'Current location', entityRef(data.public_current_location)?.label ?? null, {
        entityId: entityRef(data.public_current_location)?.id,
      });
      pushItem(items, 'Home location', entityRef(data.public_home_location)?.label ?? null, {
        entityId: entityRef(data.public_home_location)?.id,
      });
      pushItem(items, 'Reports to', entityRef(data.reports_to)?.label ?? null, {
        entityId: entityRef(data.reports_to)?.id,
      });
      pushItem(items, 'Speech', stringValue(data.speech_text), { visibility: 'gm_only' });
      pushItem(items, 'True location', entityRef(data.gm_current_location)?.label ?? null, {
        visibility: 'gm_only',
        entityId: entityRef(data.gm_current_location)?.id,
      });
      pushItem(items, 'True home', entityRef(data.gm_home_location)?.label ?? null, {
        visibility: 'gm_only',
        entityId: entityRef(data.gm_home_location)?.id,
      });
      break;
    case 'party':
      pushItem(items, 'Home location', entityRef(data.home_location)?.label ?? null, {
        entityId: entityRef(data.home_location)?.id,
      });
      pushItem(items, 'Current location', entityRef(data.current_location)?.label ?? null, {
        entityId: entityRef(data.current_location)?.id,
      });
      break;
    case 'faction':
      pushItem(items, 'Parent faction', entityRef(data.parent_faction)?.label ?? null, {
        entityId: entityRef(data.parent_faction)?.id,
      });
      pushItem(items, 'Type', stringValue(data.faction_type_label));
      pushItem(items, 'Scope', stringValue(data.scope_label));
      pushItem(items, 'Disposition', stringValue(data.party_disposition_label));
      pushItem(items, 'Relationship', stringValue(data.relationship_to_party_text));
      pushItem(items, 'Headquarters', entityRef(data.headquarters_location)?.label ?? null, {
        visibility: 'gm_only',
        entityId: entityRef(data.headquarters_location)?.id,
      });
      pushItem(items, 'Territory', entityRef(data.territory_location)?.label ?? null, {
        entityId: entityRef(data.territory_location)?.id,
      });
      pushItem(items, 'Leader', entityRef(data.leader)?.label ?? null, {
        visibility: 'gm_only',
        entityId: entityRef(data.leader)?.id,
      });
      pushItem(items, 'Numbers', stringValue(data.numbers_text), { visibility: 'gm_only' });
      break;
    case 'location':
      pushItem(items, 'Relationship', stringValue(data.relationship_to_party_text));
      pushItem(items, 'Disposition', stringValue(data.party_disposition_label));
      pushItem(items, 'Terrain', stringValue(data.terrain_label));
      pushItem(items, 'Accessibility', stringValue(data.accessibility_label));
      pushItem(items, 'Population', stringValue(data.population_text));
      pushItem(items, 'Scale', stringValue(data.size_or_scale_text));
      pushItem(items, 'Danger', stringValue(data.danger_level_label), {
        visibility: 'gm_only',
      });
      pushItem(
        items,
        'Controlling faction',
        entityRef(data.controlling_faction)?.label ?? null,
        { visibility: 'gm_only', entityId: entityRef(data.controlling_faction)?.id },
      );
      pushItem(items, 'Owner / steward', entityRef(data.owner_or_steward)?.label ?? null, {
        visibility: 'gm_only',
        entityId: entityRef(data.owner_or_steward)?.id,
      });
      pushItem(items, 'Ruler / authority', entityRef(data.ruler_or_authority)?.label ?? null, {
        visibility: 'gm_only',
        entityId: entityRef(data.ruler_or_authority)?.id,
      });
      break;
    case 'storyline':
      pushItem(items, 'Primary location', entityRef(data.primary_location)?.label ?? null, {
        entityId: entityRef(data.primary_location)?.id,
      });
      pushItem(items, 'Reward', stringValue(data.reward_text));
      pushItem(items, 'Completed', formatDateTime(stringValue(data.completed_at)));
      pushItem(items, 'Sort order', numberValue(data.sort_order)?.toString() ?? null);
      break;
    case 'session':
      pushItem(items, 'Title', stringValue(data.title));
      pushItem(items, 'Session number', stringValue(data.session_number_label));
      pushItem(items, 'Start time', stringValue(data.start_time));
      pushItem(items, 'End time', stringValue(data.end_time));
      break;
    case 'encounter':
      pushItem(items, 'Title', stringValue(data.title));
      pushItem(items, 'Difficulty', stringValue(data.difficulty_label));
      pushItem(items, 'Sort order', numberValue(data.sort_order)?.toString() ?? null);
      break;
    case 'timeline_event':
      pushItem(items, 'Location', entityRef(data.primary_location)?.label ?? null, {
        entityId: entityRef(data.primary_location)?.id,
      });
      break;
  }

  return items;
});

const detailBlocks = computed<DetailBlock[]>(() => {
  const blocks: DetailBlock[] = [];
  const data = typedData.value;

  switch (entityTypeKey.value) {
    case 'character':
      pushBlock(blocks, 'Public summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      break;
    case 'npc':
      pushBlock(blocks, 'Public summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      break;
    case 'party':
      pushBlock(blocks, 'Public summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      break;
    case 'faction':
      pushBlock(blocks, 'Public summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      pushBlock(blocks, 'Public goal', stringValue(data.public_goal_text));
      pushBlock(blocks, 'True goal', stringValue(data.gm_true_goal_text), { visibility: 'gm_only' });
      break;
    case 'location':
      pushBlock(blocks, 'Public summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      break;
    case 'storyline':
      pushBlock(blocks, 'Summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      break;
    case 'session':
      pushBlock(blocks, 'Public summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      pushBlock(blocks, 'Next teaser', stringValue(data.next_session_teaser));
      break;
    case 'timeline_event':
      pushBlock(blocks, 'Summary', stringValue(data.public_summary));
      pushBlock(blocks, 'GM summary', stringValue(data.gm_summary), { visibility: 'gm_only' });
      break;
  }

  if (entityTypeKey.value === 'location') {
    const known = booleanValue(data.known_to_party);
    const visited = booleanValue(data.visited_by_party);

    if (known !== null) {
      pushBlock(blocks, 'Known to party', known ? 'Yes' : 'No');
    }
    if (visited !== null) {
      pushBlock(blocks, 'Visited by party', visited ? 'Yes' : 'No');
    }
  }

  return blocks;
});

const activePalette = computed(() => paletteColor(typedData.value.palette_color));
const activeSymbol = computed(() => symbolData(typedData.value.symbol));
const canShowQuickStats = computed(
  () =>
    ['character', 'npc'].includes(entityTypeKey.value) &&
    (isQuickStatsLoading.value || quickStats.value.length > 0),
);
const canShowPartyMembers = computed(
  () => entityTypeKey.value === 'party' && (isPartyMembersLoading.value || partyMembers.value.length > 0),
);
const canShowEncounterStatblocks = computed(
  () =>
    entityTypeKey.value === 'encounter' &&
    (isEncounterStatblocksLoading.value || encounterStatblocks.value.length > 0),
);

async function handlePromoteHook(hook: CharacterHook) {
  if (!props.detail?.entity_id) {
    return;
  }

  promotionError.value = '';

  try {
    await promoteHook.mutateAsync({
      hookId: hook.id,
      characterEntityId: props.detail.entity_id,
      visibility: hook.visibility === 'shared' ? promotionSelections.value[hook.id] : undefined,
    });
  } catch (error) {
    promotionError.value =
      error instanceof Error ? error.message : 'Hook could not be promoted to a storyline.';
  }
}

function typedEncounterValues(statblock: EncounterStatblock) {
  return Array.isArray(statblock.values)
    ? (statblock.values as EncounterStatblockValue[])
    : [];
}

function typedEncounterInstances(statblock: EncounterStatblock) {
  return Array.isArray(statblock.instances)
    ? (statblock.instances as EncounterStatblockInstance[])
    : [];
}
</script>

<template>
  <YPanelSurface v-if="isLoading" heading="Opening record">
    <YEmptyState heading="Loading" text="Fetching entity detail." />
  </YPanelSurface>

  <YPanelSurface v-else-if="isUnavailable || !detail" heading="Record unavailable">
    <YEmptyState
      heading="Unavailable"
      text="This record is unavailable or you do not have access."
    />
  </YPanelSurface>

  <div v-else class="grid gap-3 xl:grid-cols-[minmax(0,1fr)_18rem]">
    <div class="space-y-3">
      <YPanelSurface>
        <template #actions>
          <YVisibilityBadge :visibility="detail.default_visibility" />
        </template>

        <div class="border-b border-[var(--yife-border)] pb-3">
          <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">
            {{ detail.entity_type_label }}
          </p>
          <h2 class="mt-1 text-xl font-semibold">{{ detail.list_caption }}</h2>
          <div class="mt-2 flex flex-wrap gap-1">
            <YStatusBadge v-for="item in metadata" :key="item" :label="item" tone="info" />
            <YStatusBadge
              v-if="detail.npc_real_status_label"
              :label="`Real: ${detail.npc_real_status_label}`"
              tone="warning"
            />
          </div>
        </div>

        <div v-if="detailItems.length" class="grid gap-3 pt-3 md:grid-cols-2 xl:grid-cols-3">
          <div
            v-for="item in detailItems"
            :key="`${item.label}-${item.value}`"
            class="min-w-0 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-2"
          >
            <div class="flex items-center gap-2">
              <p class="min-w-0 flex-1 truncate text-xs font-medium uppercase text-[var(--yife-text-muted)]">
                {{ item.label }}
              </p>
              <YVisibilityBadge v-if="item.visibility" :visibility="item.visibility" />
            </div>
            <a
              v-if="item.href"
              :href="item.href"
              target="_blank"
              rel="noreferrer"
              class="mt-1 inline-flex items-center gap-1 text-sm font-medium text-[var(--yife-link)] hover:underline"
            >
              <span class="truncate">{{ item.value }}</span>
              <ExternalLink class="size-3 shrink-0" aria-hidden="true" />
            </a>
            <button
              v-else-if="item.entityId"
              type="button"
              class="mt-1 text-left text-sm font-medium text-[var(--yife-link)] hover:underline"
              @click="openEntity(item.entityId)"
            >
              {{ item.value }}
            </button>
            <p v-else class="mt-1 break-words text-sm">{{ item.value }}</p>
          </div>
        </div>

        <div v-if="detailBlocks.length" class="grid gap-3 pt-3 md:grid-cols-2">
          <div
            v-for="block in detailBlocks"
            :key="`${block.label}-${block.value}`"
            class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
          >
            <div class="flex items-center gap-2">
              <p class="min-w-0 flex-1 truncate text-xs font-medium uppercase text-[var(--yife-text-muted)]">
                {{ block.label }}
              </p>
              <YVisibilityBadge v-if="block.visibility" :visibility="block.visibility" />
            </div>
            <p class="mt-2 whitespace-pre-wrap text-sm text-[var(--yife-text)]">
              {{ block.value }}
            </p>
          </div>
        </div>
      </YPanelSurface>

      <YPanelSurface
        v-if="canShowQuickStats"
        :heading="entityTypeKey === 'character' ? 'Quick Stats' : 'Quick Statblock'"
      >
        <YEmptyState
          v-if="isQuickStatsLoading"
          heading="Loading stats"
          text="Fetching quick stat fields."
        />
        <div v-else class="grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
          <div
            v-for="stat in quickStats"
            :key="stat.field_id"
            class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-2"
          >
            <div class="flex items-center gap-2">
              <p class="min-w-0 flex-1 truncate text-xs font-medium uppercase text-[var(--yife-text-muted)]">
                {{ stat.compact_label || stat.label }}
              </p>
              <YVisibilityBadge :visibility="stat.visibility" />
            </div>
            <p class="mt-1 text-sm font-medium">{{ formatStatValue(stat) }}</p>
          </div>
        </div>
      </YPanelSurface>

      <YPanelSurface v-if="entityTypeKey === 'character'" heading="Hooks">
        <YEmptyState
          v-if="isCharacterHooksLoading"
          heading="Loading hooks"
          text="Fetching character hooks."
        />
        <YEmptyState
          v-else-if="!characterHooks.length"
          heading="No hooks"
          text="Character hooks appear here once they are added."
        />
        <div v-else class="space-y-2">
          <article
            v-for="hook in characterHooks"
            :key="hook.id"
            class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
          >
            <div class="flex flex-wrap items-center gap-1">
              <YStatusBadge :label="hook.status_label" tone="info" />
              <YStatusBadge v-if="hook.category_label" :label="hook.category_label" />
              <YVisibilityBadge :visibility="hook.visibility" />
              <YStatusBadge
                v-if="hook.promoted_storyline_label"
                :label="`Storyline: ${hook.promoted_storyline_label}`"
                tone="success"
              />
            </div>

            <p class="mt-2 text-sm">{{ hook.description_text }}</p>

            <div
              v-if="hook.gm_note_text"
              class="mt-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-2"
            >
              <div class="flex items-center gap-2">
                <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">GM note</p>
                <YVisibilityBadge visibility="gm_only" />
              </div>
              <p class="mt-1 whitespace-pre-wrap text-sm">{{ hook.gm_note_text }}</p>
            </div>

            <div class="mt-3 flex flex-wrap items-center gap-2">
              <button
                v-if="hook.promoted_storyline_entity_id"
                type="button"
                class="text-sm font-medium text-[var(--yife-link)] hover:underline"
                @click="openEntity(hook.promoted_storyline_entity_id)"
              >
                Open storyline
              </button>

              <template v-else>
                <YIconButton
                  :icon="Sparkles"
                  label="Promote to storyline"
                  :disabled="promoteHook.isPending.value"
                  @click="handlePromoteHook(hook)"
                />
                <select
                  v-if="hook.visibility === 'shared'"
                  v-model="promotionSelections[hook.id]"
                  class="h-8 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
                >
                  <option value="shared">Promote shared</option>
                  <option value="private">Promote private</option>
                </select>
              </template>
            </div>
          </article>

          <p v-if="promotionError" class="text-sm text-[var(--yife-error)]">
            {{ promotionError }}
          </p>
        </div>
      </YPanelSurface>

      <YPanelSurface v-if="canShowPartyMembers" heading="Members">
        <YEmptyState
          v-if="isPartyMembersLoading"
          heading="Loading members"
          text="Fetching party members."
        />
        <div v-else class="space-y-2">
          <div
            v-for="member in partyMembers"
            :key="member.character_entity_id"
            class="flex flex-wrap items-center gap-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-2"
          >
            <button
              type="button"
              class="min-w-0 flex-1 truncate text-left text-sm font-medium text-[var(--yife-link)] hover:underline"
              @click="openEntity(member.character_entity_id)"
            >
              {{ member.character_label || member.character_entity_id }}
            </button>
            <YStatusBadge :label="member.is_active ? 'Active' : 'Inactive'" :tone="member.is_active ? 'success' : 'neutral'" />
            <YVisibilityBadge
              v-if="member.character_visibility"
              :visibility="member.character_visibility"
            />
            <YStatusBadge v-if="member.role_label" :label="member.role_label" />
          </div>
        </div>
      </YPanelSurface>

      <YPanelSurface v-if="canShowEncounterStatblocks" heading="Statblocks">
        <YEmptyState
          v-if="isEncounterStatblocksLoading"
          heading="Loading statblocks"
          text="Fetching encounter statblocks."
        />
        <div v-else class="space-y-3">
          <article
            v-for="statblock in encounterStatblocks"
            :key="statblock.id"
            class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
          >
            <div class="flex flex-wrap items-center gap-1">
              <h3 class="min-w-0 flex-1 truncate text-sm font-semibold">{{ statblock.label }}</h3>
              <YVisibilityBadge visibility="gm_only" />
              <YStatusBadge :label="`Qty ${statblock.quantity}`" tone="info" />
              <YStatusBadge v-if="statblock.linked_npc_label" :label="statblock.linked_npc_label" />
            </div>

            <div class="mt-3 grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
              <div
                v-for="value in typedEncounterValues(statblock)"
                :key="value.field_id"
                class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-2"
              >
                <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">
                  {{ value.compact_label || value.label }}
                </p>
                <p class="mt-1 text-sm font-medium">{{ formatEncounterValue(value) }}</p>
              </div>
            </div>

            <div v-if="typedEncounterInstances(statblock).length" class="mt-3 space-y-2">
              <div
                v-for="instance in typedEncounterInstances(statblock)"
                :key="instance.id"
                class="flex flex-wrap items-center gap-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-2"
              >
                <p class="min-w-0 flex-1 truncate text-sm font-medium">{{ instance.label }}</p>
                <YStatusBadge
                  :label="instance.is_defeated ? 'Defeated' : 'In play'"
                  :tone="instance.is_defeated ? 'warning' : 'success'"
                />
                <YStatusBadge
                  :label="`HP ${instance.current_hp ?? '—'}${instance.max_hp_override !== null ? ` / ${instance.max_hp_override}` : ''}`"
                  tone="info"
                />
              </div>
            </div>
          </article>
        </div>
      </YPanelSurface>

      <YPanelSurface heading="Sections">
        <div class="grid gap-2">
          <section
            v-for="section in sections"
            :key="section.id"
            class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
          >
            <div class="flex items-center gap-2">
              <h3 class="min-w-0 flex-1 truncate text-sm font-semibold">{{ section.label }}</h3>
              <YVisibilityBadge :visibility="section.visibility" />
            </div>
            <p
              v-if="section.body_preview"
              class="mt-2 whitespace-pre-wrap text-sm text-[var(--yife-text-muted)]"
            >
              {{ section.body_preview }}
            </p>
            <p v-else class="mt-2 text-xs text-[var(--yife-text-muted)]">No section content yet.</p>
          </section>
        </div>
      </YPanelSurface>
    </div>

    <YPanelSurface heading="Context" muted>
      <div class="space-y-3 text-sm text-[var(--yife-text-muted)]">
        <div class="flex items-center gap-2">
          <Link2 class="size-4" aria-hidden="true" />
          Dense typed metadata now sits above longer section content.
        </div>

        <div v-if="activePalette" class="rounded-[4px] border border-[var(--yife-border)] p-2">
          <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">Palette</p>
          <span
            class="mt-2 inline-flex items-center rounded-[4px] px-2 py-1 text-xs font-medium"
            :style="getPaletteTokenStyle(activePalette.color_token)"
          >
            {{ activePalette.label }}
          </span>
        </div>

        <div v-if="activeSymbol" class="rounded-[4px] border border-[var(--yife-border)] p-2">
          <p class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">Symbol</p>
          <p class="mt-2 text-sm font-medium">{{ activeSymbol.label }}</p>
          <p class="text-xs">{{ activeSymbol.icon_key }}</p>
        </div>

        <YStatusBadge :label="`Updated ${formatDateTime(detail.updated_at)}`" tone="info" />
      </div>
    </YPanelSurface>
  </div>
</template>
