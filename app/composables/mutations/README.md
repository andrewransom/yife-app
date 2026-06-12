# Mutation Composables

Server content mutations belong here and should use TanStack Query mutation helpers.

Components must not call Supabase directly. Multi-table, visibility-sensitive, or versioned writes should call Supabase RPCs through app-owned wrappers once database types exist.
