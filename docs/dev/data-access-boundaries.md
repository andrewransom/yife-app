# Data Access Boundaries

Components must not call Supabase directly.

Server content reads go through feature query composables under `app/composables/queries/`.
Server content mutations go through feature mutation composables under `app/composables/mutations/`.

Pinia stores shared app/UI state only. TanStack Query owns server content and server mutation cache state.
