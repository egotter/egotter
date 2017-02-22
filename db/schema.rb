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

ActiveRecord::Schema.define(version: 20170222055518) do

  create_table "background_force_update_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191,   default: "",    null: false
    t.integer  "user_id",     limit: 4,     default: -1,    null: false
    t.string   "uid",         limit: 191,   default: "-1",  null: false
    t.string   "screen_name", limit: 191,   default: "",    null: false
    t.string   "action",      limit: 191,   default: "",    null: false
    t.string   "bot_uid",     limit: 191,   default: "-1",  null: false
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
    t.string   "medium",      limit: 191,   default: "",    null: false
    t.datetime "created_at",                                null: false
  end

  add_index "background_force_update_logs", ["created_at"], name: "index_background_force_update_logs_on_created_at", using: :btree
  add_index "background_force_update_logs", ["screen_name"], name: "index_background_force_update_logs_on_screen_name", using: :btree
  add_index "background_force_update_logs", ["uid"], name: "index_background_force_update_logs_on_uid", using: :btree
  add_index "background_force_update_logs", ["user_id"], name: "index_background_force_update_logs_on_user_id", using: :btree

  create_table "background_search_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191,   default: "",    null: false
    t.integer  "user_id",     limit: 4,     default: -1,    null: false
    t.string   "uid",         limit: 191,   default: "-1",  null: false
    t.string   "screen_name", limit: 191,   default: "",    null: false
    t.string   "action",      limit: 191,   default: "",    null: false
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
    t.string   "medium",      limit: 191,   default: "",    null: false
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

  create_table "bots", force: :cascade do |t|
    t.integer  "uid",         limit: 8,   null: false
    t.string   "screen_name", limit: 191, null: false
    t.string   "secret",      limit: 191, null: false
    t.string   "token",       limit: 191, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "bots", ["screen_name"], name: "index_bots_on_screen_name", using: :btree
  add_index "bots", ["uid"], name: "index_bots_on_uid", unique: true, using: :btree

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

  create_table "create_prompt_report_logs", force: :cascade do |t|
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

  add_index "create_prompt_report_logs", ["created_at"], name: "index_create_prompt_report_logs_on_created_at", using: :btree
  add_index "create_prompt_report_logs", ["screen_name"], name: "index_create_prompt_report_logs_on_screen_name", using: :btree
  add_index "create_prompt_report_logs", ["uid"], name: "index_create_prompt_report_logs_on_uid", using: :btree

  create_table "create_relationship_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191,   default: "",    null: false
    t.integer  "user_id",     limit: 4,     default: -1,    null: false
    t.string   "uid",         limit: 191,   default: "-1",  null: false
    t.string   "screen_name", limit: 191,   default: "",    null: false
    t.string   "bot_uid",     limit: 191,   default: "-1",  null: false
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

  add_index "create_relationship_logs", ["created_at"], name: "index_create_relationship_logs_on_created_at", using: :btree
  add_index "create_relationship_logs", ["screen_name"], name: "index_create_relationship_logs_on_screen_name", using: :btree
  add_index "create_relationship_logs", ["uid"], name: "index_create_relationship_logs_on_uid", using: :btree
  add_index "create_relationship_logs", ["user_id"], name: "index_create_relationship_logs_on_user_id", using: :btree

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

  create_table "followerships", force: :cascade do |t|
    t.integer "from_id",      limit: 4, null: false
    t.integer "follower_uid", limit: 8, null: false
    t.integer "sequence",     limit: 4, null: false
  end

  add_index "followerships", ["follower_uid"], name: "index_followerships_on_follower_uid", using: :btree
  add_index "followerships", ["from_id", "follower_uid"], name: "index_followerships_on_from_id_and_follower_uid", unique: true, using: :btree
  add_index "followerships", ["from_id"], name: "index_followerships_on_from_id", using: :btree

  create_table "forbidden_users", force: :cascade do |t|
    t.string   "screen_name", limit: 191, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "forbidden_users", ["created_at"], name: "index_forbidden_users_on_created_at", using: :btree
  add_index "forbidden_users", ["screen_name"], name: "index_forbidden_users_on_screen_name", unique: true, using: :btree

  create_table "friends", force: :cascade do |t|
    t.string   "uid",         limit: 191,   null: false
    t.string   "screen_name", limit: 191,   null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",     limit: 4,     null: false
    t.datetime "created_at",                null: false
  end

  add_index "friends", ["from_id"], name: "index_friends_on_from_id", using: :btree

  create_table "friendships", force: :cascade do |t|
    t.integer "from_id",    limit: 4, null: false
    t.integer "friend_uid", limit: 8, null: false
    t.integer "sequence",   limit: 4, null: false
  end

  add_index "friendships", ["friend_uid"], name: "index_friendships_on_friend_uid", using: :btree
  add_index "friendships", ["from_id", "friend_uid"], name: "index_friendships_on_from_id_and_friend_uid", unique: true, using: :btree
  add_index "friendships", ["from_id"], name: "index_friendships_on_from_id", using: :btree

  create_table "inactive_followerships", force: :cascade do |t|
    t.integer "from_uid",     limit: 8, null: false
    t.integer "follower_uid", limit: 8, null: false
    t.integer "sequence",     limit: 4, null: false
  end

  add_index "inactive_followerships", ["follower_uid"], name: "index_inactive_followerships_on_follower_uid", using: :btree
  add_index "inactive_followerships", ["from_uid"], name: "index_inactive_followerships_on_from_uid", using: :btree

  create_table "inactive_friendships", force: :cascade do |t|
    t.integer "from_uid",   limit: 8, null: false
    t.integer "friend_uid", limit: 8, null: false
    t.integer "sequence",   limit: 4, null: false
  end

  add_index "inactive_friendships", ["friend_uid"], name: "index_inactive_friendships_on_friend_uid", using: :btree
  add_index "inactive_friendships", ["from_uid"], name: "index_inactive_friendships_on_from_uid", using: :btree

  create_table "inactive_mutual_friendships", force: :cascade do |t|
    t.integer "from_uid",   limit: 8, null: false
    t.integer "friend_uid", limit: 8, null: false
    t.integer "sequence",   limit: 4, null: false
  end

  add_index "inactive_mutual_friendships", ["friend_uid"], name: "index_inactive_mutual_friendships_on_friend_uid", using: :btree
  add_index "inactive_mutual_friendships", ["from_uid"], name: "index_inactive_mutual_friendships_on_from_uid", using: :btree

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

  create_table "mutual_friendships", force: :cascade do |t|
    t.integer "from_uid",   limit: 8, null: false
    t.integer "friend_uid", limit: 8, null: false
    t.integer "sequence",   limit: 4, null: false
  end

  add_index "mutual_friendships", ["friend_uid"], name: "index_mutual_friendships_on_friend_uid", using: :btree
  add_index "mutual_friendships", ["from_uid"], name: "index_mutual_friendships_on_from_uid", using: :btree

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
    t.boolean  "email",                           default: true, null: false
    t.boolean  "dm",                              default: true, null: false
    t.boolean  "news",                            default: true, null: false
    t.boolean  "search",                          default: true, null: false
    t.boolean  "prompt_report",                   default: true, null: false
    t.datetime "last_email_at"
    t.datetime "last_dm_at"
    t.datetime "last_news_at"
    t.datetime "search_sent_at"
    t.datetime "prompt_report_sent_at"
    t.integer  "user_id",               limit: 4,                null: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  add_index "notification_settings", ["user_id"], name: "index_notification_settings_on_user_id", unique: true, using: :btree

  create_table "old_users", force: :cascade do |t|
    t.integer  "uid",         limit: 8,                   null: false
    t.string   "screen_name", limit: 191,                 null: false
    t.boolean  "authorized",              default: false, null: false
    t.string   "secret",      limit: 191,                 null: false
    t.string   "token",       limit: 191,                 null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "old_users", ["created_at"], name: "index_old_users_on_created_at", using: :btree
  add_index "old_users", ["screen_name"], name: "index_old_users_on_screen_name", using: :btree
  add_index "old_users", ["uid"], name: "index_old_users_on_uid", unique: true, using: :btree

  create_table "one_sided_followerships", force: :cascade do |t|
    t.integer "from_uid",     limit: 8, null: false
    t.integer "follower_uid", limit: 8, null: false
    t.integer "sequence",     limit: 4, null: false
  end

  add_index "one_sided_followerships", ["follower_uid"], name: "index_one_sided_followerships_on_follower_uid", using: :btree
  add_index "one_sided_followerships", ["from_uid"], name: "index_one_sided_followerships_on_from_uid", using: :btree

  create_table "one_sided_friendships", force: :cascade do |t|
    t.integer "from_uid",   limit: 8, null: false
    t.integer "friend_uid", limit: 8, null: false
    t.integer "sequence",   limit: 4, null: false
  end

  add_index "one_sided_friendships", ["friend_uid"], name: "index_one_sided_friendships_on_friend_uid", using: :btree
  add_index "one_sided_friendships", ["from_uid"], name: "index_one_sided_friendships_on_from_uid", using: :btree

  create_table "page_cache_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191, default: "", null: false
    t.integer  "user_id",     limit: 4,   default: -1, null: false
    t.string   "context",     limit: 191, default: "", null: false
    t.string   "device_type", limit: 191, default: "", null: false
    t.string   "os",          limit: 191, default: "", null: false
    t.string   "browser",     limit: 191, default: "", null: false
    t.string   "user_agent",  limit: 191, default: "", null: false
    t.string   "referer",     limit: 191, default: "", null: false
    t.string   "referral",    limit: 191, default: "", null: false
    t.string   "channel",     limit: 191, default: "", null: false
    t.datetime "created_at",                           null: false
  end

  add_index "page_cache_logs", ["created_at"], name: "index_page_cache_logs_on_created_at", using: :btree

  create_table "polling_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191, default: "",    null: false
    t.integer  "user_id",     limit: 4,   default: -1,    null: false
    t.string   "uid",         limit: 191, default: "",    null: false
    t.string   "screen_name", limit: 191, default: "",    null: false
    t.string   "action",      limit: 191, default: "",    null: false
    t.boolean  "status",                  default: false, null: false
    t.float    "time",        limit: 24,  default: 0.0,   null: false
    t.integer  "retry_count", limit: 4,   default: 0,     null: false
    t.string   "device_type", limit: 191, default: "",    null: false
    t.string   "os",          limit: 191, default: "",    null: false
    t.string   "browser",     limit: 191, default: "",    null: false
    t.string   "user_agent",  limit: 191, default: "",    null: false
    t.string   "referer",     limit: 191, default: "",    null: false
    t.string   "referral",    limit: 191, default: "",    null: false
    t.string   "channel",     limit: 191, default: "",    null: false
    t.datetime "created_at",                              null: false
  end

  add_index "polling_logs", ["created_at"], name: "index_polling_logs_on_created_at", using: :btree
  add_index "polling_logs", ["screen_name"], name: "index_polling_logs_on_screen_name", using: :btree
  add_index "polling_logs", ["session_id"], name: "index_polling_logs_on_session_id", using: :btree
  add_index "polling_logs", ["uid"], name: "index_polling_logs_on_uid", using: :btree
  add_index "polling_logs", ["user_id"], name: "index_polling_logs_on_user_id", using: :btree

  create_table "search_logs", force: :cascade do |t|
    t.string   "session_id",  limit: 191, default: "",    null: false
    t.integer  "user_id",     limit: 4,   default: -1,    null: false
    t.string   "uid",         limit: 191, default: "",    null: false
    t.string   "screen_name", limit: 191, default: "",    null: false
    t.string   "action",      limit: 191, default: "",    null: false
    t.boolean  "cache_hit",               default: false, null: false
    t.boolean  "ego_surfing",             default: false, null: false
    t.string   "method",      limit: 191, default: "",    null: false
    t.string   "via",         limit: 191, default: "",    null: false
    t.string   "device_type", limit: 191, default: "",    null: false
    t.string   "os",          limit: 191, default: "",    null: false
    t.string   "browser",     limit: 191, default: "",    null: false
    t.string   "user_agent",  limit: 191, default: "",    null: false
    t.string   "referer",     limit: 191, default: "",    null: false
    t.string   "referral",    limit: 191, default: "",    null: false
    t.string   "channel",     limit: 191, default: "",    null: false
    t.boolean  "first_time",              default: false, null: false
    t.boolean  "landing",                 default: false, null: false
    t.boolean  "bouncing",                default: false, null: false
    t.boolean  "exiting",                 default: false, null: false
    t.string   "medium",      limit: 191, default: "",    null: false
    t.string   "ab_test",     limit: 191, default: "",    null: false
    t.datetime "created_at",                              null: false
  end

  add_index "search_logs", ["action"], name: "index_search_logs_on_action", using: :btree
  add_index "search_logs", ["created_at"], name: "index_search_logs_on_created_at", using: :btree
  add_index "search_logs", ["screen_name"], name: "index_search_logs_on_screen_name", using: :btree
  add_index "search_logs", ["session_id"], name: "index_search_logs_on_session_id", using: :btree
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
    t.string   "session_id",  limit: 191, default: "",    null: false
    t.integer  "user_id",     limit: 4,   default: -1,    null: false
    t.string   "uid",         limit: 191, default: "-1",  null: false
    t.string   "screen_name", limit: 191, default: "",    null: false
    t.string   "context",     limit: 191, default: "",    null: false
    t.boolean  "follow",                  default: false, null: false
    t.string   "via",         limit: 191, default: "",    null: false
    t.string   "device_type", limit: 191, default: "",    null: false
    t.string   "os",          limit: 191, default: "",    null: false
    t.string   "browser",     limit: 191, default: "",    null: false
    t.string   "user_agent",  limit: 191, default: "",    null: false
    t.string   "referer",     limit: 191, default: "",    null: false
    t.string   "referral",    limit: 191, default: "",    null: false
    t.string   "channel",     limit: 191, default: "",    null: false
    t.string   "ab_test",     limit: 191, default: "",    null: false
    t.datetime "created_at",                              null: false
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

  create_table "twitter_db_followerships", force: :cascade do |t|
    t.integer "user_uid",     limit: 8, null: false
    t.integer "follower_uid", limit: 8, null: false
    t.integer "sequence",     limit: 4, null: false
  end

  add_index "twitter_db_followerships", ["follower_uid"], name: "index_twitter_db_followerships_on_follower_uid", using: :btree
  add_index "twitter_db_followerships", ["user_uid", "follower_uid"], name: "index_twitter_db_followerships_on_user_uid_and_follower_uid", unique: true, using: :btree
  add_index "twitter_db_followerships", ["user_uid"], name: "index_twitter_db_followerships_on_user_uid", using: :btree

  create_table "twitter_db_friendships", force: :cascade do |t|
    t.integer "user_uid",   limit: 8, null: false
    t.integer "friend_uid", limit: 8, null: false
    t.integer "sequence",   limit: 4, null: false
  end

  add_index "twitter_db_friendships", ["friend_uid"], name: "index_twitter_db_friendships_on_friend_uid", using: :btree
  add_index "twitter_db_friendships", ["user_uid", "friend_uid"], name: "index_twitter_db_friendships_on_user_uid_and_friend_uid", unique: true, using: :btree
  add_index "twitter_db_friendships", ["user_uid"], name: "index_twitter_db_friendships_on_user_uid", using: :btree

  create_table "twitter_db_users", force: :cascade do |t|
    t.integer  "uid",            limit: 8,                 null: false
    t.string   "screen_name",    limit: 191,               null: false
    t.integer  "friends_size",   limit: 4,     default: 0, null: false
    t.integer  "followers_size", limit: 4,     default: 0, null: false
    t.text     "user_info",      limit: 65535,             null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "twitter_db_users", ["created_at"], name: "index_twitter_db_users_on_created_at", using: :btree
  add_index "twitter_db_users", ["screen_name"], name: "index_twitter_db_users_on_screen_name", using: :btree
  add_index "twitter_db_users", ["uid"], name: "index_twitter_db_users_on_uid", unique: true, using: :btree

  create_table "twitter_users", force: :cascade do |t|
    t.string   "uid",            limit: 191,               null: false
    t.string   "screen_name",    limit: 191,               null: false
    t.integer  "friends_size",   limit: 4,     default: 0, null: false
    t.integer  "followers_size", limit: 4,     default: 0, null: false
    t.text     "user_info",      limit: 65535,             null: false
    t.integer  "search_count",   limit: 4,     default: 0, null: false
    t.integer  "update_count",   limit: 4,     default: 0, null: false
    t.integer  "user_id",        limit: 4,                 null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "twitter_users", ["created_at"], name: "index_twitter_users_on_created_at", using: :btree
  add_index "twitter_users", ["screen_name", "user_id"], name: "index_twitter_users_on_screen_name_and_user_id", using: :btree
  add_index "twitter_users", ["screen_name"], name: "index_twitter_users_on_screen_name", using: :btree
  add_index "twitter_users", ["uid", "user_id"], name: "index_twitter_users_on_uid_and_user_id", using: :btree
  add_index "twitter_users", ["uid"], name: "index_twitter_users_on_uid", using: :btree

  create_table "unfollowerships", force: :cascade do |t|
    t.integer "from_uid",     limit: 8, null: false
    t.integer "follower_uid", limit: 8, null: false
    t.integer "sequence",     limit: 4, null: false
  end

  add_index "unfollowerships", ["follower_uid"], name: "index_unfollowerships_on_follower_uid", using: :btree
  add_index "unfollowerships", ["from_uid"], name: "index_unfollowerships_on_from_uid", using: :btree

  create_table "unfriendships", force: :cascade do |t|
    t.integer "from_uid",   limit: 8, null: false
    t.integer "friend_uid", limit: 8, null: false
    t.integer "sequence",   limit: 4, null: false
  end

  add_index "unfriendships", ["friend_uid"], name: "index_unfriendships_on_friend_uid", using: :btree
  add_index "unfriendships", ["from_uid"], name: "index_unfriendships_on_from_uid", using: :btree

  create_table "user_engagement_stats", force: :cascade do |t|
    t.datetime "date",                                 null: false
    t.integer  "total",          limit: 4, default: 0, null: false
    t.integer  "1_days",         limit: 4, default: 0, null: false
    t.integer  "2_days",         limit: 4, default: 0, null: false
    t.integer  "3_days",         limit: 4, default: 0, null: false
    t.integer  "4_days",         limit: 4, default: 0, null: false
    t.integer  "5_days",         limit: 4, default: 0, null: false
    t.integer  "6_days",         limit: 4, default: 0, null: false
    t.integer  "7_days",         limit: 4, default: 0, null: false
    t.integer  "8_days",         limit: 4, default: 0, null: false
    t.integer  "9_days",         limit: 4, default: 0, null: false
    t.integer  "10_days",        limit: 4, default: 0, null: false
    t.integer  "11_days",        limit: 4, default: 0, null: false
    t.integer  "12_days",        limit: 4, default: 0, null: false
    t.integer  "13_days",        limit: 4, default: 0, null: false
    t.integer  "14_days",        limit: 4, default: 0, null: false
    t.integer  "15_days",        limit: 4, default: 0, null: false
    t.integer  "16_days",        limit: 4, default: 0, null: false
    t.integer  "17_days",        limit: 4, default: 0, null: false
    t.integer  "18_days",        limit: 4, default: 0, null: false
    t.integer  "19_days",        limit: 4, default: 0, null: false
    t.integer  "20_days",        limit: 4, default: 0, null: false
    t.integer  "21_days",        limit: 4, default: 0, null: false
    t.integer  "22_days",        limit: 4, default: 0, null: false
    t.integer  "23_days",        limit: 4, default: 0, null: false
    t.integer  "24_days",        limit: 4, default: 0, null: false
    t.integer  "25_days",        limit: 4, default: 0, null: false
    t.integer  "26_days",        limit: 4, default: 0, null: false
    t.integer  "27_days",        limit: 4, default: 0, null: false
    t.integer  "28_days",        limit: 4, default: 0, null: false
    t.integer  "29_days",        limit: 4, default: 0, null: false
    t.integer  "30_days",        limit: 4, default: 0, null: false
    t.integer  "before_1_days",  limit: 4, default: 0, null: false
    t.integer  "before_2_days",  limit: 4, default: 0, null: false
    t.integer  "before_3_days",  limit: 4, default: 0, null: false
    t.integer  "before_4_days",  limit: 4, default: 0, null: false
    t.integer  "before_5_days",  limit: 4, default: 0, null: false
    t.integer  "before_6_days",  limit: 4, default: 0, null: false
    t.integer  "before_7_days",  limit: 4, default: 0, null: false
    t.integer  "before_8_days",  limit: 4, default: 0, null: false
    t.integer  "before_9_days",  limit: 4, default: 0, null: false
    t.integer  "before_10_days", limit: 4, default: 0, null: false
    t.integer  "before_11_days", limit: 4, default: 0, null: false
    t.integer  "before_12_days", limit: 4, default: 0, null: false
    t.integer  "before_13_days", limit: 4, default: 0, null: false
    t.integer  "before_14_days", limit: 4, default: 0, null: false
    t.integer  "before_15_days", limit: 4, default: 0, null: false
    t.integer  "before_16_days", limit: 4, default: 0, null: false
    t.integer  "before_17_days", limit: 4, default: 0, null: false
    t.integer  "before_18_days", limit: 4, default: 0, null: false
    t.integer  "before_19_days", limit: 4, default: 0, null: false
    t.integer  "before_20_days", limit: 4, default: 0, null: false
    t.integer  "before_21_days", limit: 4, default: 0, null: false
    t.integer  "before_22_days", limit: 4, default: 0, null: false
    t.integer  "before_23_days", limit: 4, default: 0, null: false
    t.integer  "before_24_days", limit: 4, default: 0, null: false
    t.integer  "before_25_days", limit: 4, default: 0, null: false
    t.integer  "before_26_days", limit: 4, default: 0, null: false
    t.integer  "before_27_days", limit: 4, default: 0, null: false
    t.integer  "before_28_days", limit: 4, default: 0, null: false
    t.integer  "before_29_days", limit: 4, default: 0, null: false
    t.integer  "before_30_days", limit: 4, default: 0, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "user_engagement_stats", ["date"], name: "index_user_engagement_stats_on_date", unique: true, using: :btree

  create_table "user_retention_stats", force: :cascade do |t|
    t.datetime "date",                                null: false
    t.integer  "total",         limit: 4, default: 0, null: false
    t.integer  "1_days",        limit: 4, default: 0, null: false
    t.integer  "2_days",        limit: 4, default: 0, null: false
    t.integer  "3_days",        limit: 4, default: 0, null: false
    t.integer  "4_days",        limit: 4, default: 0, null: false
    t.integer  "5_days",        limit: 4, default: 0, null: false
    t.integer  "6_days",        limit: 4, default: 0, null: false
    t.integer  "7_days",        limit: 4, default: 0, null: false
    t.integer  "8_days",        limit: 4, default: 0, null: false
    t.integer  "9_days",        limit: 4, default: 0, null: false
    t.integer  "10_days",       limit: 4, default: 0, null: false
    t.integer  "11_days",       limit: 4, default: 0, null: false
    t.integer  "12_days",       limit: 4, default: 0, null: false
    t.integer  "13_days",       limit: 4, default: 0, null: false
    t.integer  "14_days",       limit: 4, default: 0, null: false
    t.integer  "15_days",       limit: 4, default: 0, null: false
    t.integer  "16_days",       limit: 4, default: 0, null: false
    t.integer  "17_days",       limit: 4, default: 0, null: false
    t.integer  "18_days",       limit: 4, default: 0, null: false
    t.integer  "19_days",       limit: 4, default: 0, null: false
    t.integer  "20_days",       limit: 4, default: 0, null: false
    t.integer  "21_days",       limit: 4, default: 0, null: false
    t.integer  "22_days",       limit: 4, default: 0, null: false
    t.integer  "23_days",       limit: 4, default: 0, null: false
    t.integer  "24_days",       limit: 4, default: 0, null: false
    t.integer  "25_days",       limit: 4, default: 0, null: false
    t.integer  "26_days",       limit: 4, default: 0, null: false
    t.integer  "27_days",       limit: 4, default: 0, null: false
    t.integer  "28_days",       limit: 4, default: 0, null: false
    t.integer  "29_days",       limit: 4, default: 0, null: false
    t.integer  "30_days",       limit: 4, default: 0, null: false
    t.integer  "after_1_days",  limit: 4, default: 0, null: false
    t.integer  "after_2_days",  limit: 4, default: 0, null: false
    t.integer  "after_3_days",  limit: 4, default: 0, null: false
    t.integer  "after_4_days",  limit: 4, default: 0, null: false
    t.integer  "after_5_days",  limit: 4, default: 0, null: false
    t.integer  "after_6_days",  limit: 4, default: 0, null: false
    t.integer  "after_7_days",  limit: 4, default: 0, null: false
    t.integer  "after_8_days",  limit: 4, default: 0, null: false
    t.integer  "after_9_days",  limit: 4, default: 0, null: false
    t.integer  "after_10_days", limit: 4, default: 0, null: false
    t.integer  "after_11_days", limit: 4, default: 0, null: false
    t.integer  "after_12_days", limit: 4, default: 0, null: false
    t.integer  "after_13_days", limit: 4, default: 0, null: false
    t.integer  "after_14_days", limit: 4, default: 0, null: false
    t.integer  "after_15_days", limit: 4, default: 0, null: false
    t.integer  "after_16_days", limit: 4, default: 0, null: false
    t.integer  "after_17_days", limit: 4, default: 0, null: false
    t.integer  "after_18_days", limit: 4, default: 0, null: false
    t.integer  "after_19_days", limit: 4, default: 0, null: false
    t.integer  "after_20_days", limit: 4, default: 0, null: false
    t.integer  "after_21_days", limit: 4, default: 0, null: false
    t.integer  "after_22_days", limit: 4, default: 0, null: false
    t.integer  "after_23_days", limit: 4, default: 0, null: false
    t.integer  "after_24_days", limit: 4, default: 0, null: false
    t.integer  "after_25_days", limit: 4, default: 0, null: false
    t.integer  "after_26_days", limit: 4, default: 0, null: false
    t.integer  "after_27_days", limit: 4, default: 0, null: false
    t.integer  "after_28_days", limit: 4, default: 0, null: false
    t.integer  "after_29_days", limit: 4, default: 0, null: false
    t.integer  "after_30_days", limit: 4, default: 0, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "user_retention_stats", ["date"], name: "index_user_retention_stats_on_date", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "uid",              limit: 191,                null: false
    t.string   "screen_name",      limit: 191,                null: false
    t.boolean  "authorized",                   default: true, null: false
    t.string   "secret",           limit: 191,                null: false
    t.string   "token",            limit: 191,                null: false
    t.string   "email",            limit: 191, default: "",   null: false
    t.datetime "first_access_at"
    t.datetime "last_access_at"
    t.datetime "first_search_at"
    t.datetime "last_search_at"
    t.datetime "first_sign_in_at"
    t.datetime "last_sign_in_at"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "users", ["created_at"], name: "index_users_on_created_at", using: :btree
  add_index "users", ["screen_name"], name: "index_users_on_screen_name", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

  create_table "visitor_engagement_stats", force: :cascade do |t|
    t.datetime "date",                                 null: false
    t.integer  "total",          limit: 4, default: 0, null: false
    t.integer  "1_days",         limit: 4, default: 0, null: false
    t.integer  "2_days",         limit: 4, default: 0, null: false
    t.integer  "3_days",         limit: 4, default: 0, null: false
    t.integer  "4_days",         limit: 4, default: 0, null: false
    t.integer  "5_days",         limit: 4, default: 0, null: false
    t.integer  "6_days",         limit: 4, default: 0, null: false
    t.integer  "7_days",         limit: 4, default: 0, null: false
    t.integer  "8_days",         limit: 4, default: 0, null: false
    t.integer  "9_days",         limit: 4, default: 0, null: false
    t.integer  "10_days",        limit: 4, default: 0, null: false
    t.integer  "11_days",        limit: 4, default: 0, null: false
    t.integer  "12_days",        limit: 4, default: 0, null: false
    t.integer  "13_days",        limit: 4, default: 0, null: false
    t.integer  "14_days",        limit: 4, default: 0, null: false
    t.integer  "15_days",        limit: 4, default: 0, null: false
    t.integer  "16_days",        limit: 4, default: 0, null: false
    t.integer  "17_days",        limit: 4, default: 0, null: false
    t.integer  "18_days",        limit: 4, default: 0, null: false
    t.integer  "19_days",        limit: 4, default: 0, null: false
    t.integer  "20_days",        limit: 4, default: 0, null: false
    t.integer  "21_days",        limit: 4, default: 0, null: false
    t.integer  "22_days",        limit: 4, default: 0, null: false
    t.integer  "23_days",        limit: 4, default: 0, null: false
    t.integer  "24_days",        limit: 4, default: 0, null: false
    t.integer  "25_days",        limit: 4, default: 0, null: false
    t.integer  "26_days",        limit: 4, default: 0, null: false
    t.integer  "27_days",        limit: 4, default: 0, null: false
    t.integer  "28_days",        limit: 4, default: 0, null: false
    t.integer  "29_days",        limit: 4, default: 0, null: false
    t.integer  "30_days",        limit: 4, default: 0, null: false
    t.integer  "before_1_days",  limit: 4, default: 0, null: false
    t.integer  "before_2_days",  limit: 4, default: 0, null: false
    t.integer  "before_3_days",  limit: 4, default: 0, null: false
    t.integer  "before_4_days",  limit: 4, default: 0, null: false
    t.integer  "before_5_days",  limit: 4, default: 0, null: false
    t.integer  "before_6_days",  limit: 4, default: 0, null: false
    t.integer  "before_7_days",  limit: 4, default: 0, null: false
    t.integer  "before_8_days",  limit: 4, default: 0, null: false
    t.integer  "before_9_days",  limit: 4, default: 0, null: false
    t.integer  "before_10_days", limit: 4, default: 0, null: false
    t.integer  "before_11_days", limit: 4, default: 0, null: false
    t.integer  "before_12_days", limit: 4, default: 0, null: false
    t.integer  "before_13_days", limit: 4, default: 0, null: false
    t.integer  "before_14_days", limit: 4, default: 0, null: false
    t.integer  "before_15_days", limit: 4, default: 0, null: false
    t.integer  "before_16_days", limit: 4, default: 0, null: false
    t.integer  "before_17_days", limit: 4, default: 0, null: false
    t.integer  "before_18_days", limit: 4, default: 0, null: false
    t.integer  "before_19_days", limit: 4, default: 0, null: false
    t.integer  "before_20_days", limit: 4, default: 0, null: false
    t.integer  "before_21_days", limit: 4, default: 0, null: false
    t.integer  "before_22_days", limit: 4, default: 0, null: false
    t.integer  "before_23_days", limit: 4, default: 0, null: false
    t.integer  "before_24_days", limit: 4, default: 0, null: false
    t.integer  "before_25_days", limit: 4, default: 0, null: false
    t.integer  "before_26_days", limit: 4, default: 0, null: false
    t.integer  "before_27_days", limit: 4, default: 0, null: false
    t.integer  "before_28_days", limit: 4, default: 0, null: false
    t.integer  "before_29_days", limit: 4, default: 0, null: false
    t.integer  "before_30_days", limit: 4, default: 0, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "visitor_engagement_stats", ["date"], name: "index_visitor_engagement_stats_on_date", unique: true, using: :btree

  create_table "visitor_retention_stats", force: :cascade do |t|
    t.datetime "date",                                null: false
    t.integer  "total",         limit: 4, default: 0, null: false
    t.integer  "1_days",        limit: 4, default: 0, null: false
    t.integer  "2_days",        limit: 4, default: 0, null: false
    t.integer  "3_days",        limit: 4, default: 0, null: false
    t.integer  "4_days",        limit: 4, default: 0, null: false
    t.integer  "5_days",        limit: 4, default: 0, null: false
    t.integer  "6_days",        limit: 4, default: 0, null: false
    t.integer  "7_days",        limit: 4, default: 0, null: false
    t.integer  "8_days",        limit: 4, default: 0, null: false
    t.integer  "9_days",        limit: 4, default: 0, null: false
    t.integer  "10_days",       limit: 4, default: 0, null: false
    t.integer  "11_days",       limit: 4, default: 0, null: false
    t.integer  "12_days",       limit: 4, default: 0, null: false
    t.integer  "13_days",       limit: 4, default: 0, null: false
    t.integer  "14_days",       limit: 4, default: 0, null: false
    t.integer  "15_days",       limit: 4, default: 0, null: false
    t.integer  "16_days",       limit: 4, default: 0, null: false
    t.integer  "17_days",       limit: 4, default: 0, null: false
    t.integer  "18_days",       limit: 4, default: 0, null: false
    t.integer  "19_days",       limit: 4, default: 0, null: false
    t.integer  "20_days",       limit: 4, default: 0, null: false
    t.integer  "21_days",       limit: 4, default: 0, null: false
    t.integer  "22_days",       limit: 4, default: 0, null: false
    t.integer  "23_days",       limit: 4, default: 0, null: false
    t.integer  "24_days",       limit: 4, default: 0, null: false
    t.integer  "25_days",       limit: 4, default: 0, null: false
    t.integer  "26_days",       limit: 4, default: 0, null: false
    t.integer  "27_days",       limit: 4, default: 0, null: false
    t.integer  "28_days",       limit: 4, default: 0, null: false
    t.integer  "29_days",       limit: 4, default: 0, null: false
    t.integer  "30_days",       limit: 4, default: 0, null: false
    t.integer  "after_1_days",  limit: 4, default: 0, null: false
    t.integer  "after_2_days",  limit: 4, default: 0, null: false
    t.integer  "after_3_days",  limit: 4, default: 0, null: false
    t.integer  "after_4_days",  limit: 4, default: 0, null: false
    t.integer  "after_5_days",  limit: 4, default: 0, null: false
    t.integer  "after_6_days",  limit: 4, default: 0, null: false
    t.integer  "after_7_days",  limit: 4, default: 0, null: false
    t.integer  "after_8_days",  limit: 4, default: 0, null: false
    t.integer  "after_9_days",  limit: 4, default: 0, null: false
    t.integer  "after_10_days", limit: 4, default: 0, null: false
    t.integer  "after_11_days", limit: 4, default: 0, null: false
    t.integer  "after_12_days", limit: 4, default: 0, null: false
    t.integer  "after_13_days", limit: 4, default: 0, null: false
    t.integer  "after_14_days", limit: 4, default: 0, null: false
    t.integer  "after_15_days", limit: 4, default: 0, null: false
    t.integer  "after_16_days", limit: 4, default: 0, null: false
    t.integer  "after_17_days", limit: 4, default: 0, null: false
    t.integer  "after_18_days", limit: 4, default: 0, null: false
    t.integer  "after_19_days", limit: 4, default: 0, null: false
    t.integer  "after_20_days", limit: 4, default: 0, null: false
    t.integer  "after_21_days", limit: 4, default: 0, null: false
    t.integer  "after_22_days", limit: 4, default: 0, null: false
    t.integer  "after_23_days", limit: 4, default: 0, null: false
    t.integer  "after_24_days", limit: 4, default: 0, null: false
    t.integer  "after_25_days", limit: 4, default: 0, null: false
    t.integer  "after_26_days", limit: 4, default: 0, null: false
    t.integer  "after_27_days", limit: 4, default: 0, null: false
    t.integer  "after_28_days", limit: 4, default: 0, null: false
    t.integer  "after_29_days", limit: 4, default: 0, null: false
    t.integer  "after_30_days", limit: 4, default: 0, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "visitor_retention_stats", ["date"], name: "index_visitor_retention_stats_on_date", unique: true, using: :btree

  create_table "visitors", force: :cascade do |t|
    t.string   "session_id",      limit: 191,                null: false
    t.integer  "user_id",         limit: 4,   default: -1,   null: false
    t.string   "uid",             limit: 191, default: "-1", null: false
    t.string   "screen_name",     limit: 191, default: "",   null: false
    t.datetime "first_access_at"
    t.datetime "last_access_at"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "visitors", ["created_at"], name: "index_visitors_on_created_at", using: :btree
  add_index "visitors", ["first_access_at"], name: "index_visitors_on_first_access_at", using: :btree
  add_index "visitors", ["last_access_at"], name: "index_visitors_on_last_access_at", using: :btree
  add_index "visitors", ["screen_name"], name: "index_visitors_on_screen_name", using: :btree
  add_index "visitors", ["session_id"], name: "index_visitors_on_session_id", unique: true, using: :btree
  add_index "visitors", ["uid"], name: "index_visitors_on_uid", using: :btree
  add_index "visitors", ["user_id"], name: "index_visitors_on_user_id", using: :btree

  add_foreign_key "twitter_db_followerships", "twitter_db_users", column: "follower_uid", primary_key: "uid"
  add_foreign_key "twitter_db_followerships", "twitter_db_users", column: "user_uid", primary_key: "uid"
  add_foreign_key "twitter_db_friendships", "twitter_db_users", column: "friend_uid", primary_key: "uid"
  add_foreign_key "twitter_db_friendships", "twitter_db_users", column: "user_uid", primary_key: "uid"
end
