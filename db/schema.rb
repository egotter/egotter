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

ActiveRecord::Schema.define(version: 20160211064229) do

  create_table "background_search_logs", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,     default: -1,    null: false
    t.string   "uid",        limit: 191,   default: "-1",  null: false
    t.string   "bot_uid",    limit: 191,   default: "-1",  null: false
    t.boolean  "status",                   default: false, null: false
    t.string   "reason",     limit: 191,   default: "",    null: false
    t.text     "message",    limit: 65535,                 null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "background_search_logs", ["created_at"], name: "index_background_search_logs_on_created_at", using: :btree
  add_index "background_search_logs", ["uid"], name: "index_background_search_logs_on_uid", using: :btree
  add_index "background_search_logs", ["user_id", "status"], name: "index_background_search_logs_on_user_id_and_status", using: :btree
  add_index "background_search_logs", ["user_id"], name: "index_background_search_logs_on_user_id", using: :btree

  create_table "background_update_logs", force: :cascade do |t|
    t.string   "uid",        limit: 191,   default: "-1",  null: false
    t.string   "bot_uid",    limit: 191,   default: "-1",  null: false
    t.boolean  "status",                   default: false, null: false
    t.string   "reason",     limit: 191,   default: "",    null: false
    t.text     "message",    limit: 65535,                 null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "background_update_logs", ["created_at"], name: "index_background_update_logs_on_created_at", using: :btree
  add_index "background_update_logs", ["uid"], name: "index_background_update_logs_on_uid", using: :btree

  create_table "favorites", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "favorites", ["created_at"], name: "index_favorites_on_created_at", using: :btree
  add_index "favorites", ["from_id"], name: "index_favorites_on_from_id", using: :btree
  add_index "favorites", ["screen_name"], name: "index_favorites_on_screen_name", using: :btree
  add_index "favorites", ["uid"], name: "index_favorites_on_uid", using: :btree

  create_table "followers", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "followers", ["created_at"], name: "index_followers_on_created_at", using: :btree
  add_index "followers", ["from_id"], name: "index_followers_on_from_id", using: :btree
  add_index "followers", ["screen_name"], name: "index_followers_on_screen_name", using: :btree
  add_index "followers", ["uid"], name: "index_followers_on_uid", using: :btree

  create_table "friends", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "friends", ["created_at"], name: "index_friends_on_created_at", using: :btree
  add_index "friends", ["from_id"], name: "index_friends_on_from_id", using: :btree
  add_index "friends", ["screen_name"], name: "index_friends_on_screen_name", using: :btree
  add_index "friends", ["uid"], name: "index_friends_on_uid", using: :btree

  create_table "mentions", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "mentions", ["created_at"], name: "index_mentions_on_created_at", using: :btree
  add_index "mentions", ["from_id"], name: "index_mentions_on_from_id", using: :btree
  add_index "mentions", ["screen_name"], name: "index_mentions_on_screen_name", using: :btree
  add_index "mentions", ["uid"], name: "index_mentions_on_uid", using: :btree

  create_table "search_logs", force: :cascade do |t|
    t.boolean  "login",                     default: false, null: false
    t.integer  "login_user_id", limit: 4,   default: -1,    null: false
    t.string   "search_uid",    limit: 191, default: "",    null: false
    t.string   "search_sn",     limit: 191, default: "",    null: false
    t.string   "search_value",  limit: 191, default: "",    null: false
    t.string   "search_menu",   limit: 191, default: "",    null: false
    t.boolean  "same_user",                 default: false, null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "search_logs", ["login_user_id"], name: "index_search_logs_on_login_user_id", using: :btree
  add_index "search_logs", ["search_menu"], name: "index_search_logs_on_search_menu", using: :btree
  add_index "search_logs", ["search_uid", "search_menu"], name: "index_search_logs_on_search_uid_and_search_menu", using: :btree
  add_index "search_logs", ["search_value"], name: "index_search_logs_on_search_value", using: :btree

  create_table "search_results", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.string   "query",       limit: 191,   null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "search_results", ["created_at"], name: "index_search_results_on_created_at", using: :btree
  add_index "search_results", ["from_id"], name: "index_search_results_on_from_id", using: :btree
  add_index "search_results", ["screen_name"], name: "index_search_results_on_screen_name", using: :btree
  add_index "search_results", ["uid"], name: "index_search_results_on_uid", using: :btree

  create_table "statuses", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "statuses", ["created_at"], name: "index_statuses_on_created_at", using: :btree
  add_index "statuses", ["from_id"], name: "index_statuses_on_from_id", using: :btree
  add_index "statuses", ["screen_name"], name: "index_statuses_on_screen_name", using: :btree
  add_index "statuses", ["uid"], name: "index_statuses_on_uid", using: :btree

  create_table "twitter_users", force: :cascade do |t|
    t.string   "uid",          limit: 191,               null: false
    t.string   "screen_name",  limit: 191,               null: false
    t.text     "user_info",    limit: 65535,             null: false
    t.integer  "search_count", limit: 4,     default: 0, null: false
    t.integer  "update_count", limit: 4,     default: 0, null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "twitter_users", ["created_at"], name: "index_twitter_users_on_created_at", using: :btree
  add_index "twitter_users", ["screen_name"], name: "index_twitter_users_on_screen_name", using: :btree
  add_index "twitter_users", ["uid"], name: "index_twitter_users_on_uid", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "uid",                    limit: 191,                null: false
    t.string   "screen_name",            limit: 191,                null: false
    t.string   "secret",                 limit: 191,                null: false
    t.string   "token",                  limit: 191,                null: false
    t.boolean  "notification",                       default: true, null: false
    t.string   "email",                  limit: 191,                null: false
    t.string   "encrypted_password",     limit: 191,                null: false
    t.string   "reset_password_token",   limit: 191
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 191
    t.string   "last_sign_in_ip",        limit: 191
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "users", ["created_at"], name: "index_users_on_created_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["screen_name"], name: "index_users_on_screen_name", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

end
