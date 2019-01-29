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

ActiveRecord::Schema.define(version: 20190126150202) do

  create_table "background_force_update_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",                default: "",    null: false
    t.integer  "user_id",                   default: -1,    null: false
    t.string   "uid",                       default: "-1",  null: false
    t.string   "screen_name",               default: "",    null: false
    t.string   "action",                    default: "",    null: false
    t.string   "bot_uid",                   default: "-1",  null: false
    t.boolean  "status",                    default: false, null: false
    t.string   "reason",                    default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.integer  "call_count",                default: -1,    null: false
    t.string   "via",                       default: "",    null: false
    t.string   "device_type",               default: "",    null: false
    t.string   "os",                        default: "",    null: false
    t.string   "browser",                   default: "",    null: false
    t.string   "user_agent",                default: "",    null: false
    t.string   "referer",                   default: "",    null: false
    t.string   "referral",                  default: "",    null: false
    t.string   "channel",                   default: "",    null: false
    t.string   "medium",                    default: "",    null: false
    t.datetime "created_at",                                null: false
    t.index ["created_at"], name: "index_background_force_update_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_background_force_update_logs_on_screen_name", using: :btree
    t.index ["uid"], name: "index_background_force_update_logs_on_uid", using: :btree
    t.index ["user_id"], name: "index_background_force_update_logs_on_user_id", using: :btree
  end

  create_table "background_search_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",                  default: "",    null: false
    t.integer  "user_id",                     default: -1,    null: false
    t.string   "uid",                         default: "-1",  null: false
    t.string   "screen_name",                 default: "",    null: false
    t.string   "action",                      default: "",    null: false
    t.string   "bot_uid",                     default: "-1",  null: false
    t.boolean  "auto",                        default: false, null: false
    t.boolean  "status",                      default: false, null: false
    t.string   "reason",                      default: "",    null: false
    t.text     "message",       limit: 65535,                 null: false
    t.integer  "call_count",                  default: -1,    null: false
    t.string   "via",                         default: "",    null: false
    t.string   "device_type",                 default: "",    null: false
    t.string   "os",                          default: "",    null: false
    t.string   "browser",                     default: "",    null: false
    t.string   "user_agent",                  default: "",    null: false
    t.string   "referer",                     default: "",    null: false
    t.string   "referral",                    default: "",    null: false
    t.string   "channel",                     default: "",    null: false
    t.string   "medium",                      default: "",    null: false
    t.string   "error_class",                 default: "",    null: false
    t.string   "error_message",               default: "",    null: false
    t.datetime "enqueued_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",                                  null: false
    t.index ["created_at"], name: "index_background_search_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_background_search_logs_on_screen_name", using: :btree
    t.index ["uid"], name: "index_background_search_logs_on_uid", using: :btree
    t.index ["user_id", "status"], name: "index_background_search_logs_on_user_id_and_status", using: :btree
    t.index ["user_id"], name: "index_background_search_logs_on_user_id", using: :btree
  end

  create_table "background_update_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",                   default: -1,    null: false
    t.string   "uid",                       default: "-1",  null: false
    t.string   "screen_name",               default: "",    null: false
    t.string   "bot_uid",                   default: "-1",  null: false
    t.boolean  "status",                    default: false, null: false
    t.string   "reason",                    default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.integer  "call_count",                default: -1,    null: false
    t.datetime "created_at",                                null: false
    t.index ["created_at"], name: "index_background_update_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_background_update_logs_on_screen_name", using: :btree
    t.index ["uid"], name: "index_background_update_logs_on_uid", using: :btree
  end

  create_table "blacklist_words", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "text",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_blacklist_words_on_created_at", using: :btree
    t.index ["text"], name: "index_blacklist_words_on_text", unique: true, using: :btree
  end

  create_table "bots", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint   "uid",         null: false
    t.string   "screen_name", null: false
    t.string   "secret",      null: false
    t.string   "token",       null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["screen_name"], name: "index_bots_on_screen_name", using: :btree
    t.index ["uid"], name: "index_bots_on_uid", unique: true, using: :btree
  end

  create_table "close_friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_close_friendships_on_friend_uid", using: :btree
    t.index ["from_uid"], name: "index_close_friendships_on_from_uid", using: :btree
  end

  create_table "crawler_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "controller",  default: "", null: false
    t.string   "action",      default: "", null: false
    t.string   "device_type", default: "", null: false
    t.string   "os",          default: "", null: false
    t.string   "browser",     default: "", null: false
    t.string   "ip",          default: "", null: false
    t.string   "method",      default: "", null: false
    t.string   "path",        default: "", null: false
    t.string   "user_agent",  default: "", null: false
    t.datetime "created_at",               null: false
    t.index ["created_at"], name: "index_crawler_logs_on_created_at", using: :btree
  end

  create_table "create_notification_message_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",                                   null: false
    t.string   "uid",                                       null: false
    t.string   "screen_name",                               null: false
    t.boolean  "status",                    default: false, null: false
    t.string   "reason",                    default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.string   "context",                   default: "",    null: false
    t.string   "medium",                    default: "",    null: false
    t.datetime "created_at",                                null: false
    t.index ["created_at"], name: "index_create_notification_message_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_create_notification_message_logs_on_screen_name", using: :btree
    t.index ["uid"], name: "index_create_notification_message_logs_on_uid", using: :btree
    t.index ["user_id", "status"], name: "index_create_notification_message_logs_on_user_id_and_status", using: :btree
    t.index ["user_id"], name: "index_create_notification_message_logs_on_user_id", using: :btree
  end

  create_table "create_prompt_report_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",                     default: -1,    null: false
    t.string   "uid",                         default: "-1",  null: false
    t.string   "screen_name",                 default: "",    null: false
    t.string   "bot_uid",                     default: "-1",  null: false
    t.boolean  "status",                      default: false, null: false
    t.string   "reason",                      default: "",    null: false
    t.text     "message",       limit: 65535,                 null: false
    t.integer  "call_count",                  default: -1,    null: false
    t.string   "error_class",                 default: "",    null: false
    t.string   "error_message",               default: "",    null: false
    t.datetime "created_at",                                  null: false
    t.index ["created_at"], name: "index_create_prompt_report_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_create_prompt_report_logs_on_screen_name", using: :btree
    t.index ["uid"], name: "index_create_prompt_report_logs_on_uid", using: :btree
  end

  create_table "create_relationship_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",                default: "",    null: false
    t.integer  "user_id",                   default: -1,    null: false
    t.string   "uid",                       default: "-1",  null: false
    t.string   "screen_name",               default: "",    null: false
    t.string   "bot_uid",                   default: "-1",  null: false
    t.boolean  "status",                    default: false, null: false
    t.string   "reason",                    default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.integer  "call_count",                default: -1,    null: false
    t.string   "via",                       default: "",    null: false
    t.string   "device_type",               default: "",    null: false
    t.string   "os",                        default: "",    null: false
    t.string   "browser",                   default: "",    null: false
    t.string   "user_agent",                default: "",    null: false
    t.string   "referer",                   default: "",    null: false
    t.string   "referral",                  default: "",    null: false
    t.string   "channel",                   default: "",    null: false
    t.datetime "created_at",                                null: false
    t.index ["created_at"], name: "index_create_relationship_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_create_relationship_logs_on_screen_name", using: :btree
    t.index ["uid"], name: "index_create_relationship_logs_on_uid", using: :btree
    t.index ["user_id"], name: "index_create_relationship_logs_on_user_id", using: :btree
  end

  create_table "delete_tweets_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",    default: "",    null: false
    t.integer  "user_id",       default: -1,    null: false
    t.string   "uid",           default: "-1",  null: false
    t.string   "screen_name",   default: "",    null: false
    t.boolean  "status",        default: false, null: false
    t.string   "message",       default: "",    null: false
    t.string   "error_class",   default: "",    null: false
    t.string   "error_message", default: "",    null: false
    t.datetime "created_at",                    null: false
    t.index ["created_at"], name: "index_delete_tweets_logs_on_created_at", using: :btree
  end

  create_table "favorite_friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_favorite_friendships_on_friend_uid", using: :btree
    t.index ["from_uid"], name: "index_favorite_friendships_on_from_uid", using: :btree
  end

  create_table "favorites", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "uid",                       null: false
    t.string   "screen_name",               null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",                   null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["created_at"], name: "index_favorites_on_created_at", using: :btree
    t.index ["from_id"], name: "index_favorites_on_from_id", using: :btree
    t.index ["screen_name"], name: "index_favorites_on_screen_name", using: :btree
    t.index ["uid"], name: "index_favorites_on_uid", using: :btree
  end

  create_table "follow_requests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",                    null: false
    t.bigint   "uid",                        null: false
    t.datetime "finished_at"
    t.string   "error_class",   default: "", null: false
    t.string   "error_message", default: "", null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["created_at"], name: "index_follow_requests_on_created_at", using: :btree
    t.index ["user_id"], name: "index_follow_requests_on_user_id", using: :btree
  end

  create_table "followers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4" do |t|
    t.string   "uid",                       null: false
    t.string   "screen_name",               null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",                   null: false
    t.datetime "created_at",                null: false
    t.index ["from_id"], name: "index_followers_on_from_id", using: :btree
  end

  create_table "followerships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "from_id",      null: false
    t.bigint  "follower_uid", null: false
    t.integer "sequence",     null: false
    t.index ["follower_uid"], name: "index_followerships_on_follower_uid", using: :btree
    t.index ["from_id", "follower_uid"], name: "index_followerships_on_from_id_and_follower_uid", unique: true, using: :btree
    t.index ["from_id"], name: "index_followerships_on_from_id", using: :btree
  end

  create_table "forbidden_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "screen_name", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["created_at"], name: "index_forbidden_users_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_forbidden_users_on_screen_name", unique: true, using: :btree
  end

  create_table "friends", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4" do |t|
    t.string   "uid",                       null: false
    t.string   "screen_name",               null: false
    t.text     "user_info",   limit: 65535, null: false
    t.integer  "from_id",                   null: false
    t.datetime "created_at",                null: false
    t.index ["from_id"], name: "index_friends_on_from_id", using: :btree
  end

  create_table "friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "from_id",    null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_friendships_on_friend_uid", using: :btree
    t.index ["from_id", "friend_uid"], name: "index_friendships_on_from_id_and_friend_uid", unique: true, using: :btree
    t.index ["from_id"], name: "index_friendships_on_from_id", using: :btree
  end

  create_table "inactive_followerships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",     null: false
    t.bigint  "follower_uid", null: false
    t.integer "sequence",     null: false
    t.index ["follower_uid"], name: "index_inactive_followerships_on_follower_uid", using: :btree
    t.index ["from_uid"], name: "index_inactive_followerships_on_from_uid", using: :btree
  end

  create_table "inactive_friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_inactive_friendships_on_friend_uid", using: :btree
    t.index ["from_uid"], name: "index_inactive_friendships_on_from_uid", using: :btree
  end

  create_table "inactive_mutual_friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_inactive_mutual_friendships_on_friend_uid", using: :btree
    t.index ["from_uid"], name: "index_inactive_mutual_friendships_on_from_uid", using: :btree
  end

  create_table "jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "track_id",        default: -1, null: false
    t.integer  "user_id",         default: -1, null: false
    t.bigint   "uid",             default: -1, null: false
    t.string   "screen_name",     default: "", null: false
    t.integer  "twitter_user_id", default: -1, null: false
    t.bigint   "client_uid",      default: -1, null: false
    t.string   "jid",             default: "", null: false
    t.string   "parent_jid",      default: "", null: false
    t.string   "worker_class",    default: "", null: false
    t.string   "error_class",     default: "", null: false
    t.string   "error_message",   default: "", null: false
    t.datetime "enqueued_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["created_at"], name: "index_jobs_on_created_at", using: :btree
    t.index ["jid"], name: "index_jobs_on_jid", using: :btree
    t.index ["screen_name"], name: "index_jobs_on_screen_name", using: :btree
    t.index ["track_id"], name: "index_jobs_on_track_id", using: :btree
    t.index ["uid"], name: "index_jobs_on_uid", using: :btree
  end

  create_table "mentions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "uid",                       null: false
    t.string   "screen_name",               null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",                   null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["created_at"], name: "index_mentions_on_created_at", using: :btree
    t.index ["from_id"], name: "index_mentions_on_from_id", using: :btree
    t.index ["screen_name"], name: "index_mentions_on_screen_name", using: :btree
    t.index ["uid"], name: "index_mentions_on_uid", using: :btree
  end

  create_table "modal_open_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",  default: "", null: false
    t.integer  "user_id",     default: -1, null: false
    t.string   "via",         default: "", null: false
    t.string   "device_type", default: "", null: false
    t.string   "os",          default: "", null: false
    t.string   "browser",     default: "", null: false
    t.string   "user_agent",  default: "", null: false
    t.string   "referer",     default: "", null: false
    t.string   "referral",    default: "", null: false
    t.string   "channel",     default: "", null: false
    t.datetime "created_at",               null: false
    t.index ["created_at"], name: "index_modal_open_logs_on_created_at", using: :btree
  end

  create_table "mutual_friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_mutual_friendships_on_friend_uid", using: :btree
    t.index ["from_uid"], name: "index_mutual_friendships_on_from_uid", using: :btree
  end

  create_table "news_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",    null: false
    t.datetime "read_at"
    t.string   "message_id", null: false
    t.string   "token",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_news_reports_on_created_at", using: :btree
    t.index ["token"], name: "index_news_reports_on_token", unique: true, using: :btree
    t.index ["user_id"], name: "index_news_reports_on_user_id", using: :btree
  end

  create_table "not_found_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "screen_name", null: false
    t.bigint   "uid"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["created_at"], name: "index_not_found_users_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_not_found_users_on_screen_name", unique: true, using: :btree
  end

  create_table "notification_messages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",                                   null: false
    t.string   "uid",                                       null: false
    t.string   "screen_name",                               null: false
    t.boolean  "read",                      default: false, null: false
    t.datetime "read_at"
    t.string   "message_id",                default: "",    null: false
    t.text     "message",     limit: 65535,                 null: false
    t.string   "context",                   default: "",    null: false
    t.string   "medium",                    default: "",    null: false
    t.string   "token",                     default: "",    null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.index ["created_at"], name: "index_notification_messages_on_created_at", using: :btree
    t.index ["message_id"], name: "index_notification_messages_on_message_id", using: :btree
    t.index ["screen_name"], name: "index_notification_messages_on_screen_name", using: :btree
    t.index ["token"], name: "index_notification_messages_on_token", using: :btree
    t.index ["uid"], name: "index_notification_messages_on_uid", using: :btree
    t.index ["user_id"], name: "index_notification_messages_on_user_id", using: :btree
  end

  create_table "notification_settings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.boolean  "email",                 default: true, null: false
    t.boolean  "dm",                    default: true, null: false
    t.boolean  "news",                  default: true, null: false
    t.boolean  "search",                default: true, null: false
    t.boolean  "prompt_report",         default: true, null: false
    t.datetime "last_email_at"
    t.datetime "last_dm_at"
    t.datetime "last_news_at"
    t.datetime "search_sent_at"
    t.datetime "prompt_report_sent_at"
    t.integer  "user_id",                              null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.index ["user_id"], name: "index_notification_settings_on_user_id", unique: true, using: :btree
  end

  create_table "old_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint   "uid",                         null: false
    t.string   "screen_name",                 null: false
    t.boolean  "authorized",  default: false, null: false
    t.string   "secret",                      null: false
    t.string   "token",                       null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["created_at"], name: "index_old_users_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_old_users_on_screen_name", using: :btree
    t.index ["uid"], name: "index_old_users_on_uid", unique: true, using: :btree
  end

  create_table "one_sided_followerships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",     null: false
    t.bigint  "follower_uid", null: false
    t.integer "sequence",     null: false
    t.index ["follower_uid"], name: "index_one_sided_followerships_on_follower_uid", using: :btree
    t.index ["from_uid"], name: "index_one_sided_followerships_on_from_uid", using: :btree
  end

  create_table "one_sided_friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_one_sided_friendships_on_friend_uid", using: :btree
    t.index ["from_uid"], name: "index_one_sided_friendships_on_from_uid", using: :btree
  end

  create_table "page_cache_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",  default: "", null: false
    t.integer  "user_id",     default: -1, null: false
    t.string   "context",     default: "", null: false
    t.string   "device_type", default: "", null: false
    t.string   "os",          default: "", null: false
    t.string   "browser",     default: "", null: false
    t.string   "user_agent",  default: "", null: false
    t.string   "referer",     default: "", null: false
    t.string   "referral",    default: "", null: false
    t.string   "channel",     default: "", null: false
    t.datetime "created_at",               null: false
    t.index ["created_at"], name: "index_page_cache_logs_on_created_at", using: :btree
  end

  create_table "polling_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",             default: "",    null: false
    t.integer  "user_id",                default: -1,    null: false
    t.string   "uid",                    default: "",    null: false
    t.string   "screen_name",            default: "",    null: false
    t.string   "action",                 default: "",    null: false
    t.boolean  "status",                 default: false, null: false
    t.float    "time",        limit: 24, default: 0.0,   null: false
    t.integer  "retry_count",            default: 0,     null: false
    t.string   "device_type",            default: "",    null: false
    t.string   "os",                     default: "",    null: false
    t.string   "browser",                default: "",    null: false
    t.string   "user_agent",             default: "",    null: false
    t.string   "referer",                default: "",    null: false
    t.string   "referral",               default: "",    null: false
    t.string   "channel",                default: "",    null: false
    t.datetime "created_at",                             null: false
    t.index ["created_at"], name: "index_polling_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_polling_logs_on_screen_name", using: :btree
    t.index ["session_id"], name: "index_polling_logs_on_session_id", using: :btree
    t.index ["uid"], name: "index_polling_logs_on_uid", using: :btree
    t.index ["user_id"], name: "index_polling_logs_on_user_id", using: :btree
  end

  create_table "prompt_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",                    null: false
    t.datetime "read_at"
    t.text     "changes_json", limit: 65535, null: false
    t.string   "message_id",                 null: false
    t.string   "token",                      null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["created_at"], name: "index_prompt_reports_on_created_at", using: :btree
    t.index ["token"], name: "index_prompt_reports_on_token", unique: true, using: :btree
    t.index ["user_id"], name: "index_prompt_reports_on_user_id", using: :btree
  end

  create_table "scores", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint   "uid",                          null: false
    t.string   "klout_id",                     null: false
    t.float    "klout_score",    limit: 53,    null: false
    t.text     "influence_json", limit: 65535, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["created_at"], name: "index_scores_on_created_at", using: :btree
    t.index ["uid"], name: "index_scores_on_uid", unique: true, using: :btree
  end

  create_table "search_error_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",  default: "", null: false
    t.integer  "user_id",     default: -1, null: false
    t.string   "uid",         default: "", null: false
    t.string   "screen_name", default: "", null: false
    t.string   "location",    default: "", null: false
    t.string   "message",     default: "", null: false
    t.string   "controller",  default: "", null: false
    t.string   "action",      default: "", null: false
    t.string   "method",      default: "", null: false
    t.string   "path",        default: "", null: false
    t.string   "via",         default: "", null: false
    t.string   "device_type", default: "", null: false
    t.string   "os",          default: "", null: false
    t.string   "browser",     default: "", null: false
    t.string   "user_agent",  default: "", null: false
    t.string   "referer",     default: "", null: false
    t.datetime "created_at",               null: false
    t.index ["created_at"], name: "index_search_error_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_search_error_logs_on_screen_name", using: :btree
    t.index ["session_id"], name: "index_search_error_logs_on_session_id", using: :btree
    t.index ["uid"], name: "index_search_error_logs_on_uid", using: :btree
    t.index ["user_id"], name: "index_search_error_logs_on_user_id", using: :btree
  end

  create_table "search_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id", default: "", null: false
    t.integer  "user_id",                 null: false
    t.bigint   "uid",                     null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["created_at"], name: "index_search_histories_on_created_at", using: :btree
    t.index ["session_id"], name: "index_search_histories_on_session_id", using: :btree
    t.index ["user_id"], name: "index_search_histories_on_user_id", using: :btree
  end

  create_table "search_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",  default: "",    null: false
    t.integer  "user_id",     default: -1,    null: false
    t.string   "uid",         default: "",    null: false
    t.string   "screen_name", default: "",    null: false
    t.string   "controller",  default: "",    null: false
    t.string   "action",      default: "",    null: false
    t.boolean  "cache_hit",   default: false, null: false
    t.boolean  "ego_surfing", default: false, null: false
    t.string   "method",      default: "",    null: false
    t.string   "path",        default: "",    null: false
    t.string   "via",         default: "",    null: false
    t.string   "device_type", default: "",    null: false
    t.string   "os",          default: "",    null: false
    t.string   "browser",     default: "",    null: false
    t.string   "user_agent",  default: "",    null: false
    t.string   "referer",     default: "",    null: false
    t.string   "referral",    default: "",    null: false
    t.string   "channel",     default: "",    null: false
    t.boolean  "first_time",  default: false, null: false
    t.boolean  "landing",     default: false, null: false
    t.boolean  "bouncing",    default: false, null: false
    t.boolean  "exiting",     default: false, null: false
    t.string   "medium",      default: "",    null: false
    t.string   "ab_test",     default: "",    null: false
    t.datetime "created_at",                  null: false
    t.index ["action"], name: "index_search_logs_on_action", using: :btree
    t.index ["created_at"], name: "index_search_logs_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_search_logs_on_screen_name", using: :btree
    t.index ["session_id"], name: "index_search_logs_on_session_id", using: :btree
    t.index ["uid", "action"], name: "index_search_logs_on_uid_and_action", using: :btree
    t.index ["uid"], name: "index_search_logs_on_uid", using: :btree
    t.index ["user_id"], name: "index_search_logs_on_user_id", using: :btree
  end

  create_table "search_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",    null: false
    t.datetime "read_at"
    t.string   "message_id", null: false
    t.string   "token",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_search_reports_on_created_at", using: :btree
    t.index ["token"], name: "index_search_reports_on_token", unique: true, using: :btree
    t.index ["user_id"], name: "index_search_reports_on_user_id", using: :btree
  end

  create_table "search_results", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "uid",                       null: false
    t.string   "screen_name",               null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",                   null: false
    t.string   "query",                     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["created_at"], name: "index_search_results_on_created_at", using: :btree
    t.index ["from_id"], name: "index_search_results_on_from_id", using: :btree
    t.index ["screen_name"], name: "index_search_results_on_screen_name", using: :btree
    t.index ["uid"], name: "index_search_results_on_uid", using: :btree
  end

  create_table "sign_in_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",  default: "",    null: false
    t.integer  "user_id",     default: -1,    null: false
    t.string   "uid",         default: "-1",  null: false
    t.string   "screen_name", default: "",    null: false
    t.string   "context",     default: "",    null: false
    t.boolean  "follow",      default: false, null: false
    t.boolean  "tweet",       default: false, null: false
    t.string   "via",         default: "",    null: false
    t.string   "device_type", default: "",    null: false
    t.string   "os",          default: "",    null: false
    t.string   "browser",     default: "",    null: false
    t.string   "user_agent",  default: "",    null: false
    t.string   "referer",     default: "",    null: false
    t.string   "referral",    default: "",    null: false
    t.string   "channel",     default: "",    null: false
    t.string   "ab_test",     default: "",    null: false
    t.datetime "created_at",                  null: false
    t.index ["created_at"], name: "index_sign_in_logs_on_created_at", using: :btree
    t.index ["user_id"], name: "index_sign_in_logs_on_user_id", using: :btree
  end

  create_table "statuses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4" do |t|
    t.string   "uid",                       null: false
    t.string   "screen_name",               null: false
    t.text     "status_info", limit: 65535, null: false
    t.integer  "from_id",                   null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["created_at"], name: "index_statuses_on_created_at", using: :btree
    t.index ["from_id"], name: "index_statuses_on_from_id", using: :btree
    t.index ["screen_name"], name: "index_statuses_on_screen_name", using: :btree
    t.index ["uid"], name: "index_statuses_on_uid", using: :btree
  end

  create_table "tracks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",  default: "",    null: false
    t.integer  "user_id",     default: -1,    null: false
    t.bigint   "uid",         default: -1,    null: false
    t.string   "screen_name", default: "",    null: false
    t.string   "controller",  default: "",    null: false
    t.string   "action",      default: "",    null: false
    t.boolean  "auto",        default: false, null: false
    t.string   "via",         default: "",    null: false
    t.string   "device_type", default: "",    null: false
    t.string   "os",          default: "",    null: false
    t.string   "browser",     default: "",    null: false
    t.string   "user_agent",  default: "",    null: false
    t.string   "referer",     default: "",    null: false
    t.string   "referral",    default: "",    null: false
    t.string   "channel",     default: "",    null: false
    t.string   "medium",      default: "",    null: false
    t.datetime "created_at",                  null: false
    t.index ["created_at"], name: "index_tracks_on_created_at", using: :btree
  end

  create_table "twitter_db_followerships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "user_uid",     null: false
    t.bigint  "follower_uid", null: false
    t.integer "sequence",     null: false
    t.index ["follower_uid"], name: "index_twitter_db_followerships_on_follower_uid", using: :btree
    t.index ["user_uid", "follower_uid"], name: "index_twitter_db_followerships_on_user_uid_and_follower_uid", unique: true, using: :btree
    t.index ["user_uid"], name: "index_twitter_db_followerships_on_user_uid", using: :btree
  end

  create_table "twitter_db_friendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "user_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_twitter_db_friendships_on_friend_uid", using: :btree
    t.index ["user_uid", "friend_uid"], name: "index_twitter_db_friendships_on_user_uid_and_friend_uid", unique: true, using: :btree
    t.index ["user_uid"], name: "index_twitter_db_friendships_on_user_uid", using: :btree
  end

  create_table "twitter_db_users", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4" do |t|
    t.bigint   "uid",                                      null: false
    t.string   "screen_name",                              null: false
    t.integer  "friends_size",                 default: 0, null: false
    t.integer  "followers_size",               default: 0, null: false
    t.text     "user_info",      limit: 65535,             null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.index ["created_at"], name: "index_twitter_db_users_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_twitter_db_users_on_screen_name", using: :btree
    t.index ["uid"], name: "index_twitter_db_users_on_uid", unique: true, using: :btree
  end

  create_table "twitter_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "uid",                                       null: false
    t.string   "screen_name",                               null: false
    t.integer  "friends_size",                 default: 0,  null: false
    t.integer  "followers_size",               default: 0,  null: false
    t.text     "user_info",      limit: 65535,              null: false
    t.integer  "search_count",                 default: 0,  null: false
    t.integer  "update_count",                 default: 0,  null: false
    t.integer  "user_id",                      default: -1, null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.index ["created_at"], name: "index_twitter_users_on_created_at", using: :btree
    t.index ["screen_name", "user_id"], name: "index_twitter_users_on_screen_name_and_user_id", using: :btree
    t.index ["screen_name"], name: "index_twitter_users_on_screen_name", using: :btree
    t.index ["uid", "user_id"], name: "index_twitter_users_on_uid_and_user_id", using: :btree
    t.index ["uid"], name: "index_twitter_users_on_uid", using: :btree
  end

  create_table "unfollow_requests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",                    null: false
    t.bigint   "uid",                        null: false
    t.datetime "finished_at"
    t.string   "error_class",   default: "", null: false
    t.string   "error_message", default: "", null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["created_at"], name: "index_unfollow_requests_on_created_at", using: :btree
    t.index ["user_id"], name: "index_unfollow_requests_on_user_id", using: :btree
  end

  create_table "unfollowerships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",     null: false
    t.bigint  "follower_uid", null: false
    t.integer "sequence",     null: false
    t.index ["follower_uid"], name: "index_unfollowerships_on_follower_uid", using: :btree
    t.index ["from_uid"], name: "index_unfollowerships_on_from_uid", using: :btree
  end

  create_table "unfriendships", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint  "from_uid",   null: false
    t.bigint  "friend_uid", null: false
    t.integer "sequence",   null: false
    t.index ["friend_uid"], name: "index_unfriendships_on_friend_uid", using: :btree
    t.index ["from_uid"], name: "index_unfriendships_on_from_uid", using: :btree
  end

  create_table "usage_stats", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4" do |t|
    t.bigint   "uid",                               null: false
    t.text     "wday_json",           limit: 65535, null: false
    t.text     "wday_drilldown_json", limit: 65535, null: false
    t.text     "hour_json",           limit: 65535, null: false
    t.text     "hour_drilldown_json", limit: 65535, null: false
    t.text     "usage_time_json",     limit: 65535, null: false
    t.text     "breakdown_json",      limit: 65535, null: false
    t.text     "hashtags_json",       limit: 65535, null: false
    t.text     "mentions_json",       limit: 65535, null: false
    t.text     "tweet_clusters_json", limit: 65535, null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.index ["created_at"], name: "index_usage_stats_on_created_at", using: :btree
    t.index ["uid"], name: "index_usage_stats_on_uid", unique: true, using: :btree
  end

  create_table "user_engagement_stats", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.datetime "date",                       null: false
    t.integer  "total",          default: 0, null: false
    t.integer  "1_days",         default: 0, null: false
    t.integer  "2_days",         default: 0, null: false
    t.integer  "3_days",         default: 0, null: false
    t.integer  "4_days",         default: 0, null: false
    t.integer  "5_days",         default: 0, null: false
    t.integer  "6_days",         default: 0, null: false
    t.integer  "7_days",         default: 0, null: false
    t.integer  "8_days",         default: 0, null: false
    t.integer  "9_days",         default: 0, null: false
    t.integer  "10_days",        default: 0, null: false
    t.integer  "11_days",        default: 0, null: false
    t.integer  "12_days",        default: 0, null: false
    t.integer  "13_days",        default: 0, null: false
    t.integer  "14_days",        default: 0, null: false
    t.integer  "15_days",        default: 0, null: false
    t.integer  "16_days",        default: 0, null: false
    t.integer  "17_days",        default: 0, null: false
    t.integer  "18_days",        default: 0, null: false
    t.integer  "19_days",        default: 0, null: false
    t.integer  "20_days",        default: 0, null: false
    t.integer  "21_days",        default: 0, null: false
    t.integer  "22_days",        default: 0, null: false
    t.integer  "23_days",        default: 0, null: false
    t.integer  "24_days",        default: 0, null: false
    t.integer  "25_days",        default: 0, null: false
    t.integer  "26_days",        default: 0, null: false
    t.integer  "27_days",        default: 0, null: false
    t.integer  "28_days",        default: 0, null: false
    t.integer  "29_days",        default: 0, null: false
    t.integer  "30_days",        default: 0, null: false
    t.integer  "before_1_days",  default: 0, null: false
    t.integer  "before_2_days",  default: 0, null: false
    t.integer  "before_3_days",  default: 0, null: false
    t.integer  "before_4_days",  default: 0, null: false
    t.integer  "before_5_days",  default: 0, null: false
    t.integer  "before_6_days",  default: 0, null: false
    t.integer  "before_7_days",  default: 0, null: false
    t.integer  "before_8_days",  default: 0, null: false
    t.integer  "before_9_days",  default: 0, null: false
    t.integer  "before_10_days", default: 0, null: false
    t.integer  "before_11_days", default: 0, null: false
    t.integer  "before_12_days", default: 0, null: false
    t.integer  "before_13_days", default: 0, null: false
    t.integer  "before_14_days", default: 0, null: false
    t.integer  "before_15_days", default: 0, null: false
    t.integer  "before_16_days", default: 0, null: false
    t.integer  "before_17_days", default: 0, null: false
    t.integer  "before_18_days", default: 0, null: false
    t.integer  "before_19_days", default: 0, null: false
    t.integer  "before_20_days", default: 0, null: false
    t.integer  "before_21_days", default: 0, null: false
    t.integer  "before_22_days", default: 0, null: false
    t.integer  "before_23_days", default: 0, null: false
    t.integer  "before_24_days", default: 0, null: false
    t.integer  "before_25_days", default: 0, null: false
    t.integer  "before_26_days", default: 0, null: false
    t.integer  "before_27_days", default: 0, null: false
    t.integer  "before_28_days", default: 0, null: false
    t.integer  "before_29_days", default: 0, null: false
    t.integer  "before_30_days", default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["date"], name: "index_user_engagement_stats_on_date", unique: true, using: :btree
  end

  create_table "user_retention_stats", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.datetime "date",                      null: false
    t.integer  "total",         default: 0, null: false
    t.integer  "1_days",        default: 0, null: false
    t.integer  "2_days",        default: 0, null: false
    t.integer  "3_days",        default: 0, null: false
    t.integer  "4_days",        default: 0, null: false
    t.integer  "5_days",        default: 0, null: false
    t.integer  "6_days",        default: 0, null: false
    t.integer  "7_days",        default: 0, null: false
    t.integer  "8_days",        default: 0, null: false
    t.integer  "9_days",        default: 0, null: false
    t.integer  "10_days",       default: 0, null: false
    t.integer  "11_days",       default: 0, null: false
    t.integer  "12_days",       default: 0, null: false
    t.integer  "13_days",       default: 0, null: false
    t.integer  "14_days",       default: 0, null: false
    t.integer  "15_days",       default: 0, null: false
    t.integer  "16_days",       default: 0, null: false
    t.integer  "17_days",       default: 0, null: false
    t.integer  "18_days",       default: 0, null: false
    t.integer  "19_days",       default: 0, null: false
    t.integer  "20_days",       default: 0, null: false
    t.integer  "21_days",       default: 0, null: false
    t.integer  "22_days",       default: 0, null: false
    t.integer  "23_days",       default: 0, null: false
    t.integer  "24_days",       default: 0, null: false
    t.integer  "25_days",       default: 0, null: false
    t.integer  "26_days",       default: 0, null: false
    t.integer  "27_days",       default: 0, null: false
    t.integer  "28_days",       default: 0, null: false
    t.integer  "29_days",       default: 0, null: false
    t.integer  "30_days",       default: 0, null: false
    t.integer  "after_1_days",  default: 0, null: false
    t.integer  "after_2_days",  default: 0, null: false
    t.integer  "after_3_days",  default: 0, null: false
    t.integer  "after_4_days",  default: 0, null: false
    t.integer  "after_5_days",  default: 0, null: false
    t.integer  "after_6_days",  default: 0, null: false
    t.integer  "after_7_days",  default: 0, null: false
    t.integer  "after_8_days",  default: 0, null: false
    t.integer  "after_9_days",  default: 0, null: false
    t.integer  "after_10_days", default: 0, null: false
    t.integer  "after_11_days", default: 0, null: false
    t.integer  "after_12_days", default: 0, null: false
    t.integer  "after_13_days", default: 0, null: false
    t.integer  "after_14_days", default: 0, null: false
    t.integer  "after_15_days", default: 0, null: false
    t.integer  "after_16_days", default: 0, null: false
    t.integer  "after_17_days", default: 0, null: false
    t.integer  "after_18_days", default: 0, null: false
    t.integer  "after_19_days", default: 0, null: false
    t.integer  "after_20_days", default: 0, null: false
    t.integer  "after_21_days", default: 0, null: false
    t.integer  "after_22_days", default: 0, null: false
    t.integer  "after_23_days", default: 0, null: false
    t.integer  "after_24_days", default: 0, null: false
    t.integer  "after_25_days", default: 0, null: false
    t.integer  "after_26_days", default: 0, null: false
    t.integer  "after_27_days", default: 0, null: false
    t.integer  "after_28_days", default: 0, null: false
    t.integer  "after_29_days", default: 0, null: false
    t.integer  "after_30_days", default: 0, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["date"], name: "index_user_retention_stats_on_date", unique: true, using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.bigint   "uid",                             null: false
    t.string   "screen_name",                     null: false
    t.boolean  "authorized",       default: true, null: false
    t.string   "secret",                          null: false
    t.string   "token",                           null: false
    t.string   "email",            default: "",   null: false
    t.datetime "first_access_at"
    t.datetime "last_access_at"
    t.datetime "first_search_at"
    t.datetime "last_search_at"
    t.datetime "first_sign_in_at"
    t.datetime "last_sign_in_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["created_at"], name: "index_users_on_created_at", using: :btree
    t.index ["screen_name"], name: "index_users_on_screen_name", using: :btree
    t.index ["uid"], name: "index_users_on_uid", unique: true, using: :btree
  end

  create_table "visitor_engagement_stats", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.datetime "date",                       null: false
    t.integer  "total",          default: 0, null: false
    t.integer  "1_days",         default: 0, null: false
    t.integer  "2_days",         default: 0, null: false
    t.integer  "3_days",         default: 0, null: false
    t.integer  "4_days",         default: 0, null: false
    t.integer  "5_days",         default: 0, null: false
    t.integer  "6_days",         default: 0, null: false
    t.integer  "7_days",         default: 0, null: false
    t.integer  "8_days",         default: 0, null: false
    t.integer  "9_days",         default: 0, null: false
    t.integer  "10_days",        default: 0, null: false
    t.integer  "11_days",        default: 0, null: false
    t.integer  "12_days",        default: 0, null: false
    t.integer  "13_days",        default: 0, null: false
    t.integer  "14_days",        default: 0, null: false
    t.integer  "15_days",        default: 0, null: false
    t.integer  "16_days",        default: 0, null: false
    t.integer  "17_days",        default: 0, null: false
    t.integer  "18_days",        default: 0, null: false
    t.integer  "19_days",        default: 0, null: false
    t.integer  "20_days",        default: 0, null: false
    t.integer  "21_days",        default: 0, null: false
    t.integer  "22_days",        default: 0, null: false
    t.integer  "23_days",        default: 0, null: false
    t.integer  "24_days",        default: 0, null: false
    t.integer  "25_days",        default: 0, null: false
    t.integer  "26_days",        default: 0, null: false
    t.integer  "27_days",        default: 0, null: false
    t.integer  "28_days",        default: 0, null: false
    t.integer  "29_days",        default: 0, null: false
    t.integer  "30_days",        default: 0, null: false
    t.integer  "before_1_days",  default: 0, null: false
    t.integer  "before_2_days",  default: 0, null: false
    t.integer  "before_3_days",  default: 0, null: false
    t.integer  "before_4_days",  default: 0, null: false
    t.integer  "before_5_days",  default: 0, null: false
    t.integer  "before_6_days",  default: 0, null: false
    t.integer  "before_7_days",  default: 0, null: false
    t.integer  "before_8_days",  default: 0, null: false
    t.integer  "before_9_days",  default: 0, null: false
    t.integer  "before_10_days", default: 0, null: false
    t.integer  "before_11_days", default: 0, null: false
    t.integer  "before_12_days", default: 0, null: false
    t.integer  "before_13_days", default: 0, null: false
    t.integer  "before_14_days", default: 0, null: false
    t.integer  "before_15_days", default: 0, null: false
    t.integer  "before_16_days", default: 0, null: false
    t.integer  "before_17_days", default: 0, null: false
    t.integer  "before_18_days", default: 0, null: false
    t.integer  "before_19_days", default: 0, null: false
    t.integer  "before_20_days", default: 0, null: false
    t.integer  "before_21_days", default: 0, null: false
    t.integer  "before_22_days", default: 0, null: false
    t.integer  "before_23_days", default: 0, null: false
    t.integer  "before_24_days", default: 0, null: false
    t.integer  "before_25_days", default: 0, null: false
    t.integer  "before_26_days", default: 0, null: false
    t.integer  "before_27_days", default: 0, null: false
    t.integer  "before_28_days", default: 0, null: false
    t.integer  "before_29_days", default: 0, null: false
    t.integer  "before_30_days", default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["date"], name: "index_visitor_engagement_stats_on_date", unique: true, using: :btree
  end

  create_table "visitor_retention_stats", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.datetime "date",                      null: false
    t.integer  "total",         default: 0, null: false
    t.integer  "1_days",        default: 0, null: false
    t.integer  "2_days",        default: 0, null: false
    t.integer  "3_days",        default: 0, null: false
    t.integer  "4_days",        default: 0, null: false
    t.integer  "5_days",        default: 0, null: false
    t.integer  "6_days",        default: 0, null: false
    t.integer  "7_days",        default: 0, null: false
    t.integer  "8_days",        default: 0, null: false
    t.integer  "9_days",        default: 0, null: false
    t.integer  "10_days",       default: 0, null: false
    t.integer  "11_days",       default: 0, null: false
    t.integer  "12_days",       default: 0, null: false
    t.integer  "13_days",       default: 0, null: false
    t.integer  "14_days",       default: 0, null: false
    t.integer  "15_days",       default: 0, null: false
    t.integer  "16_days",       default: 0, null: false
    t.integer  "17_days",       default: 0, null: false
    t.integer  "18_days",       default: 0, null: false
    t.integer  "19_days",       default: 0, null: false
    t.integer  "20_days",       default: 0, null: false
    t.integer  "21_days",       default: 0, null: false
    t.integer  "22_days",       default: 0, null: false
    t.integer  "23_days",       default: 0, null: false
    t.integer  "24_days",       default: 0, null: false
    t.integer  "25_days",       default: 0, null: false
    t.integer  "26_days",       default: 0, null: false
    t.integer  "27_days",       default: 0, null: false
    t.integer  "28_days",       default: 0, null: false
    t.integer  "29_days",       default: 0, null: false
    t.integer  "30_days",       default: 0, null: false
    t.integer  "after_1_days",  default: 0, null: false
    t.integer  "after_2_days",  default: 0, null: false
    t.integer  "after_3_days",  default: 0, null: false
    t.integer  "after_4_days",  default: 0, null: false
    t.integer  "after_5_days",  default: 0, null: false
    t.integer  "after_6_days",  default: 0, null: false
    t.integer  "after_7_days",  default: 0, null: false
    t.integer  "after_8_days",  default: 0, null: false
    t.integer  "after_9_days",  default: 0, null: false
    t.integer  "after_10_days", default: 0, null: false
    t.integer  "after_11_days", default: 0, null: false
    t.integer  "after_12_days", default: 0, null: false
    t.integer  "after_13_days", default: 0, null: false
    t.integer  "after_14_days", default: 0, null: false
    t.integer  "after_15_days", default: 0, null: false
    t.integer  "after_16_days", default: 0, null: false
    t.integer  "after_17_days", default: 0, null: false
    t.integer  "after_18_days", default: 0, null: false
    t.integer  "after_19_days", default: 0, null: false
    t.integer  "after_20_days", default: 0, null: false
    t.integer  "after_21_days", default: 0, null: false
    t.integer  "after_22_days", default: 0, null: false
    t.integer  "after_23_days", default: 0, null: false
    t.integer  "after_24_days", default: 0, null: false
    t.integer  "after_25_days", default: 0, null: false
    t.integer  "after_26_days", default: 0, null: false
    t.integer  "after_27_days", default: 0, null: false
    t.integer  "after_28_days", default: 0, null: false
    t.integer  "after_29_days", default: 0, null: false
    t.integer  "after_30_days", default: 0, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["date"], name: "index_visitor_retention_stats_on_date", unique: true, using: :btree
  end

  create_table "visitors", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string   "session_id",                     null: false
    t.integer  "user_id",         default: -1,   null: false
    t.string   "uid",             default: "-1", null: false
    t.string   "screen_name",     default: "",   null: false
    t.datetime "first_access_at"
    t.datetime "last_access_at"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["created_at"], name: "index_visitors_on_created_at", using: :btree
    t.index ["first_access_at"], name: "index_visitors_on_first_access_at", using: :btree
    t.index ["last_access_at"], name: "index_visitors_on_last_access_at", using: :btree
    t.index ["screen_name"], name: "index_visitors_on_screen_name", using: :btree
    t.index ["session_id"], name: "index_visitors_on_session_id", unique: true, using: :btree
    t.index ["uid"], name: "index_visitors_on_uid", using: :btree
    t.index ["user_id"], name: "index_visitors_on_user_id", using: :btree
  end

  create_table "welcome_messages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer  "user_id",    null: false
    t.datetime "read_at"
    t.string   "message_id", null: false
    t.string   "token",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_welcome_messages_on_created_at", using: :btree
    t.index ["token"], name: "index_welcome_messages_on_token", unique: true, using: :btree
    t.index ["user_id"], name: "index_welcome_messages_on_user_id", using: :btree
  end

  add_foreign_key "twitter_db_followerships", "twitter_db_users", column: "follower_uid", primary_key: "uid"
  add_foreign_key "twitter_db_followerships", "twitter_db_users", column: "user_uid", primary_key: "uid"
  add_foreign_key "twitter_db_friendships", "twitter_db_users", column: "friend_uid", primary_key: "uid"
  add_foreign_key "twitter_db_friendships", "twitter_db_users", column: "user_uid", primary_key: "uid"
end
