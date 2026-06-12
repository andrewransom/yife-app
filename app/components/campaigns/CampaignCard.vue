<script setup lang="ts">
import { computed } from 'vue';
import { CalendarDays, Image } from 'lucide-vue-next';
import type { MyCampaign } from '~/composables/campaigns/types';

const props = defineProps<{
  campaign: MyCampaign;
}>();

const roleLabel = computed(() => {
  const firstRole = props.campaign.role_keys[0];

  return firstRole ? firstRole.replaceAll('_', ' ') : 'member';
});

const updatedLabel = computed(() => {
  if (!props.campaign.updated_at) {
    return 'No recent activity';
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
  }).format(new Date(props.campaign.updated_at));
});
</script>

<template>
  <NuxtLink
    :to="`/campaigns/${campaign.campaign_id}`"
    class="grid min-h-40 grid-cols-[5.5rem_1fr] gap-3 border border-[var(--yife-border)] bg-[var(--yife-surface)] p-3 hover:bg-[var(--yife-surface-muted)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[var(--yife-focus)]"
  >
    <div
      class="flex h-full min-h-32 items-center justify-center border border-dashed border-[var(--yife-border)] bg-[var(--yife-surface-muted)] text-[var(--yife-text-muted)]"
      aria-label="Campaign image placeholder"
    >
      <Image class="size-5" aria-hidden="true" />
    </div>

    <div class="min-w-0">
      <div class="flex items-start justify-between gap-2">
        <div class="min-w-0">
          <h2 class="truncate text-base font-semibold">{{ campaign.name }}</h2>
          <p class="mt-1 line-clamp-2 text-sm leading-5 text-[var(--yife-text-muted)]">
            {{ campaign.description || 'No campaign description yet.' }}
          </p>
        </div>
        <YStatusBadge :label="roleLabel" tone="info" class="capitalize" />
      </div>

      <dl class="mt-4 grid grid-cols-2 gap-2 text-xs text-[var(--yife-text-muted)]">
        <div>
          <dt class="font-medium text-[var(--yife-text)]">Status</dt>
          <dd>{{ campaign.status_label }}</dd>
        </div>
        <div>
          <dt class="font-medium text-[var(--yife-text)]">Activity</dt>
          <dd class="inline-flex items-center gap-1">
            <CalendarDays class="size-3" aria-hidden="true" />
            {{ updatedLabel }}
          </dd>
        </div>
        <div class="col-span-2">
          <dt class="font-medium text-[var(--yife-text)]">Next session</dt>
          <dd>Not scheduled</dd>
        </div>
      </dl>
    </div>
  </NuxtLink>
</template>
