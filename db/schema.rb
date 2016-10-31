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

ActiveRecord::Schema.define(version: 20161021113742) do

  create_table "background_search_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191,   default: "",    null: false
    t.integer  "user_id",     limit: 4,     default: -1,    null: false
    t.string   "uid",         limit: 191,   default: "-1",  null: false
    t.string   "screen_name", limit: 191,   default: "",    null: false
    t.string   "bot_uid",     limit: 191,   default: "-1",  null: false
    t.boolean  "auto",                      default: false, null: false
    t.boolean  "status",                    default: false, null: false
    t.string   "reason",      limit: 191,   default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.integer  "call_count",  limit: 4,     default: -1,    null: false
    t.string   "via",         limit: 191,   default: "",    null: false
    t.string   "device_type", limit: 191,   default: "",    null: false
    t.string   "os",          limit: 191,   default: "",    null: false
    t.string   "browser",     limit: 191,   default: "",    null: false
    t.string   "user_agent",  limit: 191,   default: "",    null: false
    t.string   "referer",     limit: 191,   default: "",    null: false
    t.string   "referral",    limit: 191,   default: "",    null: false
    t.string   "channel",     limit: 191,   default: "",    null: false
    t.datetime "created_at",                                null: false
  end

  add_index "background_search_logs", ["created_at"], name: "index_background_search_logs_on_created_at", using: :btree
  add_index "background_search_logs", ["screen_name"], name: "index_background_search_logs_on_screen_name", using: :btree
  add_index "background_search_logs", ["uid"], name: "index_background_search_logs_on_uid", using: :btree
  add_index "background_search_logs", ["user_id", "status"], name: "index_background_search_logs_on_user_id_and_status", using: :btree
  add_index "background_search_logs", ["user_id"], name: "index_background_search_logs_on_user_id", using: :btree

  create_table "background_update_logs", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,     default: -1,    null: false
    t.string   "uid",         limit: 191,   default: "-1",  null: false
    t.string   "screen_name", limit: 191,   default: "",    null: false
    t.string   "bot_uid",     limit: 191,   default: "-1",  null: false
    t.boolean  "status",                    default: false, null: false
    t.string   "reason",      limit: 191,   default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.integer  "call_count",  limit: 4,     default: -1,    null: false
    t.datetime "created_at",                                null: false
  end

  add_index "background_update_logs", ["created_at"], name: "index_background_update_logs_on_created_at", using: :btree
  add_index "background_update_logs", ["screen_name"], name: "index_background_update_logs_on_screen_name", using: :btree
  add_index "background_update_logs", ["uid"], name: "index_background_update_logs_on_uid", using: :btree

  create_table "blazer_audits", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.integer  "query_id",    limit: 4
    t.text     "statement",   limit: 65535
    t.string   "data_source", limit: 191
    t.datetime "created_at"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.integer  "creator_id",  limit: 4
    t.integer  "query_id",    limit: 4
    t.string   "state",       limit: 191
    t.string   "schedule",    limit: 191
    t.text     "emails",      limit: 65535
    t.string   "check_type",  limit: 191
    t.text     "message",     limit: 65535
    t.datetime "last_run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.integer  "dashboard_id", limit: 4
    t.integer  "query_id",     limit: 4
    t.integer  "position",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.integer  "creator_id", limit: 4
    t.text     "name",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.integer  "creator_id",  limit: 4
    t.string   "name",        limit: 191
    t.text     "description", limit: 65535
    t.text     "statement",   limit: 65535
    t.string   "data_source", limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "create_notification_message_logs", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,                     null: false
    t.string   "uid",         limit: 191,                   null: false
    t.string   "screen_name", limit: 191,                   null: false
    t.boolean  "status",                    default: false, null: false
    t.string   "reason",      limit: 191,   default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.string   "context",     limit: 191,   default: "",    null: false
    t.string   "medium",      limit: 191,   default: "",    null: false
    t.datetime "created_at",                                null: false
  end

  add_index "create_notification_message_logs", ["created_at"], name: "index_create_notification_message_logs_on_created_at", using: :btree
  add_index "create_notification_message_logs", ["screen_name"], name: "index_create_notification_message_logs_on_screen_name", using: :btree
  add_index "create_notification_message_logs", ["uid"], name: "index_create_notification_message_logs_on_uid", using: :btree
  add_index "create_notification_message_logs", ["user_id", "status"], name: "index_create_notification_message_logs_on_user_id_and_status", using: :btree
  add_index "create_notification_message_logs", ["user_id"], name: "index_create_notification_message_logs_on_user_id", using: :btree

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
  end

  add_index "followers", ["from_id"], name: "index_followers_on_from_id", using: :btree

  create_table "friends", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
  end

  add_index "friends", ["from_id"], name: "index_friends_on_from_id", using: :btree

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

  create_table "modal_open_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191, default: "", null: false
    t.integer  "user_id",     limit: 4,   default: -1, null: false
    t.string   "via",         limit: 191, default: "", null: false
    t.string   "device_type", limit: 191, default: "", null: false
    t.string   "os",          limit: 191, default: "", null: false
    t.string   "browser",     limit: 191, default: "", null: false
    t.string   "user_agent",  limit: 191, default: "", null: false
    t.string   "referer",     limit: 191, default: "", null: false
    t.string   "referral",    limit: 191, default: "", null: false
    t.string   "channel",     limit: 191, default: "", null: false
    t.datetime "created_at",                           null: false
  end

  add_index "modal_open_logs", ["created_at"], name: "index_modal_open_logs_on_created_at", using: :btree

  create_table "notification_messages", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,                     null: false
    t.string   "uid",         limit: 191,                   null: false
    t.string   "screen_name", limit: 191,                   null: false
    t.boolean  "read",                      default: false, null: false
    t.datetime "read_at"
    t.string   "message_id",  limit: 191,   default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.string   "context",     limit: 191,   default: "",    null: false
    t.string   "medium",      limit: 191,   default: "",    null: false
    t.string   "token",       limit: 191,   default: "",    null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "notification_messages", ["created_at"], name: "index_notification_messages_on_created_at", using: :btree
  add_index "notification_messages", ["message_id"], name: "index_notification_messages_on_message_id", using: :btree
  add_index "notification_messages", ["screen_name"], name: "index_notification_messages_on_screen_name", using: :btree
  add_index "notification_messages", ["token"], name: "index_notification_messages_on_token", using: :btree
  add_index "notification_messages", ["uid"], name: "index_notification_messages_on_uid", using: :btree
  add_index "notification_messages", ["user_id"], name: "index_notification_messages_on_user_id", using: :btree

  create_table "notification_settings", force: :cascade do |t|
    t.boolean  "email",                    default: true, null: false
    t.boolean  "dm",                       default: true, null: false
    t.boolean  "news",                     default: true, null: false
    t.boolean  "search",                   default: true, null: false
    t.datetime "last_email_at",                           null: false
    t.datetime "last_dm_at",                              null: false
    t.datetime "last_news_at",                            null: false
    t.datetime "last_search_at",                          null: false
    t.integer  "from_id",        limit: 4,                null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "notification_settings", ["from_id"], name: "index_notification_settings_on_from_id", using: :btree

  create_table "search_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191, default: "",    null: false
    t.integer  "user_id",     limit: 4,   default: -1,    null: false
    t.string   "uid",         limit: 191, default: "",    null: false
    t.string   "screen_name", limit: 191, default: "",    null: false
    t.string   "action",      limit: 191, default: "",    null: false
    t.boolean  "ego_surfing",             default: false, null: false
    t.string   "method",      limit: 191, default: "",    null: false
    t.string   "device_type", limit: 191, default: "",    null: false
    t.string   "os",          limit: 191, default: "",    null: false
    t.string   "browser",     limit: 191, default: "",    null: false
    t.string   "user_agent",  limit: 191, default: "",    null: false
    t.string   "referer",     limit: 191, default: "",    null: false
    t.string   "referral",    limit: 191, default: "",    null: false
    t.string   "channel",     limit: 191, default: "",    null: false
    t.string   "medium",      limit: 191, default: "",    null: false
    t.datetime "created_at",                              null: false
  end

  add_index "search_logs", ["action"], name: "index_search_logs_on_action", using: :btree
  add_index "search_logs", ["created_at"], name: "index_search_logs_on_created_at", using: :btree
  add_index "search_logs", ["screen_name"], name: "index_search_logs_on_screen_name", using: :btree
  add_index "search_logs", ["uid", "action"], name: "index_search_logs_on_uid_and_action", using: :btree
  add_index "search_logs", ["uid"], name: "index_search_logs_on_uid", using: :btree
  add_index "search_logs", ["user_id"], name: "index_search_logs_on_user_id", using: :btree

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

  create_table "sign_in_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191, default: "", null: false
    t.integer  "user_id",     limit: 4,   default: -1, null: false
    t.string   "context",     limit: 191, default: "", null: false
    t.string   "via",         limit: 191, default: "", null: false
    t.string   "device_type", limit: 191, default: "", null: false
    t.string   "os",          limit: 191, default: "", null: false
    t.string   "browser",     limit: 191, default: "", null: false
    t.string   "user_agent",  limit: 191, default: "", null: false
    t.string   "referer",     limit: 191, default: "", null: false
    t.string   "referral",    limit: 191, default: "", null: false
    t.string   "channel",     limit: 191, default: "", null: false
    t.datetime "created_at",                           null: false
  end

  add_index "sign_in_logs", ["created_at"], name: "index_sign_in_logs_on_created_at", using: :btree
  add_index "sign_in_logs", ["user_id"], name: "index_sign_in_logs_on_user_id", using: :btree

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
    t.integer  "user_id",      limit: 4,                 null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "twitter_users", ["created_at"], name: "index_twitter_users_on_created_at", using: :btree
  add_index "twitter_users", ["screen_name", "user_id"], name: "index_twitter_users_on_screen_name_and_user_id", using: :btree
  add_index "twitter_users", ["screen_name"], name: "index_twitter_users_on_screen_name", using: :btree
  add_index "twitter_users", ["uid", "user_id"], name: "index_twitter_users_on_uid_and_user_id", using: :btree
  add_index "twitter_users", ["uid"], name: "index_twitter_users_on_uid", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "uid",         limit: 191,              null: false
    t.string   "screen_name", limit: 191,              null: false
    t.string   "secret",      limit: 191,              null: false
    t.string   "token",       limit: 191,              null: false
    t.string   "email",       limit: 191, default: "", null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "users", ["created_at"], name: "index_users_on_created_at", using: :btree
  add_index "users", ["screen_name"], name: "index_users_on_screen_name", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

end
