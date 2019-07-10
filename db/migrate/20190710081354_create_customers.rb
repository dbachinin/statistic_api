class CreateCustomers < ActiveRecord::Migration[5.2]
  create_table :customers, force: :cascade do |t|
    t.string   "firstname",                 limit: 255,                 null: false
    t.string   "lastname",                  limit: 255,                 null: false
    t.string   "email",                     limit: 255,                 null: false
    t.boolean  "is_deleted",                            default: false
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.string   "phone",                     limit: 255,                 null: false
    t.integer  "location_id",               limit: 4
    t.string   "alt_phone",                 limit: 255
    t.string   "address_line_1",            limit: 255
    t.string   "address_line_2",            limit: 255
    t.string   "city",                      limit: 255
    t.string   "state",                     limit: 255
    t.string   "zip_code",                  limit: 255
    t.string   "country",                   limit: 255
    t.string   "sex",                       limit: 255
    t.date     "date_of_birth"
    t.integer  "updated_by_user_id",        limit: 4
    t.integer  "status",                    limit: 4,                   null: false
    t.integer  "priority",                  limit: 4
    t.integer  "user_id",                   limit: 4
    t.datetime "waiver"
    t.integer  "source",                    limit: 4
    t.integer  "idle_days",                 limit: 4
    t.integer  "phone_status",              limit: 4,   default: 0
    t.integer  "des_subscription_status",   limit: 4,   default: 0
    t.integer  "phone_subscription_status", limit: 4,   default: 0
  end

  def self.down
    drop_table :customers
  end
end
