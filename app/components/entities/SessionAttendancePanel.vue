<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { Save } from 'lucide-vue-next';
import { useCampaignMemberProfilesQuery } from '~/composables/campaigns/useCampaignMemberProfilesQuery';
import { useCampaignEntitySummariesQuery } from '~/composables/entities/useCampaignEntitySummariesQuery';
import { useSessionAttendanceQuery } from '~/composables/entities/useSessionAttendanceQuery';
import { useUpdateSessionAttendanceMutation } from '~/composables/entities/useSessionMutations';
import { useYifeToast } from '~/composables/auth/useYifeToast';

const props = withDefaults(
  defineProps<{
    campaignId: string;
    sessionEntityId: string;
    activeRoleView?: 'gm' | 'player';
    isPlayerPreview?: boolean;
  }>(),
  {
    activeRoleView: 'gm',
    isPlayerPreview: false,
  },
);

const toast = useYifeToast();
const attendanceQuery = useSessionAttendanceQuery(() => props.sessionEntityId, {
  enabled: computed(() => Boolean(props.sessionEntityId)),
  previewAsPlayer: computed(() => props.isPlayerPreview === true),
});
const membersQuery = useCampaignMemberProfilesQuery(() => props.campaignId, {
  enabled: computed(() => props.activeRoleView === 'gm' && !props.isPlayerPreview),
});
const summariesQuery = useCampaignEntitySummariesQuery(() => props.campaignId, {
  enabled: computed(() => props.activeRoleView === 'gm' && !props.isPlayerPreview),
});
const updateAttendance = useUpdateSessionAttendanceMutation();
const selectedUserIds = ref<string[]>([]);
const selectedCharacterIds = ref<string[]>([]);

const characterOptions = computed(() =>
  (summariesQuery.data.value ?? [])
    .filter((summary) => summary.entity_type_key === 'character')
    .map((summary) => ({
      entity_id: summary.entity_id,
      list_caption: summary.list_caption,
    })),
);
const attendance = computed(() => attendanceQuery.data.value);
const canManage = computed(
  () => props.activeRoleView === 'gm' && !props.isPlayerPreview && attendance.value?.can_manage,
);

watch(
  attendance,
  (value) => {
    selectedUserIds.value = value?.attending_users.map((user) => user.user_id) ?? [];
    selectedCharacterIds.value =
      value?.attending_characters.map((character) => character.character_entity_id) ?? [];
  },
  { immediate: true },
);

function toggle(list: string[], value: string, checked: boolean) {
  return checked ? Array.from(new Set([...list, value])) : list.filter((item) => item !== value);
}

async function save() {
  try {
    await updateAttendance.mutateAsync({
      sessionEntityId: props.sessionEntityId,
      userIds: selectedUserIds.value,
      characterEntityIds: selectedCharacterIds.value,
    });
    toast.success('Attendance saved');
  } catch (error) {
    toast.error(error instanceof Error ? error.message : 'Attendance update failed');
  }
}
</script>

<template>
  <YPanelSurface heading="Attendance">
    <template #actions>
      <YIconButton
        v-if="canManage"
        :icon="Save"
        label="Save attendance"
        :disabled="updateAttendance.isPending.value"
        @click="save"
      />
    </template>

    <YEmptyState
      v-if="attendanceQuery.isPending.value"
      heading="Loading attendance"
      text="Fetching visible attendance."
    />
    <div v-else class="grid gap-3 lg:grid-cols-2">
      <section class="space-y-2">
        <div class="flex items-center gap-2">
          <h3 class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">Members</h3>
          <YStatusBadge :label="String(attendance?.attending_users.length ?? 0)" tone="info" />
        </div>

        <div
          v-if="canManage && membersQuery.data.value?.length"
          class="space-y-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
        >
          <label
            v-for="member in membersQuery.data.value"
            :key="member.user_id"
            class="flex items-center gap-2 text-sm"
          >
            <input
              type="checkbox"
              :checked="selectedUserIds.includes(member.user_id)"
              @change="
                selectedUserIds = toggle(
                  selectedUserIds,
                  member.user_id,
                  ($event.target as HTMLInputElement).checked,
                )
              "
            />
            <span>{{ member.display_name_override || member.display_name || member.user_id }}</span>
          </label>
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="user in attendance?.attending_users ?? []"
            :key="user.user_id"
            class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-2 text-sm"
          >
            {{ user.display_label || user.user_id }}
          </div>
          <YEmptyState
            v-if="!attendance?.attending_users.length"
            heading="No members marked"
            text="Attending members appear here."
          />
        </div>
      </section>

      <section class="space-y-2">
        <div class="flex items-center gap-2">
          <h3 class="text-xs font-medium uppercase text-[var(--yife-text-muted)]">Characters</h3>
          <YStatusBadge :label="String(attendance?.attending_characters.length ?? 0)" tone="info" />
        </div>

        <div
          v-if="canManage && characterOptions.length"
          class="space-y-2 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-3"
        >
          <label
            v-for="character in characterOptions"
            :key="character.entity_id"
            class="flex items-center gap-2 text-sm"
          >
            <input
              type="checkbox"
              :checked="selectedCharacterIds.includes(character.entity_id)"
              @change="
                selectedCharacterIds = toggle(
                  selectedCharacterIds,
                  character.entity_id,
                  ($event.target as HTMLInputElement).checked,
                )
              "
            />
            <span>{{ character.list_caption }}</span>
          </label>
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="character in attendance?.attending_characters ?? []"
            :key="character.character_entity_id"
            class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface-muted)] p-2 text-sm"
          >
            {{ character.display_label || character.character_entity_id }}
          </div>
          <YEmptyState
            v-if="!attendance?.attending_characters.length"
            heading="No characters marked"
            text="Attending characters appear here."
          />
        </div>
      </section>
    </div>
  </YPanelSurface>
</template>
