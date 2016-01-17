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

ActiveRecord::Schema.define(version: 20160117142535) do

  create_table "background_search_logs", force: :cascade do |t|
    t.boolean  "login",         default: false
    t.integer  "login_user_id", default: -1
    t.text     "uid",           default: "-1"
    t.boolean  "status",        default: false
    t.text     "reason",        default: ""
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "background_search_logs", ["login_user_id"], name: "index_background_search_logs_on_login_user_id"
  add_index "background_search_logs", ["uid"], name: "index_background_search_logs_on_uid"

  create_table "followers", force: :cascade do |t|
    t.string   "uid",         null: false
    t.string   "screen_name", null: false
    t.text     "user_info",   null: false
    t.integer  "from_id",     null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "followers", ["screen_name"], name: "index_followers_on_screen_name"
  add_index "followers", ["uid"], name: "index_followers_on_uid"

  create_table "friends", force: :cascade do |t|
    t.string   "uid",         null: false
    t.string   "screen_name", null: false
    t.text     "user_info",   null: false
    t.integer  "from_id",     null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "friends", ["screen_name"], name: "index_friends_on_screen_name"
  add_index "friends", ["uid"], name: "index_friends_on_uid"

  create_table "search_logs", force: :cascade do |t|
    t.boolean  "login",         default: false
    t.integer  "login_user_id", default: -1
    t.string   "search_uid",    default: ""
    t.string   "search_sn",     default: ""
    t.string   "search_value",  default: ""
    t.string   "search_menu",   default: ""
    t.boolean  "same_user",     default: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "search_logs", ["login_user_id"], name: "index_search_logs_on_login_user_id"
  add_index "search_logs", ["search_menu"], name: "index_search_logs_on_search_menu"
  add_index "search_logs", ["search_value"], name: "index_search_logs_on_search_value"

  create_table "twitter_users", force: :cascade do |t|
    t.string   "uid",         null: false
    t.string   "screen_name", null: false
    t.text     "user_info",   null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "twitter_users", ["screen_name"], name: "index_twitter_users_on_screen_name"
  add_index "twitter_users", ["uid"], name: "index_twitter_users_on_uid"

  create_table "users", force: :cascade do |t|
    t.string   "provider",                           null: false
    t.string   "uid",                                null: false
    t.string   "secret",                             null: false
    t.string   "token",                              null: false
    t.string   "email",                              null: false
    t.string   "encrypted_password",                 null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
