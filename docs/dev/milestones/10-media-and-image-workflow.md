# 10. Media And Image Workflow

## Purpose

Add MVP image identity for campaigns and core visible entity types.

This milestone should implement Supabase Storage public bucket usage, Postgres media metadata, client-side variant generation, crop anchor selection, primary image assignment, image display in dense lists, and public-by-URL warnings without introducing private media or generic attachments.

## Source References

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/dev/specs/yife-media-image-storage-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`
- `docs/dev/milestones/02-supabase-core-schema-and-security-foundation.md`
- `docs/dev/milestones/04-entity-creation-and-directory-baseline.md`
- `docs/dev/milestones/06-role-aware-visibility-and-player-gm-views.md`

## Goals

- Configure public Supabase Storage bucket `yife-images`.
- Implement media metadata tables/RLS if not already complete.
- Implement Storage object write policies for allowed campaign media paths.
- Implement client-side image decoding, crop preview, and variant generation.
- Generate required `thumb_160` and `grid_480` variants.
- Implement `create_media_asset_upload` and `finalize_media_asset_upload` RPCs.
- Assign primary images for campaigns, characters, NPCs, and locations.
- Render primary images in campaign cards, entity directories, pickers, and detail shells.
- Show public-by-URL warning near every MVP upload control.
- Add cleanup/failure handling for abandoned or failed uploads.
- Add tests for media RLS, variants, public URL derivation, crop behavior, and partial failures.

## Non-Goals

- No private media.
- No signed URL serving.
- No server-side image processing.
- No retained originals by default.
- No generic note/section/gallery attachments.
- No media moderation or virus scanning.
- No background cleanup workers.
- No profile avatar upload unless explicitly promoted during implementation.
- No advanced crop editor beyond 3x3 anchor selection.

## Assumptions

- `media_assets` and `media_asset_variants` may already exist from M02; this milestone completes upload/finalize behavior and policies.
- Campaigns, characters, NPCs, and locations have nullable primary image columns.
- Public image files are acceptable for MVP if the UI warns users clearly.
- Components must use app-owned media composables/services rather than Supabase calls directly.
- Browser support includes modern Chrome, Edge, Firefox, Safari, mobile Safari, and mobile Chrome.

## Implementation Steps

### 1. Confirm Media Schema

Create or confirm `media_assets` with:

- `id`
- `campaign_id`
- `owner_user_id`
- `asset_scope`
- `storage_bucket`
- `status`
- `current_version_key`
- `title`
- `alt_text`
- `is_decorative`
- `crop_anchor`
- `dominant_color`
- `blurhash`
- original file metadata
- `retain_original`
- audit fields
- `deleted_at`

Create or confirm `media_asset_variants` with:

- `id`
- `media_asset_id`
- `variant`
- `storage_bucket`
- `storage_path`
- `width`
- `height`
- `format`
- `mime_type`
- `byte_size`
- `version_key`
- `created_at`

Rules:

- Store bucket/path, not public URLs.
- Ready campaign primary images require `thumb_160` and `grid_480`.
- Ready assets must have status `ready`.
- Failed/uploading/deleted assets must not appear in player-safe summaries.
- Same-campaign primary image rules are enforced by RPCs and backed by triggers or validation helpers where practical.

### 2. Configure Storage Bucket And Policies

Configure public bucket:

```text
yife-images
```

Storage path pattern:

```text
campaigns/{campaign_id}/media/{asset_id}/{version_key}/thumb_160.{ext}
campaigns/{campaign_id}/media/{asset_id}/{version_key}/grid_480.{ext}
```

Rules:

- Bucket is public.
- Create bucket configuration through migration/SQL where local Supabase supports it; otherwise document the exact manual local/remote setup step.
- Reads are public by design.
- Writes require authenticated users and strict path policy checks.
- Storage object policy must check `bucket_id = 'yife-images'`.
- Object names must match the campaign media path grammar and allowed variant names.
- Allowed extensions are `webp`, `jpg`, and `jpeg`.
- Uploads use `upsert: false`.
- Insert policy validates the object path against an existing `media_assets` row with status `uploading`, same campaign, same asset id, same version key, and `created_by = auth.uid()`.
- Update/delete policies are at least as strict as insert policies.
- Do not expose service-role keys to client code.

### 3. Implement Upload RPCs

Add `create_media_asset_upload`.

It must:

- require authenticated caller
- validate campaign membership and write permission
- validate target type and target id
- enforce target-specific write rules, including character image permissions
- validate crop anchor
- validate alt text/decorative state
- create `media_assets` row with status `uploading`
- set `current_version_key = v1`
- return allowed variant upload paths

Add `finalize_media_asset_upload`.

It must:

- require authenticated caller
- validate ownership/write permission
- validate asset is in `uploading` status
- validate required variants exist in submitted metadata
- validate paths match the reserved paths
- validate dimensions, MIME types, formats, and byte sizes
- insert variant rows idempotently
- mark asset `ready`
- assign primary image to target in the same logical mutation when feasible
- return updated primary image metadata for summaries/details

Failure handling:

- failed validation marks the asset `failed` when possible
- retry creates a new asset or version path
- failed replacements must not clear previous ready images

### 4. Implement Client Variant Generation

Add app-owned media processing utilities for:

- image file validation
- MIME/type fallback
- EXIF orientation handling where feasible
- canvas resizing/cropping
- WebP export
- JPEG fallback when WebP export fails
- 3x3 crop-anchor calculation
- byte-size/dimension metadata collection

Required variants:

- `thumb_160`: 160 x 160 cropped square
- `grid_480`: 480 x 480 cropped square

Suggested MVP limits:

- max source image size: 10 MB
- max decoded long edge: 6000 px
- `thumb_160` quality: 0.75
- `grid_480` quality: 0.82

Rules:

- Generate only variants the UI renders.
- Do not retain originals by default.
- If `retain_original` is implemented, it stays off by default and uses optional `original_1600`.
- Components call mutation composables/services, not raw Supabase Storage APIs.

### 5. Build Upload UI

Create reusable upload components:

- image file picker
- crop anchor selector
- crop preview
- alt text/decorative controls
- progress/failure/retry/remove states
- public-by-URL warning

Required warning text near upload controls:

```text
Images are public by URL in the MVP. Do not upload private or sensitive images.
```

Rules:

- Alt text is required for non-decorative user-facing primary images.
- `is_decorative` must be an explicit user choice.
- Crop anchor defaults to `center`.
- Upload UI shows preview before final save.
- Failed upload state does not clear previous image.
- Remove/clear primary image should detach the primary reference and optionally mark unreferenced asset deleted.

### 6. Add Primary Image Targets

Support primary images for:

- campaigns
- characters
- NPCs
- locations

Rules:

- Campaign, character, NPC, and location primary images reference campaign-scoped assets in the same campaign.
- Primary images are player-visible when the parent campaign/entity is player-visible.
- Do not use primary images for spoiler/GM-only art on otherwise player-visible records.
- Spoiler images are deferred until media links/visibility or private media is promoted.
- User profile avatar upload is deferred; `user_profiles.avatar_asset_id` may remain nullable.

### 7. Update Safe Summary Reads

Add primary image metadata to campaign and entity summaries:

- `primary_image_asset_id`
- `primary_image_alt_text`
- `primary_image_thumb_bucket`
- `primary_image_thumb_path`
- `primary_image_thumb_width`
- `primary_image_thumb_height`
- `primary_image_grid_bucket`
- `primary_image_grid_path`
- `primary_image_grid_width`
- `primary_image_grid_height`
- `primary_image_is_decorative`

Rules:

- Summary reads include only ready assets.
- Player-safe summaries include images only for visible records.
- Summaries never expose original filenames, hidden titles, failed uploads, abandoned uploads, unassigned assets, or public URLs.
- App code derives public URLs from bucket/path.

### 8. Build Image Display Components

Create reusable components:

- primary image display
- dense thumbnail
- campaign card image
- missing image placeholder
- failed/deleted image placeholder
- image action menu

Rules:

- Dense lists use `thumb_160`.
- Campaign cards/detail previews use `grid_480`.
- Use fixed dimensions or aspect-ratio constraints to prevent layout shift.
- Use `loading="lazy"` and `decoding="async"` outside immediate above-the-fold content.
- Alt text for inaccessible/hidden media must not leak hidden content.
- Missing/failed/deleted images render stable placeholders.

### 9. Add Cleanup Script

Add a manual cleanup script for:

- marking stale `uploading` assets older than 24 hours as `failed`
- listing failed/deleted assets and their paths
- optionally deleting unreferenced Storage files when explicitly run

Rules:

- Cleanup is metadata-first.
- Storage hard delete is best effort.
- Any script that deletes Storage objects must use local/server-only credentials and must never expose service-role credentials to client code.
- Normal UI correctness must not depend on Storage cleanup.
- Do not add a cleanup jobs table until automation exists.

### 10. Add Query And Mutation Composables

Expected query composables:

- `usePrimaryImageQuery` only if summaries/details are insufficient
- `useMediaAssetUploadStateQuery` for creator upload/failure state if needed

Expected mutation composables:

- `useUploadPrimaryImageMutation`
- `useReplacePrimaryImageMutation`
- `useClearPrimaryImageMutation`
- `useRetryImageUploadMutation`

Rules:

- Mutations invalidate campaign lists, entity summaries, target details, media state, and activity caches.
- Client processing utilities are called by mutation services/composables.
- Pinia may hold only transient crop dialog state.
- Components never call Supabase Storage directly.

### 11. Add Tests

Database/RLS/RPC tests:

- owner/GM can create uploading campaign media asset
- unauthorized user cannot create media for another campaign
- player cannot read raw campaign media metadata outside safe summaries
- asset cannot become ready without `thumb_160` and `grid_480`
- finalize rejects mismatched paths, campaign ids, version keys, MIME types, and dimensions
- primary image cannot point to a different campaign asset
- failed/uploading assets are omitted from player-safe summaries
- failed replacement does not clear previous ready image
- storage policies reject invalid bucket ids, variants, extensions, and paths

Unit/component tests:

- crop anchor calculation for all 9 anchors
- WebP/JPEG fallback handling
- public URL derivation uses bucket/path
- alt text validation
- public-by-URL warning renders near upload controls
- missing/failed image placeholders
- query invalidation after upload

Browser/manual tests:

- desktop Chrome upload
- desktop Firefox upload
- desktop Safari upload
- mobile Safari camera upload
- mobile Chrome camera upload
- HEIC or unsupported file behavior
- EXIF orientation behavior
- dense list layout with missing and failed images

### 12. Verify Locally

Run:

```sh
pnpm supabase:start
pnpm supabase:reset
pnpm db:test
pnpm db:types
pnpm typecheck
pnpm lint
pnpm format:check
pnpm test:unit
pnpm build
pnpm test:e2e
```

Document browser/manual upload coverage separately from automated tests.

## Manual Steps Required From Andrew

- Create or confirm the local/remote public Supabase Storage bucket.
- Verify the public-by-URL warning copy.
- Manually test Safari/mobile camera uploads before relying on the flow.
- Review whether profile avatar upload should remain deferred.

## Success Criteria

- Public bucket and Storage policies are configured.
- Users can upload primary images for campaigns, characters, NPCs, and locations.
- Required variants are generated client-side and stored with metadata.
- Public URLs are derived from bucket/path, not persisted.
- Primary image summaries render thumbnails without extra per-row media queries.
- Upload UI warns that images are public by URL.
- Alt text/decorative state is validated.
- Failed uploads and replacements do not break existing image display.
- Browser/manual image checks are documented.
- Tests cover RLS, RPCs, variant generation, crop anchors, and safe summary rendering.

## What Good Looks Like

- Campaign and entity lists gain visual identity without heavy images or layout shift.
- Upload failure is recoverable and never clears a previous working image.
- The privacy tradeoff is visible at the moment of upload.
- The media model remains ready for private media or server-side processing later.

## Resolved Decisions

- Use one public `yife-images` bucket.
- Generate `thumb_160` and `grid_480` in the browser.
- Store bucket/path as source of truth and derive public URLs in app code.
- Original retention is optional and off by default.
- Campaign, character, NPC, and location primary images are in scope.
- Profile avatar upload is deferred unless explicitly promoted.
- Generic note/section media attachments are deferred.

## Review Notes

Two q-review-plan passes were applied to this milestone draft.

Pass 1 corrections incorporated:

- Required bucket setup to be migration-backed where practical, with manual setup documented only where Supabase local tooling requires it.
- Tightened Storage policy grammar for bucket id, path, variant names, and extensions.
- Added target-specific write-permission validation, including character image permissions.

Pass 2 corrections incorporated:

- Fixed display attribute examples.
- Required cleanup scripts that delete Storage objects to use server/local-only credentials and never expose service-role secrets.
- Added tests for Storage policy rejection and upload warning rendering.
