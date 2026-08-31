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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_152423) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "churches", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "guard_guardians", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guard_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["guard_id", "user_id"], name: "index_guard_guardians_on_guard_id_and_user_id", unique: true
    t.index ["guard_id"], name: "index_guard_guardians_on_guard_id"
    t.index ["user_id"], name: "index_guard_guardians_on_user_id"
  end

  create_table "guard_setup_guardians", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guard_setup_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["guard_setup_id", "user_id"], name: "index_guard_setup_guardians_on_guard_setup_id_and_user_id", unique: true
    t.index ["guard_setup_id"], name: "index_guard_setup_guardians_on_guard_setup_id"
    t.index ["user_id"], name: "index_guard_setup_guardians_on_user_id"
  end

  create_table "guard_setups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_number", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.bigint "vocal_id", null: false
    t.index ["vocal_id"], name: "index_guard_setups_on_vocal_id"
  end

  create_table "guards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_number", null: false
    t.date "due_date", null: false
    t.bigint "guard_setup_id", null: false
    t.text "notes"
    t.bigint "priest_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "vocal_id", null: false
    t.index ["guard_setup_id"], name: "index_guards_on_guard_setup_id"
    t.index ["priest_id"], name: "index_guards_on_priest_id"
    t.index ["vocal_id"], name: "index_guards_on_vocal_id"
  end

  create_table "headquarters", force: :cascade do |t|
    t.string "address", null: false
    t.string "city", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "facebook"
    t.string "instagram"
    t.string "phone"
    t.string "slug", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.string "web_address"
    t.string "whatsapp"
    t.index ["slug"], name: "index_headquarters_on_slug", unique: true
  end

  create_table "health_facilities", force: :cascade do |t|
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "priest_setups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_month"
    t.integer "day_of_week"
    t.bigint "priest_id", null: false
    t.datetime "updated_at", null: false
    t.integer "week_number"
    t.index ["priest_id"], name: "index_priest_setups_on_priest_id"
    t.index ["week_number", "day_of_week"], name: "index_priest_setups_on_week_number_and_day_of_week", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.string "address"
    t.integer "age"
    t.string "caller_full_name"
    t.string "caller_phone"
    t.string "caller_relationship"
    t.text "comments"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.date "due_date", null: false
    t.string "full_name", null: false
    t.bigint "guard_id", null: false
    t.bigint "health_facility_id"
    t.string "health_facility_place"
    t.string "health_status"
    t.bigint "nro"
    t.string "pathology"
    t.string "sacraments"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_services_on_created_by_id"
    t.index ["guard_id"], name: "index_services_on_guard_id"
    t.index ["health_facility_id"], name: "index_services_on_health_facility_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "address"
    t.bigint "church_id"
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.date "date_of_birth"
    t.integer "dni"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.date "start_day"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.integer "user_type", default: 0, null: false
    t.index ["church_id"], name: "index_users_on_church_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "guard_guardians", "guards"
  add_foreign_key "guard_guardians", "users"
  add_foreign_key "guard_setup_guardians", "guard_setups"
  add_foreign_key "guard_setup_guardians", "users"
  add_foreign_key "guard_setups", "users", column: "vocal_id"
  add_foreign_key "guards", "guard_setups"
  add_foreign_key "guards", "users", column: "priest_id"
  add_foreign_key "guards", "users", column: "vocal_id"
  add_foreign_key "priest_setups", "users", column: "priest_id"
  add_foreign_key "services", "guards"
  add_foreign_key "services", "health_facilities"
  add_foreign_key "services", "users", column: "created_by_id"
  add_foreign_key "users", "churches"
end
