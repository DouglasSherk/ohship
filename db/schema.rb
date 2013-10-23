# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131023201259) do

  create_table "packages", force: true do |t|
    t.integer  "shippee_id"
    t.integer  "shipper_id"
    t.integer  "state",                    default: 0
    t.float    "length_cm"
    t.float    "width_cm"
    t.float    "height_cm"
    t.float    "weight_kg"
    t.integer  "value_cents"
    t.string   "description"
    t.string   "ship_to_name"
    t.string   "ship_to_address"
    t.string   "ship_to_city"
    t.string   "ship_to_country"
    t.integer  "transaction_id"
    t.string   "shippee_tracking"
    t.string   "shippee_tracking_carrier"
    t.string   "shipper_tracking"
    t.string   "shipper_tracking_carrier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ship_to_postal_code"
    t.string   "special_instructions"
  end

  create_table "photos", force: true do |t|
    t.integer  "package_id"
    t.string   "type"
    t.string   "file_type"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
