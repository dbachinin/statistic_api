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

ActiveRecord::Schema.define(version: 2021_10_09_213805) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "plpgsql"

  create_table "customer_statuses", force: :cascade do |t|
    t.integer "status", null: false
    t.integer "duration"
    t.boolean "is_deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.integer "location_id"
    t.index ["customer_id"], name: "index_customer_statuses_on_customer_id"
    t.index ["location_id"], name: "index_customer_statuses_on_location_id"
    t.index ["status"], name: "index_customer_statuses_on_status"
  end

  create_table "customers", force: :cascade do |t|
    t.string "firstname", limit: 255, null: false
    t.string "lastname", limit: 255, null: false
    t.string "email", limit: 255, null: false
    t.boolean "is_deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone", limit: 255, null: false
    t.integer "location_id"
    t.string "alt_phone", limit: 255
    t.string "address_line_1", limit: 255
    t.string "address_line_2", limit: 255
    t.string "city", limit: 255
    t.string "state", limit: 255
    t.string "zip_code", limit: 255
    t.string "country", limit: 255
    t.string "sex", limit: 255
    t.date "date_of_birth"
    t.integer "updated_by_user_id"
    t.integer "status", null: false
    t.integer "priority"
    t.integer "user_id"
    t.datetime "waiver"
    t.integer "source"
    t.integer "idle_days"
    t.integer "phone_status", default: 0
    t.integer "des_subscription_status", default: 0
    t.integer "phone_subscription_status", default: 0
    t.datetime "idle_days_date"
  end

end
