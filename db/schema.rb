# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_13_183728) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bbb_configs", force: :cascade do |t|
    t.bigint "tool_id"
    t.string "url"
    t.string "internal_url"
    t.string "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tool_id"], name: "index_bbb_configs_on_tool_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["revoked_at"], name: "index_oauth_access_tokens_on_revoked_at"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "rails_lti2_provider_lti_launches", force: :cascade do |t|
    t.bigint "tool_id"
    t.string "nonce"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.boolean "expired"
    t.index ["created_at"], name: "index_rails_lti2_provider_lti_launches_on_created_at"
    t.index ["nonce"], name: "index_launch_nonce", unique: true
    t.index ["nonce"], name: "index_rails_lti2_provider_lti_launches_on_nonce"
    t.index ["tool_id"], name: "index_rails_lti2_provider_lti_launches_on_tool_id"
    t.index ["user_id"], name: "index_rails_lti2_provider_lti_launches_on_user_id"
  end

  create_table "rails_lti2_provider_registrations", force: :cascade do |t|
    t.string "uuid"
    t.text "registration_request_params"
    t.text "tool_proxy_json"
    t.string "workflow_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tool_id"
    t.text "correlation_id"
    t.index ["correlation_id"], name: "index_rails_lti2_provider_registrations_on_correlation_id", unique: true
  end

  create_table "rails_lti2_provider_tenants", force: :cascade do |t|
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "settings", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "institution_guid"
    t.index ["institution_guid"], name: "index_rails_lti2_provider_tenants_on_institution_guid", unique: true
    t.index ["uid"], name: "index_tenant_uid", unique: true
  end

  create_table "rails_lti2_provider_tools", force: :cascade do |t|
    t.string "uuid"
    t.text "shared_secret"
    t.text "tool_settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "lti_version"
    t.integer "tenant_id"
    t.datetime "expired_at", precision: nil
    t.jsonb "app_settings", default: {}, null: false
    t.integer "status", default: 1, null: false
    t.index ["id", "tenant_id"], name: "index_tool_id_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_tenant_id"
    t.index ["uuid"], name: "index_uuid", unique: true
  end

  create_table "rooms_app_configs", force: :cascade do |t|
    t.bigint "tool_id"
    t.boolean "set_duration", default: false, null: false
    t.boolean "download_presentation_video", default: true, null: false
    t.boolean "message_reference_terms_use", default: true, null: false
    t.boolean "force_disable_external_link", default: false, null: false
    t.string "external_disclaimer"
    t.string "external_widget"
    t.string "external_context_url"
    t.boolean "moodle_integration_enabled", default: false, null: false
    t.string "moodle_url"
    t.string "moodle_token"
    t.boolean "moodle_group_select_enabled", default: false, null: false
    t.boolean "moodle_show_all_groups", default: true, null: false
    t.boolean "brightspace_integration_enabled", default: false, null: false
    t.string "brightspace_oauth_url"
    t.string "brightspace_oauth_client_id"
    t.string "brightspace_oauth_client_secret"
    t.string "brightspace_oauth_scopes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tool_id"], name: "index_rooms_app_configs_on_tool_id"
  end

  create_table "rsa_key_pairs", force: :cascade do |t|
    t.text "private_key"
    t.text "public_key"
    t.string "tool_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "context"
    t.string "uid"
    t.string "full_name"
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_accessed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["context", "uid"], name: "index_users_on_context_and_uid"
    t.index ["id"], name: "index_users_on_id"
  end

  create_table "worka_app_configs", force: :cascade do |t|
    t.bigint "tool_id"
    t.boolean "saas_enabled", default: false, null: false
    t.string "saas_world_url"
    t.string "saas_map_url"
    t.string "saas_map_storage_url"
    t.string "self_hosted_url"
    t.string "self_hosted_map_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tool_id"], name: "index_worka_app_configs_on_tool_id"
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
