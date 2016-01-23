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

ActiveRecord::Schema.define(version: 20160123153606) do

  create_table "background_search_logs", force: :cascade do |t|
    t.boolean  "login",                     default: false
    t.integer  "login_user_id", limit: 4,   default: -1
    t.string   "uid",           limit: 255, default: "-1"
    t.string   "bot_uid",       limit: 255, default: "-1"
    t.boolean  "status",                    default: false
    t.string   "reason",        limit: 255, default: ""
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "background_search_logs", ["login_user_id"], name: "index_background_search_logs_on_login_user_id", using: :btree
  add_index "background_search_logs", ["uid"], name: "index_background_search_logs_on_uid", using: :btree

  create_table "background_update_logs", force: :cascade do |t|
    t.string   "uid",        limit: 255, default: "-1"
    t.string   "bot_uid",    limit: 255, default: "-1"
    t.boolean  "status",                 default: false
    t.string   "reason",     limit: 255, default: ""
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "background_update_logs", ["uid"], name: "index_background_update_logs_on_uid", using: :btree

  create_table "followers", force: :cascade do |t|
    t.string   "uid",         limit: 255,   null: false
    t.string   "screen_name", limit: 255,   null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "followers", ["from_id"], name: "index_followers_on_from_id", using: :btree
  add_index "followers", ["screen_name"], name: "index_followers_on_screen_name", using: :btree
  add_index "followers", ["uid"], name: "index_followers_on_uid", using: :btree

  create_table "friends", force: :cascade do |t|
    t.string   "uid",         limit: 255,   null: false
    t.string   "screen_name", limit: 255,   null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "friends", ["from_id"], name: "index_friends_on_from_id", using: :btree
  add_index "friends", ["screen_name"], name: "index_friends_on_screen_name", using: :btree
  add_index "friends", ["uid"], name: "index_friends_on_uid", using: :btree

  create_table "search_logs", force: :cascade do |t|
    t.boolean  "login",                     default: false
    t.integer  "login_user_id", limit: 4,   default: -1
    t.string   "search_uid",    limit: 255, default: ""
    t.string   "search_sn",     limit: 255, default: ""
    t.string   "search_value",  limit: 255, default: ""
    t.string   "search_menu",   limit: 255, default: ""
    t.boolean  "same_user",                 default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "search_logs", ["login_user_id"], name: "index_search_logs_on_login_user_id", using: :btree
  add_index "search_logs", ["search_menu"], name: "index_search_logs_on_search_menu", using: :btree
  add_index "search_logs", ["search_uid", "search_menu"], name: "index_search_logs_on_search_uid_and_search_menu", using: :btree
  add_index "search_logs", ["search_value"], name: "index_search_logs_on_search_value", using: :btree

  create_table "twitter_users", force: :cascade do |t|
    t.string   "uid",         limit: 255,   null: false
    t.string   "screen_name", limit: 255,   null: false
    t.text     "user_info",   limit: 65535, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "twitter_users", ["screen_name"], name: "index_twitter_users_on_screen_name", using: :btree
  add_index "twitter_users", ["uid"], name: "index_twitter_users_on_uid", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "provider",               limit: 255,                null: false
    t.string   "uid",                    limit: 255,                null: false
    t.string   "secret",                 limit: 255,                null: false
    t.string   "token",                  limit: 255,                null: false
    t.boolean  "notification",                       default: true, null: false
    t.string   "email",                  limit: 255,                null: false
    t.string   "encrypted_password",     limit: 255,                null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
