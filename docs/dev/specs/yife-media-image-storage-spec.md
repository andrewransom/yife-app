# Yife Media And Image Storage Spec

## Purpose

This spec defines MVP image storage, metadata, upload, serving, and UI behavior for Yife.app.

It converts the free-tier Supabase image storage idea into a Yife-specific implementation direction based on:

- `docs/dev/yife-requirements.md`
- `docs/dev/yife-tech-stack.md`
- `docs/dev/specs/yife-content-model-db-design-spec.md`
- `docs/decisions/yife-content-model-db-decisions.md`
- `docs/decisions/yife-technology-stack-decisions.md`

The goal is to support representative campaign, character, NPC, and location images with predictable free-tier Supabase costs, dense-list performance, and clear privacy expectations.

## Core Decision

Use Supabase Storage public bucket files plus Supabase Postgres metadata.

MVP image handling:

- Generate required image variants in the browser before upload.
- Store optimized variants in a public Supabase Storage bucket.
- Store image metadata, variant metadata, and associations in Postgres.
- Store bucket/path as source of truth.
- Derive public URLs in app code when rendering.
- Keep original image retention optional and off by default.
- Defer private media, signed URLs, server-side image processing, and generic attachments unless explicitly promoted.

Public Storage files are accessible to anyone with the URL. App metadata, image associations, and UI access remain protected by campaign membership, role, RLS, views, and RPCs, but the file itself is not private in MVP.

## Scope

MVP supports primary images for:

- campaigns
- characters
- NPCs
- locations

MVP may also support user profile avatars if the profile UI needs them, but campaign media is the priority. If avatar upload is not implemented with the first media milestone, keep `user_profiles.avatar_asset_id` nullable and defer avatar-specific UI.

Post-MVP unless promoted:

- generic image galleries
- arbitrary note, section, or rich text image attachments
- private media
- signed URL serving
- server-side thumbnail generation
- background repair workers
- moderation or virus scanning
- EXIF preservation
- advanced crop editing beyond anchor selection

## User-Facing Privacy Requirement

Any upload UI for MVP public images must warn users that image files are public by URL.

Minimum copy direction:

```text
Images are public by URL in the MVP. Do not upload private or sensitive images.
```

The warning should appear near upload controls for campaign, character, NPC, and location images. It should not be hidden in global documentation only.

## Image Variants

Generate only the variants that the UI renders.

Required MVP variants:

| Variant | Target | Purpose | Required |
|---|---:|---|---|
| `thumb_160` | 160 x 160 cropped square | dense lists, pickers, command palette, tiny previews | yes |
| `grid_480` | 480 x 480 cropped square | campaign cards, entity cards, image pickers, detail preview | yes |

Optional future variant:

| Variant | Target | Purpose | Required |
|---|---:|---|---|
| `original_1600` | max 1600px long edge | larger preview or future reprocessing | no |

Rules:

- Normal lists and pickers must not render original uploads.
- Required variants are WebP when browser support allows.
- Safari and mobile camera uploads must be tested for WebP, canvas resizing, HEIC input, and EXIF orientation behavior before relying on a flow.
- If WebP export fails in a supported browser, fall back to JPEG for the generated variants and store the actual format in variant metadata.
- Do not store many speculative variants during MVP.

## Crop Anchors

Cropped square variants must support a user-selected 3x3 crop anchor.

Allowed values:

```text
top-left     top-center     top-right
center-left  center         center-right
bottom-left  bottom-center  bottom-right
```

Rules:

- Default crop anchor is `center`.
- The selected anchor applies to all cropped generated variants for the asset version.
- Upload UI should let users preview the resulting crop before final save when feasible.
- The anchor is metadata. Replacing an image creates new generated files rather than mutating old cached paths.

## Storage Bucket

Use one public Supabase Storage bucket for MVP image files.

```text
Bucket: yife-images
Public: true
```

Rules:

- The app stores `storage_bucket` and `storage_path`, not public URLs.
- App code derives public URLs through the Supabase Storage client.
- Browser uploads use the Supabase anon key; Storage object policies restrict who may insert/update/delete paths.
- Public read access means file secrecy is not guaranteed.
- Do not expose a Supabase service role key in client code.

## Storage Paths

Use versioned paths to avoid overwriting cacheable public URLs.

Campaign-scoped media:

```text
campaigns/{campaign_id}/media/{asset_id}/{version_key}/thumb_160.{ext}
campaigns/{campaign_id}/media/{asset_id}/{version_key}/grid_480.{ext}
```

Optional user-profile media:

```text
users/{user_id}/media/{asset_id}/{version_key}/thumb_160.{ext}
users/{user_id}/media/{asset_id}/{version_key}/grid_480.{ext}
```

Rules:

- `asset_id` is a UUID from `media_assets.id`.
- `version_key` starts as `v1`.
- `ext` is derived from the generated file format, usually `webp` and occasionally `jpg` for fallback.
- Replacing an image creates a new version key, such as `v2`, or a content hash path.
- Required uploads use `upsert: false`.
- Storage uploads and path updates must happen through app-owned mutation composables and service modules, not directly from components.
- Cache control for generated variants should be long-lived because paths are immutable.

## Postgres Model

The content model spec defines `media_assets` and `media_asset_links` at a high level. This spec is the more specific source for MVP media implementation and supersedes older media sketches that store public URLs directly or collapse all thumbnails into one asset row.

### `media_assets`

Represents one logical image asset.

```text
media_assets
- id
- campaign_id nullable
- owner_user_id nullable
- asset_scope -- campaign | user_profile
- storage_bucket
- status -- uploading | ready | failed | deleted
- current_version_key
- title nullable
- alt_text nullable
- is_decorative
- crop_anchor
- dominant_color nullable
- blurhash nullable
- original_filename nullable
- original_mime_type nullable
- original_byte_size nullable
- original_width nullable
- original_height nullable
- retain_original
- created_by
- updated_by
- created_at
- updated_at
- deleted_at nullable
```

Rules:

- Campaign, character, NPC, and location images use `asset_scope = campaign` and a non-null `campaign_id`.
- User profile avatars, if implemented, use `asset_scope = user_profile`, `campaign_id = null`, and `owner_user_id = auth.uid()` for the avatar owner.
- `status = ready` only after all required variant files and variant rows exist.
- `status = failed` means upload or client processing did not finish cleanly.
- `status = deleted` plus `deleted_at` supports soft delete before Storage cleanup.
- `current_version_key` identifies the active variant set for this asset and starts as `v1`.
- `crop_anchor` uses the allowed 3x3 anchor values and defaults to `center`.
- `is_decorative` defaults to false. If false, primary-image upload UI should require useful `alt_text`.
- `retain_original` defaults to false.
- Original file metadata may be stored even when the original file is not retained.
- Do not store public URLs in `media_assets` for MVP.

Suggested indexes:

```text
media_assets_campaign_ready_idx on (campaign_id, status, created_at desc)
media_assets_created_by_idx on (created_by, created_at desc)
media_assets_deleted_idx on (deleted_at) where deleted_at is not null
```

### `media_asset_variants`

Represents one generated stored file for a logical asset.

```text
media_asset_variants
- id
- media_asset_id fk -> media_assets.id
- variant -- thumb_160 | grid_480 | original_1600
- storage_bucket
- storage_path
- width
- height
- format
- mime_type
- byte_size
- version_key
- created_at
```

Rules:

- Unique constraint: `(media_asset_id, variant, version_key)`.
- The active version for an asset is `media_assets.current_version_key`.
- Summary and detail read models must join variants with `media_asset_variants.version_key = media_assets.current_version_key`.
- MVP may keep only current version rows unless replacement history becomes useful.
- `thumb_160` and `grid_480` are required before the parent asset becomes `ready`.
- `original_1600` is allowed only when `retain_original = true` or a later feature explicitly needs it.
- Store actual dimensions and MIME type after generation, not assumed values.

Suggested indexes:

```text
media_asset_variants_asset_idx on (media_asset_id)
media_asset_variants_variant_idx on (variant)
```

### Primary Image References

Primary image columns are allowed for fast list, picker, and summary display.

```text
campaigns.image_asset_id nullable fk -> media_assets.id
characters.image_asset_id nullable fk -> media_assets.id
npcs.image_asset_id nullable fk -> media_assets.id
locations.image_asset_id nullable fk -> media_assets.id
user_profiles.avatar_asset_id nullable fk -> media_assets.id
```

Rules:

- Campaign, character, NPC, and location primary images must reference a campaign-scoped asset in the same campaign.
- User profile avatars, if implemented, reference a user-profile asset created by that user.
- MVP primary images are player-visible whenever the parent campaign/entity is visible to the player.
- GM-private or spoiler images for otherwise player-visible NPCs, locations, Storylines, sections, maps, or handouts require media links with visibility. Private media storage remains deferred.
- Until then, spoiler image content belongs outside player-visible primary image slots.
- Deleting or replacing a primary image must not break list rendering; missing or deleted images fall back to placeholder UI.
- Campaign entity summaries should include enough primary image metadata to render `thumb_160` without fetching full asset details.
- Same-campaign primary image rules must be enforced in assignment/finalize RPCs and backed by DB triggers or check functions for `campaigns`, `characters`, `npcs`, and `locations`.

### `media_asset_links`

Generic media links support player-visible and Game Master-only Session/entity handouts and reference images. They are separate from primary-image workflows.

```text
media_asset_links
- id
- media_asset_id fk -> media_assets.id
- entity_id nullable fk -> campaign_entities.id
- note_id nullable fk -> notes.id
- section_id nullable fk -> entity_sections.id
- link_role
- visibility
- sort_order
- created_by
- created_at
```

MVP rules:

- Link visibility must be enforced before media metadata reaches player-facing reads.
- Hidden media links must not leak through counts, placeholders, previews, filenames, labels, or related summaries.
- Generic note, section, and gallery attachments are deferred unless explicitly promoted.
- If links are implemented early, linked records must belong to the same campaign as the asset.
- Link visibility must not grant access to hidden entities, notes, or sections.

## Upload Workflow

Image mutations go through feature mutation composables and app-owned service modules.

Components must not call Supabase directly.

Recommended flow:

```text
User selects image
  -> browser decodes image
  -> upload UI lets user choose crop anchor
  -> browser generates thumb_160 and grid_480
  -> call create_media_asset_upload RPC to create media_assets row with status uploading
  -> upload generated variants to public Storage paths
  -> call finalize_media_asset_upload RPC to insert variant rows, set status ready, and assign the primary image
  -> invalidate relevant TanStack Query caches
```

Rules:

- Create/finalize metadata steps use RPCs because they touch multiple tables and permission-sensitive references.
- `create_media_asset_upload` validates target type, target id, campaign membership, write permission, crop anchor, and intended variant list before returning upload paths.
- `finalize_media_asset_upload` validates required variant metadata, Storage paths, same-campaign references, target write permission, and status transition before assigning the primary image.
- `finalize_media_asset_upload` should be idempotent for the same asset id, version key, target, and variant metadata so client retries do not create duplicate rows or clear the previous image.
- Required variant generation happens before marking an asset ready.
- Primary image assignment should be part of the same logical mutation as asset finalization when feasible.
- If a step fails, mark the asset `failed` when possible and show a retry/remove action.
- Storage uploads and Postgres writes are not atomic; the UI must tolerate partial failure.
- Retrying a failed upload should create a new version path or new asset unless cleanup confirms old paths are gone.

Status lifecycle:

```text
uploading -> ready
uploading -> failed
uploading -> deleted
ready -> deleted
failed -> deleted
```

Rules:

- Assets left in `uploading` for more than 24 hours are abandoned and should be marked `failed` by a manual script or future cleanup job.
- Abandoned or failed assets must not be exposed through player-facing summaries.
- MVP should include a simple cleanup script once Storage uploads are implemented, even if it is manually run.

## Replacement Workflow

Replacing an image creates new immutable file paths.

Recommended flow:

```text
User chooses replacement image
  -> create new asset or new version for existing asset
  -> generate and upload required variants
  -> finalize metadata as ready
  -> switch primary image reference to the new ready asset, or update current_version_key after the new version is ready
  -> soft-delete or detach the old asset when no longer referenced
```

Rules:

- Do not overwrite old public Storage paths.
- UI should continue rendering the previous ready image until the replacement is ready.
- Failed replacements must not clear the existing primary image.

## Deletion And Cleanup

MVP deletion is metadata-first.

Rules:

- Clearing a primary image removes the reference from the owning record.
- If an asset has no remaining references, it may be marked `deleted`.
- Storage object cleanup can be manual or scripted during MVP.
- Hard delete of Storage files is best-effort and must not be required for normal UI correctness.
- Public URLs may remain accessible until Storage objects are actually removed.

Optional later cleanup table:

```text
media_cleanup_jobs
- id
- media_asset_id fk -> media_assets.id
- status -- pending | complete | failed
- attempts
- error nullable
- created_at
- available_at
- completed_at nullable
```

Do not add this jobs table until cleanup automation exists.

## RLS And Access Control

Postgres metadata is protected by RLS. Raw media metadata can leak sensitive names through `title`, `alt_text`, `original_filename`, or hidden associations, so player-facing reads must prefer visibility-safe views/RPCs and campaign/entity summaries.

Rules:

- Do not grant broad direct `select` on campaign-scoped `media_assets` or `media_asset_variants` to all campaign members.
- Campaign owners and Game Masters can read and manage campaign media metadata.
- Asset creators can read their own upload/failure state when they still have access to the campaign.
- Player-facing media metadata is exposed through safe campaign/entity summary views or RPCs that first prove the target campaign, entity, note, or section is visible to the caller.
- Insert/update/delete of campaign media requires the user to have the relevant campaign permission.
- Game Masters and campaign owners can manage campaign, NPC, and location primary images.
- Character image permissions follow the character edit rules for the campaign.
- Players must not infer hidden entity, note, or section details from media metadata or links.
- Player-facing reads must not include media linked only to hidden or GM-only records.
- User-profile avatar rows, if implemented, are readable by authenticated users as needed for membership/profile display and writable only by the owning user.

Storage object policies protect writes, not public reads.

Storage rules:

- Authenticated users may upload only to paths they are allowed to create.
- Campaign media upload paths must include a campaign id that the uploader can write to.
- Users may not update or delete Storage objects outside allowed paths.
- Public bucket reads are allowed by design.

Storage object policy shape:

- `bucket_id` must be `yife-images`.
- Object name must match an allowed path grammar:
  - `campaigns/{campaign_id}/media/{asset_id}/{version_key}/{variant}.{ext}`
  - `users/{user_id}/media/{asset_id}/{version_key}/{variant}.{ext}`
- `{variant}` must be one of `thumb_160`, `grid_480`, or allowed future variants.
- `{ext}` must be an allowed generated-image extension, initially `webp`, `jpg`, or `jpeg`.
- For campaign uploads, `media_assets.id = {asset_id}` must exist with `status = uploading`, matching `campaign_id`, matching `current_version_key`, and `created_by = auth.uid()`.
- For user-profile uploads, `media_assets.id = {asset_id}` must exist with `asset_scope = user_profile`, `owner_user_id = auth.uid()`, `status = uploading`, and matching `current_version_key`.
- Storage update/delete policies should be at least as strict as insert policies. Prefer immutable uploads with `upsert: false` and delete through cleanup tooling.
- The finalize RPC validates that each submitted variant path extension, MIME type, format, and byte size are internally consistent before storing variant metadata.

## UI Requirements

Upload UI:

- Uses compact controls consistent with the authenticated app.
- Shows the public-by-URL warning near the upload input.
- Shows image preview before save.
- Supports crop anchor selection using a 3x3 control.
- Shows progress, processing, success, failure, retry, and remove states.
- Requires alt text where the image is user-facing unless the UI explicitly marks it decorative with `is_decorative = true`.

Display UI:

- Dense lists use `thumb_160`.
- Campaign cards and image grids use `grid_480` with `thumb_160` in `srcset` where useful.
- Use fixed image dimensions or aspect-ratio constraints to prevent layout shift.
- Use `loading="lazy"` and `decoding="async"` outside immediate above-the-fold content.
- Missing, failed, deleted, or inaccessible images use stable placeholder UI.
- Inaccessible media must not leak hidden entity names or details through alt text, titles, filenames, or placeholders.
- Alt text for GM-only images should be treated as GM-only content and should not be reused on player-facing placeholders.

## Data Access And Caching

Rules:

- Components do not call Supabase directly.
- Reads go through feature query composables.
- Mutations go through feature mutation composables.
- TanStack Query owns media metadata and primary-image server state.
- Pinia may store only local UI state such as an open crop dialog or selected crop anchor before save.
- Query keys must include campaign id and target record id where applicable.
- Mutations invalidate campaign summaries, target entity details, and any relevant image/media query caches.

## Campaign Summaries

`campaign_entity_summaries` or equivalent read models should expose enough image data for dense UI without requiring extra per-row media queries.

Suggested summary image fields:

```text
primary_image_asset_id
primary_image_alt_text
primary_image_thumb_bucket
primary_image_thumb_path
primary_image_thumb_width
primary_image_thumb_height
primary_image_grid_bucket
primary_image_grid_path
primary_image_grid_width
primary_image_grid_height
primary_image_is_decorative
```

Rules:

- Summary views must respect entity visibility.
- Player summaries must not include images from inaccessible records.
- Player-safe summaries may include `primary_image_alt_text` only for visible primary images.
- Player-safe summaries must never expose `original_filename`, hidden media titles, failed upload rows, abandoned upload rows, or unassigned media assets.
- Public URLs are still derived in app code from bucket/path.

## Validation

Client validation:

- accepted input MIME types
- maximum input file size
- required alt text when applicable
- crop anchor is one of the allowed values
- generated variants exist before finalize

Database/RPC validation:

- campaign membership and write permission
- same-campaign asset/reference constraints
- allowed target record type
- required variant rows before `ready`
- status transitions
- non-null `campaign_id` for campaign-scoped assets
- non-null `owner_user_id` for user-profile assets
- `alt_text` required for non-decorative primary images

Suggested MVP limits:

```text
Max source image size: 10 MB
Max decoded long edge: 6000 px
Generated thumb_160 target quality: 0.75
Generated grid_480 target quality: 0.82
```

These limits may be adjusted after testing real mobile camera images.

## Testing Requirements

Schema/RLS tests once schema work starts:

- campaign owner and Game Master can directly read campaign media metadata
- player can read visible primary image metadata only through player-safe summary/RPC reads
- player cannot directly read raw campaign media metadata that is not theirs
- non-member cannot read campaign media metadata
- player cannot read media metadata linked only to GM-only inaccessible records
- authorized user can create an uploading asset row
- unauthorized user cannot create asset rows for another campaign
- asset cannot become ready without required variant rows
- primary image reference cannot point to a different campaign asset
- same-campaign primary image triggers/check functions reject invalid assignments for campaigns, characters, NPCs, and locations
- abandoned `uploading` assets are not returned by player-safe media reads

Frontend/unit tests:

- crop anchor calculation
- WebP/JPEG fallback handling
- failed upload state does not clear previous image
- public URL derivation uses bucket/path
- query invalidation after successful primary image mutation

Browser/manual tests:

- desktop Chrome image upload
- desktop Firefox image upload
- desktop Safari image upload
- mobile Safari camera image upload
- mobile Chrome camera image upload
- HEIC or unsupported file behavior
- EXIF orientation behavior
- dense list layout with missing and failed images

## Deferred Upgrade Path

The MVP model should allow these upgrades without replacing the core tables:

- private bucket plus signed URL serving
- server-side thumbnail generation
- cleanup and repair jobs
- retained originals and reprocessing
- richer galleries and attachments
- moderation/scanning
- CDN or external image provider if Supabase limits become constraining

Do not add these systems until a concrete need appears.
