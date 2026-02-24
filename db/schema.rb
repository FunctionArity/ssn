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

ActiveRecord::Schema[8.1].define(version: 2026_02_23_204158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.bigint "priest_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vocal_id", null: false
    t.index ["priest_id"], name: "index_guard_setups_on_priest_id"
    t.index ["vocal_id"], name: "index_guard_setups_on_vocal_id"
  end

  create_table "guards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_number", null: false
    t.date "due_date", null: false
    t.bigint "guard_setup_id", null: false
    t.text "notes"
    t.bigint "priest_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vocal_id", null: false
    t.index ["guard_setup_id"], name: "index_guards_on_guard_setup_id"
    t.index ["priest_id"], name: "index_guards_on_priest_id"
    t.index ["vocal_id"], name: "index_guards_on_vocal_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "guard_guardians", "guards"
  add_foreign_key "guard_guardians", "users"
  add_foreign_key "guard_setup_guardians", "guard_setups"
  add_foreign_key "guard_setup_guardians", "users"
  add_foreign_key "guard_setups", "users", column: "priest_id"
  add_foreign_key "guard_setups", "users", column: "vocal_id"
  add_foreign_key "guards", "guard_setups"
  add_foreign_key "guards", "users", column: "priest_id"
  add_foreign_key "guards", "users", column: "vocal_id"
end
