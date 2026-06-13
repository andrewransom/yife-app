export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      campaign_currency_definitions: {
        Row: {
          campaign_id: string
          created_at: string
          created_by: string
          id: string
          is_active: boolean
          is_standard: boolean
          key: string
          label: string
          sort_order: number
          updated_at: string
          updated_by: string
          value_in_standard: number
        }
        Insert: {
          campaign_id: string
          created_at?: string
          created_by: string
          id?: string
          is_active?: boolean
          is_standard?: boolean
          key: string
          label: string
          sort_order: number
          updated_at?: string
          updated_by: string
          value_in_standard: number
        }
        Update: {
          campaign_id?: string
          created_at?: string
          created_by?: string
          id?: string
          is_active?: boolean
          is_standard?: boolean
          key?: string
          label?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string
          value_in_standard?: number
        }
        Relationships: [
          {
            foreignKeyName: "campaign_currency_definitions_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_entities: {
        Row: {
          archived_at: string | null
          campaign_id: string
          created_at: string
          created_by: string
          default_visibility: string
          deleted_at: string | null
          entity_type_id: string
          id: string
          list_caption: string
          parent_entity_id: string | null
          primary_image_asset_id: string | null
          related_session_entity_id: string | null
          relevant_date: string | null
          sort_key: string | null
          status_id: string | null
          updated_at: string
          updated_by: string
        }
        Insert: {
          archived_at?: string | null
          campaign_id: string
          created_at?: string
          created_by: string
          default_visibility: string
          deleted_at?: string | null
          entity_type_id: string
          id?: string
          list_caption: string
          parent_entity_id?: string | null
          primary_image_asset_id?: string | null
          related_session_entity_id?: string | null
          relevant_date?: string | null
          sort_key?: string | null
          status_id?: string | null
          updated_at?: string
          updated_by: string
        }
        Update: {
          archived_at?: string | null
          campaign_id?: string
          created_at?: string
          created_by?: string
          default_visibility?: string
          deleted_at?: string | null
          entity_type_id?: string
          id?: string
          list_caption?: string
          parent_entity_id?: string | null
          primary_image_asset_id?: string | null
          related_session_entity_id?: string | null
          relevant_date?: string | null
          sort_key?: string | null
          status_id?: string | null
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaign_entities_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_entities_entity_type_id_fkey"
            columns: ["entity_type_id"]
            isOneToOne: false
            referencedRelation: "entity_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_entities_parent_entity_id_fkey"
            columns: ["parent_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_entities_primary_image_fk"
            columns: ["primary_image_asset_id"]
            isOneToOne: false
            referencedRelation: "media_assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_entities_related_session_entity_id_fkey"
            columns: ["related_session_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_entities_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_entity_type_settings: {
        Row: {
          campaign_id: string
          created_at: string
          created_by: string
          default_visibility: string
          entity_type_id: string
          is_enabled: boolean
          updated_at: string
          updated_by: string
        }
        Insert: {
          campaign_id: string
          created_at?: string
          created_by: string
          default_visibility: string
          entity_type_id: string
          is_enabled?: boolean
          updated_at?: string
          updated_by: string
        }
        Update: {
          campaign_id?: string
          created_at?: string
          created_by?: string
          default_visibility?: string
          entity_type_id?: string
          is_enabled?: boolean
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaign_entity_type_settings_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_entity_type_settings_entity_type_id_fkey"
            columns: ["entity_type_id"]
            isOneToOne: false
            referencedRelation: "entity_types"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_invitation_roles: {
        Row: {
          created_at: string
          invitation_id: string
          role_id: string
        }
        Insert: {
          created_at?: string
          invitation_id: string
          role_id: string
        }
        Update: {
          created_at?: string
          invitation_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaign_invitation_roles_invitation_id_fkey"
            columns: ["invitation_id"]
            isOneToOne: false
            referencedRelation: "campaign_invitations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_invitation_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "role_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_invitations: {
        Row: {
          accepted_at: string | null
          accepted_by_user_id: string | null
          campaign_id: string
          created_at: string
          declined_at: string | null
          email_normalized: string
          expires_at: string | null
          id: string
          invited_by_user_id: string
          revoked_at: string | null
          status: string
          updated_at: string
        }
        Insert: {
          accepted_at?: string | null
          accepted_by_user_id?: string | null
          campaign_id: string
          created_at?: string
          declined_at?: string | null
          email_normalized: string
          expires_at?: string | null
          id?: string
          invited_by_user_id: string
          revoked_at?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          accepted_at?: string | null
          accepted_by_user_id?: string | null
          campaign_id?: string
          created_at?: string
          declined_at?: string | null
          email_normalized?: string
          expires_at?: string | null
          id?: string
          invited_by_user_id?: string
          revoked_at?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaign_invitations_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_membership_roles: {
        Row: {
          created_at: string
          membership_id: string
          role_id: string
        }
        Insert: {
          created_at?: string
          membership_id: string
          role_id: string
        }
        Update: {
          created_at?: string
          membership_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaign_membership_roles_membership_id_fkey"
            columns: ["membership_id"]
            isOneToOne: false
            referencedRelation: "campaign_memberships"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaign_membership_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "role_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      campaign_memberships: {
        Row: {
          campaign_id: string
          created_at: string
          display_name_override: string | null
          id: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          campaign_id: string
          created_at?: string
          display_name_override?: string | null
          id?: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          campaign_id?: string
          created_at?: string
          display_name_override?: string | null
          id?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaign_memberships_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      campaigns: {
        Row: {
          created_at: string
          created_by: string
          description: string | null
          end_date: string | null
          id: string
          image_asset_id: string | null
          name: string
          owner_user_id: string
          start_date: string
          status_id: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          description?: string | null
          end_date?: string | null
          id?: string
          image_asset_id?: string | null
          name: string
          owner_user_id: string
          start_date: string
          status_id: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          description?: string | null
          end_date?: string | null
          id?: string
          image_asset_id?: string | null
          name?: string
          owner_user_id?: string
          start_date?: string
          status_id?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "campaigns_image_asset_fk"
            columns: ["image_asset_id"]
            isOneToOne: false
            referencedRelation: "media_assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaigns_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      characters: {
        Row: {
          controlling_user_id: string
          created_at: string
          created_by: string
          entity_id: string
          image_asset_id: string | null
          name: string
          status_id: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          controlling_user_id: string
          created_at?: string
          created_by: string
          entity_id: string
          image_asset_id?: string | null
          name: string
          status_id: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          controlling_user_id?: string
          created_at?: string
          created_by?: string
          entity_id?: string
          image_asset_id?: string | null
          name?: string
          status_id?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "characters_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "characters_image_asset_id_fkey"
            columns: ["image_asset_id"]
            isOneToOne: false
            referencedRelation: "media_assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "characters_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      encounters: {
        Row: {
          created_at: string
          created_by: string
          encounter_type_option_id: string
          entity_id: string
          related_plot_arc_entity_id: string | null
          related_session_entity_id: string | null
          status_id: string
          title: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          encounter_type_option_id: string
          entity_id: string
          related_plot_arc_entity_id?: string | null
          related_session_entity_id?: string | null
          status_id: string
          title: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          encounter_type_option_id?: string
          entity_id?: string
          related_plot_arc_entity_id?: string | null
          related_session_entity_id?: string | null
          status_id?: string
          title?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "encounters_encounter_type_option_id_fkey"
            columns: ["encounter_type_option_id"]
            isOneToOne: false
            referencedRelation: "entity_option_definitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "encounters_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "encounters_related_plot_arc_entity_id_fkey"
            columns: ["related_plot_arc_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "encounters_related_session_entity_id_fkey"
            columns: ["related_session_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "encounters_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      entity_aliases: {
        Row: {
          alias_text: string
          alias_type: string
          created_at: string
          created_by: string
          deleted_at: string | null
          entity_id: string
          id: string
          is_preferred: boolean
          updated_at: string
          updated_by: string
          visibility: string
        }
        Insert: {
          alias_text: string
          alias_type?: string
          created_at?: string
          created_by: string
          deleted_at?: string | null
          entity_id: string
          id?: string
          is_preferred?: boolean
          updated_at?: string
          updated_by: string
          visibility: string
        }
        Update: {
          alias_text?: string
          alias_type?: string
          created_at?: string
          created_by?: string
          deleted_at?: string | null
          entity_id?: string
          id?: string
          is_preferred?: boolean
          updated_at?: string
          updated_by?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "entity_aliases_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
        ]
      }
      entity_option_definitions: {
        Row: {
          campaign_id: string | null
          created_at: string
          created_by: string | null
          entity_type_id: string | null
          group_key: string
          id: string
          is_active: boolean
          is_system: boolean
          key: string
          label: string
          sort_order: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          campaign_id?: string | null
          created_at?: string
          created_by?: string | null
          entity_type_id?: string | null
          group_key: string
          id?: string
          is_active?: boolean
          is_system?: boolean
          key: string
          label: string
          sort_order: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          campaign_id?: string | null
          created_at?: string
          created_by?: string | null
          entity_type_id?: string | null
          group_key?: string
          id?: string
          is_active?: boolean
          is_system?: boolean
          key?: string
          label?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "entity_option_definitions_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "entity_option_definitions_entity_type_id_fkey"
            columns: ["entity_type_id"]
            isOneToOne: false
            referencedRelation: "entity_types"
            referencedColumns: ["id"]
          },
        ]
      }
      entity_section_definitions: {
        Row: {
          created_at: string
          default_content_mode: string
          default_edit_policy: string
          default_visibility: string
          entity_type_id: string
          id: string
          is_active: boolean
          is_system: boolean
          label: string
          section_key: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          default_content_mode: string
          default_edit_policy: string
          default_visibility: string
          entity_type_id: string
          id?: string
          is_active?: boolean
          is_system?: boolean
          label: string
          section_key: string
          sort_order: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          default_content_mode?: string
          default_edit_policy?: string
          default_visibility?: string
          entity_type_id?: string
          id?: string
          is_active?: boolean
          is_system?: boolean
          label?: string
          section_key?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "entity_section_definitions_entity_type_id_fkey"
            columns: ["entity_type_id"]
            isOneToOne: false
            referencedRelation: "entity_types"
            referencedColumns: ["id"]
          },
        ]
      }
      entity_sections: {
        Row: {
          body_json: Json
          body_preview: string | null
          body_text: string
          content_mode: string
          created_at: string
          created_by: string
          edit_policy: string
          entity_id: string
          id: string
          label: string
          section_definition_id: string
          section_key: string
          updated_at: string
          updated_by: string
          version_number: number
          visibility: string
        }
        Insert: {
          body_json?: Json
          body_preview?: string | null
          body_text?: string
          content_mode: string
          created_at?: string
          created_by: string
          edit_policy: string
          entity_id: string
          id?: string
          label: string
          section_definition_id: string
          section_key: string
          updated_at?: string
          updated_by: string
          version_number?: number
          visibility: string
        }
        Update: {
          body_json?: Json
          body_preview?: string | null
          body_text?: string
          content_mode?: string
          created_at?: string
          created_by?: string
          edit_policy?: string
          entity_id?: string
          id?: string
          label?: string
          section_definition_id?: string
          section_key?: string
          updated_at?: string
          updated_by?: string
          version_number?: number
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "entity_sections_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "entity_sections_section_definition_id_fkey"
            columns: ["section_definition_id"]
            isOneToOne: false
            referencedRelation: "entity_section_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      entity_types: {
        Row: {
          created_at: string
          default_visibility: string
          icon_key: string
          id: string
          is_active: boolean
          is_system: boolean
          key: string
          label: string
          plural_label: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          default_visibility: string
          icon_key: string
          id?: string
          is_active?: boolean
          is_system?: boolean
          key: string
          label: string
          plural_label: string
          sort_order: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          default_visibility?: string
          icon_key?: string
          id?: string
          is_active?: boolean
          is_system?: boolean
          key?: string
          label?: string
          plural_label?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      factions: {
        Row: {
          created_at: string
          created_by: string
          entity_id: string
          name: string
          parent_faction_entity_id: string | null
          status_id: string | null
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          entity_id: string
          name: string
          parent_faction_entity_id?: string | null
          status_id?: string | null
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          entity_id?: string
          name?: string
          parent_faction_entity_id?: string | null
          status_id?: string | null
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "factions_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "factions_parent_faction_entity_id_fkey"
            columns: ["parent_faction_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "factions_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      locations: {
        Row: {
          created_at: string
          created_by: string
          entity_id: string
          image_asset_id: string | null
          location_type_option_id: string
          name: string
          parent_location_entity_id: string | null
          status_id: string | null
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          entity_id: string
          image_asset_id?: string | null
          location_type_option_id: string
          name: string
          parent_location_entity_id?: string | null
          status_id?: string | null
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          entity_id?: string
          image_asset_id?: string | null
          location_type_option_id?: string
          name?: string
          parent_location_entity_id?: string | null
          status_id?: string | null
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "locations_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "locations_image_asset_id_fkey"
            columns: ["image_asset_id"]
            isOneToOne: false
            referencedRelation: "media_assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "locations_location_type_option_id_fkey"
            columns: ["location_type_option_id"]
            isOneToOne: false
            referencedRelation: "entity_option_definitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "locations_parent_location_entity_id_fkey"
            columns: ["parent_location_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "locations_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      media_asset_variants: {
        Row: {
          byte_size: number
          created_at: string
          format: string
          height: number
          id: string
          media_asset_id: string
          mime_type: string
          storage_bucket: string
          storage_path: string
          variant: string
          version_key: string
          width: number
        }
        Insert: {
          byte_size: number
          created_at?: string
          format: string
          height: number
          id?: string
          media_asset_id: string
          mime_type: string
          storage_bucket: string
          storage_path: string
          variant: string
          version_key: string
          width: number
        }
        Update: {
          byte_size?: number
          created_at?: string
          format?: string
          height?: number
          id?: string
          media_asset_id?: string
          mime_type?: string
          storage_bucket?: string
          storage_path?: string
          variant?: string
          version_key?: string
          width?: number
        }
        Relationships: [
          {
            foreignKeyName: "media_asset_variants_media_asset_id_fkey"
            columns: ["media_asset_id"]
            isOneToOne: false
            referencedRelation: "media_assets"
            referencedColumns: ["id"]
          },
        ]
      }
      media_assets: {
        Row: {
          alt_text: string | null
          asset_scope: string
          blurhash: string | null
          campaign_id: string | null
          created_at: string
          created_by: string
          crop_anchor: string
          current_version_key: string
          deleted_at: string | null
          dominant_color: string | null
          id: string
          is_decorative: boolean
          original_byte_size: number | null
          original_filename: string | null
          original_height: number | null
          original_mime_type: string | null
          original_width: number | null
          owner_user_id: string | null
          retain_original: boolean
          status: string
          storage_bucket: string
          title: string | null
          updated_at: string
          updated_by: string
        }
        Insert: {
          alt_text?: string | null
          asset_scope: string
          blurhash?: string | null
          campaign_id?: string | null
          created_at?: string
          created_by: string
          crop_anchor?: string
          current_version_key?: string
          deleted_at?: string | null
          dominant_color?: string | null
          id?: string
          is_decorative?: boolean
          original_byte_size?: number | null
          original_filename?: string | null
          original_height?: number | null
          original_mime_type?: string | null
          original_width?: number | null
          owner_user_id?: string | null
          retain_original?: boolean
          status?: string
          storage_bucket?: string
          title?: string | null
          updated_at?: string
          updated_by: string
        }
        Update: {
          alt_text?: string | null
          asset_scope?: string
          blurhash?: string | null
          campaign_id?: string | null
          created_at?: string
          created_by?: string
          crop_anchor?: string
          current_version_key?: string
          deleted_at?: string | null
          dominant_color?: string | null
          id?: string
          is_decorative?: boolean
          original_byte_size?: number | null
          original_filename?: string | null
          original_height?: number | null
          original_mime_type?: string | null
          original_width?: number | null
          owner_user_id?: string | null
          retain_original?: boolean
          status?: string
          storage_bucket?: string
          title?: string | null
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "media_assets_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      npcs: {
        Row: {
          apparent_status_id: string
          created_at: string
          created_by: string
          entity_id: string
          faction_entity_id: string | null
          image_asset_id: string | null
          name: string
          real_status_id: string
          stat_block_jsonb: Json | null
          updated_at: string
          updated_by: string
        }
        Insert: {
          apparent_status_id: string
          created_at?: string
          created_by: string
          entity_id: string
          faction_entity_id?: string | null
          image_asset_id?: string | null
          name: string
          real_status_id: string
          stat_block_jsonb?: Json | null
          updated_at?: string
          updated_by: string
        }
        Update: {
          apparent_status_id?: string
          created_at?: string
          created_by?: string
          entity_id?: string
          faction_entity_id?: string | null
          image_asset_id?: string | null
          name?: string
          real_status_id?: string
          stat_block_jsonb?: Json | null
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "npcs_apparent_status_id_fkey"
            columns: ["apparent_status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "npcs_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "npcs_faction_entity_id_fkey"
            columns: ["faction_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "npcs_image_asset_id_fkey"
            columns: ["image_asset_id"]
            isOneToOne: false
            referencedRelation: "media_assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "npcs_real_status_id_fkey"
            columns: ["real_status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      parties: {
        Row: {
          created_at: string
          created_by: string
          entity_id: string
          name: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          entity_id: string
          name: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          entity_id?: string
          name?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "parties_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
        ]
      }
      plot_arcs: {
        Row: {
          created_at: string
          created_by: string
          entity_id: string
          status_id: string
          title: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          entity_id: string
          status_id: string
          title: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          entity_id?: string
          status_id?: string
          title?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "plot_arcs_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plot_arcs_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      quests: {
        Row: {
          created_at: string
          created_by: string
          entity_id: string
          is_major: boolean
          parent_quest_entity_id: string | null
          priority_option_id: string | null
          status_id: string
          title: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          entity_id: string
          is_major?: boolean
          parent_quest_entity_id?: string | null
          priority_option_id?: string | null
          status_id: string
          title: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          entity_id?: string
          is_major?: boolean
          parent_quest_entity_id?: string | null
          priority_option_id?: string | null
          status_id?: string
          title?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "quests_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quests_parent_quest_entity_id_fkey"
            columns: ["parent_quest_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quests_priority_option_id_fkey"
            columns: ["priority_option_id"]
            isOneToOne: false
            referencedRelation: "entity_option_definitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quests_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      relationship_types: {
        Row: {
          campaign_id: string | null
          created_at: string
          created_by: string | null
          default_directionality: string
          id: string
          inverse_label: string | null
          is_active: boolean
          is_system: boolean
          key: string
          label: string
          sort_order: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          campaign_id?: string | null
          created_at?: string
          created_by?: string | null
          default_directionality?: string
          id?: string
          inverse_label?: string | null
          is_active?: boolean
          is_system?: boolean
          key: string
          label: string
          sort_order: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          campaign_id?: string | null
          created_at?: string
          created_by?: string | null
          default_directionality?: string
          id?: string
          inverse_label?: string | null
          is_active?: boolean
          is_system?: boolean
          key?: string
          label?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "relationship_types_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      role_definitions: {
        Row: {
          id: string
          is_active: boolean
          is_system: boolean
          key: string
          label: string
          sort_order: number
        }
        Insert: {
          id?: string
          is_active?: boolean
          is_system?: boolean
          key: string
          label: string
          sort_order: number
        }
        Update: {
          id?: string
          is_active?: boolean
          is_system?: boolean
          key?: string
          label?: string
          sort_order?: number
        }
        Relationships: []
      }
      sessions: {
        Row: {
          created_at: string
          created_by: string
          entity_id: string
          session_date: string
          status_id: string
          title: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          entity_id: string
          session_date: string
          status_id: string
          title: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          entity_id?: string
          session_date?: string
          status_id?: string
          title?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "sessions_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "status_definitions"
            referencedColumns: ["id"]
          },
        ]
      }
      status_definitions: {
        Row: {
          campaign_id: string | null
          color_token: string | null
          created_at: string
          created_by: string | null
          entity_type_id: string | null
          id: string
          is_active: boolean
          is_system: boolean
          is_terminal: boolean
          key: string
          label: string
          sort_order: number
          subject_key: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          campaign_id?: string | null
          color_token?: string | null
          created_at?: string
          created_by?: string | null
          entity_type_id?: string | null
          id?: string
          is_active?: boolean
          is_system?: boolean
          is_terminal?: boolean
          key: string
          label: string
          sort_order: number
          subject_key: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          campaign_id?: string | null
          color_token?: string | null
          created_at?: string
          created_by?: string | null
          entity_type_id?: string | null
          id?: string
          is_active?: boolean
          is_system?: boolean
          is_terminal?: boolean
          key?: string
          label?: string
          sort_order?: number
          subject_key?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "status_definitions_entity_type_id_fkey"
            columns: ["entity_type_id"]
            isOneToOne: false
            referencedRelation: "entity_types"
            referencedColumns: ["id"]
          },
        ]
      }
      timeline_events: {
        Row: {
          created_at: string
          created_by: string
          date_expression: string
          entity_id: string
          event_type_option_id: string
          related_session_entity_id: string | null
          sort_key: string | null
          title: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          created_at?: string
          created_by: string
          date_expression: string
          entity_id: string
          event_type_option_id: string
          related_session_entity_id?: string | null
          sort_key?: string | null
          title: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          created_at?: string
          created_by?: string
          date_expression?: string
          entity_id?: string
          event_type_option_id?: string
          related_session_entity_id?: string | null
          sort_key?: string | null
          title?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "timeline_events_entity_id_fkey"
            columns: ["entity_id"]
            isOneToOne: true
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "timeline_events_event_type_option_id_fkey"
            columns: ["event_type_option_id"]
            isOneToOne: false
            referencedRelation: "entity_option_definitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "timeline_events_related_session_entity_id_fkey"
            columns: ["related_session_entity_id"]
            isOneToOne: false
            referencedRelation: "campaign_entities"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profiles: {
        Row: {
          avatar_asset_id: string | null
          created_at: string
          display_name: string
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_asset_id?: string | null
          created_at?: string
          display_name?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_asset_id?: string | null
          created_at?: string
          display_name?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_avatar_asset_fk"
            columns: ["avatar_asset_id"]
            isOneToOne: false
            referencedRelation: "media_assets"
            referencedColumns: ["id"]
          },
        ]
      }
      user_settings: {
        Row: {
          accessibility_preferences_jsonb: Json | null
          created_at: string
          default_campaign_id: string | null
          default_landing_behavior: string
          theme_preference: string
          updated_at: string
          user_id: string
        }
        Insert: {
          accessibility_preferences_jsonb?: Json | null
          created_at?: string
          default_campaign_id?: string | null
          default_landing_behavior?: string
          theme_preference?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          accessibility_preferences_jsonb?: Json | null
          created_at?: string
          default_campaign_id?: string | null
          default_landing_behavior?: string
          theme_preference?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_settings_default_campaign_fk"
            columns: ["default_campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      campaign_entity_summaries: {
        Row: {
          archived_at: string | null
          campaign_id: string | null
          controlling_user_display_label: string | null
          default_visibility: string | null
          deleted_at: string | null
          encounter_type_label: string | null
          entity_id: string | null
          entity_type_key: string | null
          is_major: boolean | null
          list_caption: string | null
          location_type_label: string | null
          npc_apparent_status_label: string | null
          parent_entity_id: string | null
          parent_entity_label: string | null
          primary_image_alt_text: string | null
          primary_image_asset_id: string | null
          primary_image_grid_bucket: string | null
          primary_image_grid_height: number | null
          primary_image_grid_path: string | null
          primary_image_grid_width: number | null
          primary_image_is_decorative: boolean | null
          primary_image_thumb_bucket: string | null
          primary_image_thumb_height: number | null
          primary_image_thumb_path: string | null
          primary_image_thumb_width: number | null
          quest_priority_label: string | null
          related_plot_arc_entity_id: string | null
          related_plot_arc_label: string | null
          related_session_entity_id: string | null
          related_session_label: string | null
          relevant_date: string | null
          sort_key: string | null
          status_key: string | null
          status_label: string | null
          timeline_date_expression: string | null
          timeline_event_type_label: string | null
          updated_at: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      can_mutate_campaign_config: {
        Args: { campaign_id: string }
        Returns: boolean
      }
      can_view_campaign_entity: {
        Args: { p_entity_id: string }
        Returns: boolean
      }
      can_view_gm_content: { Args: { campaign_id: string }; Returns: boolean }
      create_campaign: {
        Args: {
          p_description?: string
          p_end_date?: string
          p_name: string
          p_start_date: string
          p_status_key?: string
        }
        Returns: {
          campaign_id: string
          description: string
          membership_id: string
          name: string
          role_keys: string[]
          status_key: string
          status_label: string
        }[]
      }
      create_campaign_entity: {
        Args: {
          p_campaign_id: string
          p_entity_type_key: string
          p_input?: Json
        }
        Returns: {
          campaign_id: string
          default_visibility: string
          entity_id: string
          entity_type_key: string
          list_caption: string
          status_key: string
          status_label: string
          updated_at: string
        }[]
      }
      current_user_email_normalized: { Args: never; Returns: string }
      current_user_id: { Args: never; Returns: string }
      ensure_user_defaults: {
        Args: never
        Returns: {
          default_landing_behavior: string
          display_name: string
          theme_preference: string
          user_id: string
        }[]
      }
      entity_ref_label: { Args: { p_entity_id: string }; Returns: string }
      get_campaign_entity_summaries: {
        Args: { p_campaign_id: string }
        Returns: {
          archived_at: string
          campaign_id: string
          controlling_user_display_label: string
          default_visibility: string
          deleted_at: string
          encounter_type_label: string
          entity_id: string
          entity_type_key: string
          is_major: boolean
          list_caption: string
          location_type_label: string
          npc_apparent_status_label: string
          parent_entity_id: string
          parent_entity_label: string
          primary_image_alt_text: string
          primary_image_asset_id: string
          primary_image_grid_bucket: string
          primary_image_grid_height: number
          primary_image_grid_path: string
          primary_image_grid_width: number
          primary_image_is_decorative: boolean
          primary_image_thumb_bucket: string
          primary_image_thumb_height: number
          primary_image_thumb_path: string
          primary_image_thumb_width: number
          quest_priority_label: string
          related_plot_arc_entity_id: string
          related_plot_arc_label: string
          related_session_entity_id: string
          related_session_label: string
          relevant_date: string
          sort_key: string
          status_key: string
          status_label: string
          timeline_date_expression: string
          timeline_event_type_label: string
          updated_at: string
        }[]
      }
      get_campaign_membership_summary: {
        Args: { p_campaign_id: string }
        Returns: {
          campaign_id: string
          membership_status: string
          role_keys: string[]
          user_id: string
        }[]
      }
      get_entity_detail: {
        Args: { p_entity_id: string }
        Returns: {
          archived_at: string
          campaign_id: string
          controlling_user_display_label: string
          controlling_user_id: string
          default_visibility: string
          encounter_type_label: string
          entity_id: string
          entity_type_key: string
          entity_type_label: string
          is_major: boolean
          list_caption: string
          location_type_label: string
          npc_apparent_status_label: string
          npc_real_status_label: string
          parent_entity_id: string
          parent_entity_label: string
          quest_priority_label: string
          related_plot_arc_entity_id: string
          related_plot_arc_label: string
          related_session_entity_id: string
          related_session_label: string
          relevant_date: string
          sections: Json
          sort_key: string
          status_key: string
          status_label: string
          timeline_date_expression: string
          timeline_event_type_label: string
          updated_at: string
        }[]
      }
      get_entity_option_definitions: {
        Args: {
          p_campaign_id: string
          p_entity_type_key: string
          p_group_key?: string
        }
        Returns: {
          entity_type_key: string
          group_key: string
          id: string
          key: string
          label: string
          sort_order: number
        }[]
      }
      get_entity_status_options: {
        Args: { p_campaign_id: string; p_entity_type_key: string }
        Returns: {
          id: string
          key: string
          label: string
          sort_order: number
        }[]
      }
      get_entity_type_options: {
        Args: { p_campaign_id: string }
        Returns: {
          can_create: boolean
          default_visibility: string
          entity_type_id: string
          entity_type_key: string
          icon_key: string
          is_enabled: boolean
          label: string
          plural_label: string
          sort_order: number
        }[]
      }
      get_my_campaigns: {
        Args: never
        Returns: {
          campaign_id: string
          description: string
          membership_status: string
          name: string
          primary_image_alt_text: string
          primary_image_asset_id: string
          primary_image_grid_bucket: string
          primary_image_grid_height: number
          primary_image_grid_path: string
          primary_image_grid_width: number
          primary_image_is_decorative: boolean
          primary_image_thumb_bucket: string
          primary_image_thumb_height: number
          primary_image_thumb_path: string
          primary_image_thumb_width: number
          role_keys: string[]
          status_key: string
          status_label: string
          updated_at: string
        }[]
      }
      get_safe_member_profiles: {
        Args: { p_campaign_id: string }
        Returns: {
          avatar_asset_id: string
          avatar_is_decorative: boolean
          avatar_thumb_bucket: string
          avatar_thumb_height: number
          avatar_thumb_path: string
          avatar_thumb_width: number
          campaign_id: string
          display_name: string
          display_name_override: string
          user_id: string
        }[]
      }
      has_campaign_role: {
        Args: { campaign_id: string; role_key: string }
        Returns: boolean
      }
      is_campaign_gm: { Args: { campaign_id: string }; Returns: boolean }
      is_campaign_member: { Args: { campaign_id: string }; Returns: boolean }
      is_campaign_owner: { Args: { campaign_id: string }; Returns: boolean }
      normalize_email: { Args: { email: string }; Returns: string }
      require_campaign_entity_ref: {
        Args: {
          p_campaign_id: string
          p_entity_id: string
          p_entity_type_key: string
          p_required?: boolean
        }
        Returns: string
      }
      require_entity_option: {
        Args: {
          p_campaign_id: string
          p_entity_type_id: string
          p_group_key: string
          p_option_id: string
          p_required?: boolean
        }
        Returns: string
      }
      require_entity_status: {
        Args: {
          p_campaign_id: string
          p_entity_type_id: string
          p_required?: boolean
          p_status_id: string
        }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const

