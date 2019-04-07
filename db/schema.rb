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

ActiveRecord::Schema.define(version: 2019_04_07_014044) do

  create_table "ahoy_events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.json "properties"
    t.timestamp "time", null: false
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["time"], name: "index_ahoy_events_on_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.timestamp "started_at", null: false
    t.index ["started_at"], name: "index_ahoy_visits_on_started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "audience_insights", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.text "categories_text", null: false
    t.text "friends_text", null: false
    t.text "followers_text", null: false
    t.text "new_friends_text", null: false
    t.text "new_followers_text", null: false
    t.text "unfriends_text", null: false
    t.text "unfollowers_text", null: false
    t.text "new_unfriends_text", null: false
    t.text "new_unfollowers_text", null: false
    t.text "tweets_categories_text", null: false
    t.text "tweets_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_audience_insights_on_created_at"
    t.index ["uid"], name: "index_audience_insights_on_uid", unique: true
  end

  create_table "background_force_update_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "-1", null: false
    t.string "screen_name", default: "", null: false
    t.string "action", default: "", null: false
    t.string "bot_uid", default: "-1", null: false
    t.boolean "status", default: false, null: false
    t.string "reason", default: "", null: false
    t.text "message", null: false
    t.integer "call_count", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.string "medium", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_background_force_update_logs_on_created_at"
    t.index ["screen_name"], name: "index_background_force_update_logs_on_screen_name"
    t.index ["uid"], name: "index_background_force_update_logs_on_uid"
    t.index ["user_id"], name: "index_background_force_update_logs_on_user_id"
  end

  create_table "background_search_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "-1", null: false
    t.string "screen_name", default: "", null: false
    t.string "action", default: "", null: false
    t.string "bot_uid", default: "-1", null: false
    t.boolean "auto", default: false, null: false
    t.boolean "status", default: false, null: false
    t.string "reason", default: "", null: false
    t.text "message", null: false
    t.integer "call_count", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.string "medium", default: "", null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "enqueued_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_background_search_logs_on_created_at"
    t.index ["screen_name"], name: "index_background_search_logs_on_screen_name"
    t.index ["uid"], name: "index_background_search_logs_on_uid"
    t.index ["user_id", "status"], name: "index_background_search_logs_on_user_id_and_status"
    t.index ["user_id"], name: "index_background_search_logs_on_user_id"
  end

  create_table "background_update_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "-1", null: false
    t.string "screen_name", default: "", null: false
    t.string "bot_uid", default: "-1", null: false
    t.boolean "status", default: false, null: false
    t.string "reason", default: "", null: false
    t.text "message", null: false
    t.integer "call_count", default: -1, null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_background_update_logs_on_created_at"
    t.index ["screen_name"], name: "index_background_update_logs_on_screen_name"
    t.index ["uid"], name: "index_background_update_logs_on_uid"
  end

  create_table "blacklist_words", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_blacklist_words_on_created_at"
    t.index ["text"], name: "index_blacklist_words_on_text", unique: true
  end

  create_table "block_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_block_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_block_friendships_on_from_uid"
  end

  create_table "blocked_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name"
    t.bigint "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_blocked_users_on_created_at"
    t.index ["uid"], name: "index_blocked_users_on_uid", unique: true
  end

  create_table "bots", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.string "secret", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["screen_name"], name: "index_bots_on_screen_name"
    t.index ["uid"], name: "index_bots_on_uid", unique: true
  end

  create_table "cache_directories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "dir", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dir"], name: "index_cache_directories_on_dir", unique: true
    t.index ["name"], name: "index_cache_directories_on_name", unique: true
  end

  create_table "close_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_close_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_close_friendships_on_from_uid"
  end

  create_table "crawler_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "controller", default: "", null: false
    t.string "action", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "ip", default: "", null: false
    t.string "method", default: "", null: false
    t.string "path", default: "", null: false
    t.integer "status", default: -1, null: false
    t.string "user_agent", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_crawler_logs_on_created_at"
  end

  create_table "create_follow_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "request_id"
    t.bigint "uid"
    t.boolean "status", default: false, null: false
    t.string "error_class"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_follow_logs_on_created_at"
    t.index ["request_id"], name: "index_create_follow_logs_on_request_id"
    t.index ["user_id"], name: "index_create_follow_logs_on_user_id"
  end

  create_table "create_notification_message_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.boolean "status", default: false, null: false
    t.string "reason", default: "", null: false
    t.text "message", null: false
    t.string "context", default: "", null: false
    t.string "medium", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_notification_message_logs_on_created_at"
    t.index ["screen_name"], name: "index_create_notification_message_logs_on_screen_name"
    t.index ["uid"], name: "index_create_notification_message_logs_on_uid"
    t.index ["user_id", "status"], name: "index_create_notification_message_logs_on_user_id_and_status"
    t.index ["user_id"], name: "index_create_notification_message_logs_on_user_id"
  end

  create_table "create_prompt_report_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.integer "request_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.boolean "status", default: false, null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_prompt_report_logs_on_created_at"
    t.index ["request_id"], name: "index_create_prompt_report_logs_on_request_id"
    t.index ["screen_name"], name: "index_create_prompt_report_logs_on_screen_name"
    t.index ["uid"], name: "index_create_prompt_report_logs_on_uid"
  end

  create_table "create_prompt_report_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_create_prompt_report_requests_on_created_at"
    t.index ["user_id"], name: "index_create_prompt_report_requests_on_user_id"
  end

  create_table "create_relationship_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "-1", null: false
    t.string "screen_name", default: "", null: false
    t.string "bot_uid", default: "-1", null: false
    t.boolean "status", default: false, null: false
    t.string "reason", default: "", null: false
    t.text "message", null: false
    t.integer "call_count", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_relationship_logs_on_created_at"
    t.index ["screen_name"], name: "index_create_relationship_logs_on_screen_name"
    t.index ["uid"], name: "index_create_relationship_logs_on_uid"
    t.index ["user_id"], name: "index_create_relationship_logs_on_user_id"
  end

  create_table "create_twitter_user_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "request_id"
    t.bigint "uid"
    t.boolean "status", default: false, null: false
    t.string "error_class"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_twitter_user_logs_on_created_at"
    t.index ["request_id"], name: "index_create_twitter_user_logs_on_request_id"
    t.index ["uid"], name: "index_create_twitter_user_logs_on_uid"
    t.index ["user_id"], name: "index_create_twitter_user_logs_on_user_id"
  end

  create_table "create_twitter_user_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id"
    t.integer "user_id", null: false
    t.bigint "uid", null: false
    t.integer "twitter_user_id"
    t.datetime "finished_at"
    t.bigint "ahoy_visit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_create_twitter_user_requests_on_created_at"
    t.index ["user_id"], name: "index_create_twitter_user_requests_on_user_id"
  end

  create_table "create_unfollow_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "request_id"
    t.bigint "uid"
    t.boolean "status", default: false, null: false
    t.string "error_class"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_unfollow_logs_on_created_at"
    t.index ["request_id"], name: "index_create_unfollow_logs_on_request_id"
    t.index ["user_id"], name: "index_create_unfollow_logs_on_user_id"
  end

  create_table "delete_tweets_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.integer "request_id", default: -1, null: false
    t.boolean "status", default: false, null: false
    t.string "message", default: "", null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_delete_tweets_logs_on_created_at"
  end

  create_table "delete_tweets_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_delete_tweets_requests_on_created_at"
    t.index ["user_id"], name: "index_delete_tweets_requests_on_user_id"
  end

  create_table "egotter_followers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name", null: false
    t.bigint "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_egotter_followers_on_created_at"
    t.index ["uid"], name: "index_egotter_followers_on_uid", unique: true
  end

  create_table "favorite_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_favorite_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_favorite_friendships_on_from_uid"
  end

  create_table "favorites", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "status_info", null: false
    t.integer "from_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_favorites_on_created_at"
    t.index ["from_id"], name: "index_favorites_on_from_id"
    t.index ["screen_name"], name: "index_favorites_on_screen_name"
    t.index ["uid"], name: "index_favorites_on_uid"
  end

  create_table "follow_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "uid", null: false
    t.datetime "finished_at"
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_follow_requests_on_created_at"
    t.index ["user_id"], name: "index_follow_requests_on_user_id"
  end

  create_table "followers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "user_info", null: false
    t.integer "from_id", null: false
    t.datetime "created_at", null: false
    t.index ["from_id"], name: "index_followers_on_from_id"
  end

  create_table "followerships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "from_id", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_followerships_on_follower_uid"
    t.index ["from_id", "follower_uid"], name: "index_followerships_on_from_id_and_follower_uid", unique: true
    t.index ["from_id"], name: "index_followerships_on_from_id"
  end

  create_table "forbidden_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name", null: false
    t.bigint "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_forbidden_users_on_created_at"
    t.index ["screen_name"], name: "index_forbidden_users_on_screen_name", unique: true
  end

  create_table "friends", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "user_info", null: false
    t.integer "from_id", null: false
    t.datetime "created_at", null: false
    t.index ["from_id"], name: "index_friends_on_from_id"
  end

  create_table "friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "from_id", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_friendships_on_friend_uid"
    t.index ["from_id", "friend_uid"], name: "index_friendships_on_from_id_and_friend_uid", unique: true
    t.index ["from_id"], name: "index_friendships_on_from_id"
  end

  create_table "gauges", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.integer "value"
    t.datetime "time"
    t.index ["time"], name: "index_gauges_on_time"
  end

  create_table "import_twitter_user_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "twitter_user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_import_twitter_user_requests_on_created_at"
    t.index ["user_id"], name: "index_import_twitter_user_requests_on_user_id"
  end

  create_table "inactive_followerships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_inactive_followerships_on_follower_uid"
    t.index ["from_uid"], name: "index_inactive_followerships_on_from_uid"
  end

  create_table "inactive_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_inactive_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_inactive_friendships_on_from_uid"
  end

  create_table "inactive_mutual_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_inactive_mutual_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_inactive_mutual_friendships_on_from_uid"
  end

  create_table "jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "track_id", default: -1, null: false
    t.integer "user_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.integer "twitter_user_id", default: -1, null: false
    t.bigint "client_uid", default: -1, null: false
    t.string "jid", default: "", null: false
    t.string "parent_jid", default: "", null: false
    t.string "worker_class", default: "", null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "enqueued_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_jobs_on_created_at"
    t.index ["jid"], name: "index_jobs_on_jid"
    t.index ["screen_name"], name: "index_jobs_on_screen_name"
    t.index ["track_id"], name: "index_jobs_on_track_id"
    t.index ["uid"], name: "index_jobs_on_uid"
  end

  create_table "mentions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "status_info", null: false
    t.integer "from_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_mentions_on_created_at"
    t.index ["from_id"], name: "index_mentions_on_from_id"
    t.index ["screen_name"], name: "index_mentions_on_screen_name"
    t.index ["uid"], name: "index_mentions_on_uid"
  end

  create_table "modal_open_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_modal_open_logs_on_created_at"
  end

  create_table "mutual_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_mutual_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_mutual_friendships_on_from_uid"
  end

  create_table "news_reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_news_reports_on_created_at"
    t.index ["token"], name: "index_news_reports_on_token", unique: true
    t.index ["user_id"], name: "index_news_reports_on_user_id"
  end

  create_table "not_found_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name", null: false
    t.bigint "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_not_found_users_on_created_at"
    t.index ["screen_name"], name: "index_not_found_users_on_screen_name", unique: true
  end

  create_table "notification_messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.string "message_id", default: "", null: false
    t.text "message", null: false
    t.string "context", default: "", null: false
    t.string "medium", default: "", null: false
    t.string "token", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_notification_messages_on_created_at"
    t.index ["message_id"], name: "index_notification_messages_on_message_id"
    t.index ["screen_name"], name: "index_notification_messages_on_screen_name"
    t.index ["token"], name: "index_notification_messages_on_token"
    t.index ["uid"], name: "index_notification_messages_on_uid"
    t.index ["user_id"], name: "index_notification_messages_on_user_id"
  end

  create_table "notification_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.boolean "email", default: true, null: false
    t.boolean "dm", default: true, null: false
    t.boolean "news", default: true, null: false
    t.boolean "search", default: true, null: false
    t.boolean "prompt_report", default: true, null: false
    t.datetime "last_email_at"
    t.datetime "last_dm_at"
    t.datetime "last_news_at"
    t.datetime "search_sent_at"
    t.datetime "prompt_report_sent_at"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_settings_on_user_id", unique: true
  end

  create_table "old_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.boolean "authorized", default: false, null: false
    t.string "secret", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_old_users_on_created_at"
    t.index ["screen_name"], name: "index_old_users_on_screen_name"
    t.index ["uid"], name: "index_old_users_on_uid", unique: true
  end

  create_table "one_sided_followerships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_one_sided_followerships_on_follower_uid"
    t.index ["from_uid"], name: "index_one_sided_followerships_on_from_uid"
  end

  create_table "one_sided_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_one_sided_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_one_sided_friendships_on_from_uid"
  end

  create_table "orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "search_count", default: 0, null: false
    t.integer "follow_requests_count", default: 0, null: false
    t.integer "unfollow_requests_count", default: 0, null: false
    t.string "customer_id"
    t.string "subscription_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "page_cache_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "context", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_page_cache_logs_on_created_at"
  end

  create_table "polling_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "", null: false
    t.string "screen_name", default: "", null: false
    t.string "action", default: "", null: false
    t.boolean "status", default: false, null: false
    t.float "time", default: 0.0, null: false
    t.integer "retry_count", default: 0, null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_polling_logs_on_created_at"
    t.index ["screen_name"], name: "index_polling_logs_on_screen_name"
    t.index ["session_id"], name: "index_polling_logs_on_session_id"
    t.index ["uid"], name: "index_polling_logs_on_uid"
    t.index ["user_id"], name: "index_polling_logs_on_user_id"
  end

  create_table "prompt_reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.text "changes_json", null: false
    t.string "token", null: false
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prompt_reports_on_created_at"
    t.index ["token"], name: "index_prompt_reports_on_token", unique: true
    t.index ["user_id"], name: "index_prompt_reports_on_user_id"
  end

  create_table "reset_cache_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "-1", null: false
    t.integer "user_id", default: -1, null: false
    t.integer "request_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.boolean "status", default: false, null: false
    t.string "message", default: "", null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_reset_cache_logs_on_created_at"
  end

  create_table "reset_cache_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reset_cache_requests_on_created_at"
    t.index ["user_id"], name: "index_reset_cache_requests_on_user_id"
  end

  create_table "reset_egotter_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "-1", null: false
    t.integer "user_id", default: -1, null: false
    t.integer "request_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.boolean "status", default: false, null: false
    t.string "message", default: "", null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_reset_egotter_logs_on_created_at"
  end

  create_table "reset_egotter_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reset_egotter_requests_on_created_at"
    t.index ["user_id"], name: "index_reset_egotter_requests_on_user_id"
  end

  create_table "scores", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "klout_id", null: false
    t.float "klout_score", limit: 53, null: false
    t.text "influence_json", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_scores_on_created_at"
    t.index ["uid"], name: "index_scores_on_uid", unique: true
  end

  create_table "search_error_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "", null: false
    t.string "screen_name", default: "", null: false
    t.string "location", default: "", null: false
    t.string "message", default: "", null: false
    t.string "controller", default: "", null: false
    t.string "action", default: "", null: false
    t.string "method", default: "", null: false
    t.string "path", default: "", null: false
    t.integer "status", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_search_error_logs_on_created_at"
    t.index ["screen_name"], name: "index_search_error_logs_on_screen_name"
    t.index ["session_id"], name: "index_search_error_logs_on_session_id"
    t.index ["uid"], name: "index_search_error_logs_on_uid"
    t.index ["user_id"], name: "index_search_error_logs_on_user_id"
  end

  create_table "search_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", null: false
    t.bigint "uid", null: false
    t.bigint "ahoy_visit_id"
    t.string "via"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_search_histories_on_created_at"
    t.index ["session_id"], name: "index_search_histories_on_session_id"
    t.index ["user_id"], name: "index_search_histories_on_user_id"
  end

  create_table "search_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.string "controller", default: "", null: false
    t.string "action", default: "", null: false
    t.boolean "cache_hit", default: false, null: false
    t.boolean "ego_surfing", default: false, null: false
    t.string "method", default: "", null: false
    t.string "path", default: "", null: false
    t.integer "status", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.text "referer"
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.string "medium", default: "", null: false
    t.string "ab_test", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_search_logs_on_action"
    t.index ["created_at"], name: "index_search_logs_on_created_at"
    t.index ["screen_name"], name: "index_search_logs_on_screen_name"
    t.index ["session_id"], name: "index_search_logs_on_session_id"
    t.index ["uid", "action"], name: "index_search_logs_on_uid_and_action"
    t.index ["uid"], name: "index_search_logs_on_uid"
    t.index ["user_id"], name: "index_search_logs_on_user_id"
  end

  create_table "search_reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_search_reports_on_created_at"
    t.index ["token"], name: "index_search_reports_on_token", unique: true
    t.index ["user_id"], name: "index_search_reports_on_user_id"
  end

  create_table "search_results", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "status_info", null: false
    t.integer "from_id", null: false
    t.string "query", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_search_results_on_created_at"
    t.index ["from_id"], name: "index_search_results_on_from_id"
    t.index ["screen_name"], name: "index_search_results_on_screen_name"
    t.index ["uid"], name: "index_search_results_on_uid"
  end

  create_table "sign_in_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "-1", null: false
    t.string "screen_name", default: "", null: false
    t.string "context", default: "", null: false
    t.boolean "follow", default: false, null: false
    t.boolean "tweet", default: false, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.string "ab_test", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_sign_in_logs_on_created_at"
    t.index ["user_id"], name: "index_sign_in_logs_on_user_id"
  end

  create_table "statuses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "status_info", null: false
    t.integer "from_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_statuses_on_created_at"
    t.index ["from_id"], name: "index_statuses_on_from_id"
    t.index ["screen_name"], name: "index_statuses_on_screen_name"
    t.index ["uid"], name: "index_statuses_on_uid"
  end

  create_table "tokimeki_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_tokimeki_friendships_on_friend_uid"
    t.index ["user_uid", "friend_uid"], name: "index_tokimeki_friendships_on_user_uid_and_friend_uid", unique: true
    t.index ["user_uid"], name: "index_tokimeki_friendships_on_user_uid"
  end

  create_table "tokimeki_unfriendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_tokimeki_unfriendships_on_friend_uid"
    t.index ["user_uid"], name: "index_tokimeki_unfriendships_on_user_uid"
  end

  create_table "tokimeki_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.integer "friends_count", default: 0, null: false
    t.integer "processed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tokimeki_users_on_created_at"
    t.index ["uid"], name: "index_tokimeki_users_on_uid", unique: true
  end

  create_table "tracks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.string "controller", default: "", null: false
    t.string "action", default: "", null: false
    t.boolean "auto", default: false, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.string "medium", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_tracks_on_created_at"
  end

  create_table "tweet_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "text", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tweet_requests_on_created_at"
    t.index ["user_id"], name: "index_tweet_requests_on_user_id"
  end

  create_table "twitter_db_favorites", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.integer "sequence", null: false
    t.text "raw_attrs_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_twitter_db_favorites_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_favorites_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_favorites_on_uid"
  end

  create_table "twitter_db_followerships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_uid", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_twitter_db_followerships_on_follower_uid"
    t.index ["user_uid", "follower_uid"], name: "index_twitter_db_followerships_on_user_uid_and_follower_uid", unique: true
    t.index ["user_uid"], name: "index_twitter_db_followerships_on_user_uid"
  end

  create_table "twitter_db_friendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_twitter_db_friendships_on_friend_uid"
    t.index ["user_uid", "friend_uid"], name: "index_twitter_db_friendships_on_user_uid_and_friend_uid", unique: true
    t.index ["user_uid"], name: "index_twitter_db_friendships_on_user_uid"
  end

  create_table "twitter_db_mentions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.integer "sequence", null: false
    t.text "raw_attrs_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_twitter_db_mentions_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_mentions_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_mentions_on_uid"
  end

  create_table "twitter_db_profiles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", default: "", null: false
    t.integer "friends_count", default: -1, null: false
    t.integer "followers_count", default: -1, null: false
    t.boolean "protected", default: false, null: false
    t.boolean "suspended", default: false, null: false
    t.datetime "status_created_at"
    t.datetime "account_created_at"
    t.integer "statuses_count", default: -1, null: false
    t.integer "favourites_count", default: -1, null: false
    t.integer "listed_count", default: -1, null: false
    t.string "name", default: "", null: false
    t.string "location", default: "", null: false
    t.string "description", default: "", null: false
    t.string "url", default: "", null: false
    t.string "geo_enabled", default: "0", null: false
    t.boolean "verified", default: false, null: false
    t.string "lang", default: "", null: false
    t.string "profile_image_url_https", default: "", null: false
    t.string "profile_banner_url", default: "", null: false
    t.string "profile_link_color", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_twitter_db_profiles_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_profiles_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_profiles_on_uid", unique: true
  end

  create_table "twitter_db_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.integer "sequence", null: false
    t.text "raw_attrs_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_twitter_db_statuses_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_statuses_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_statuses_on_uid"
  end

  create_table "twitter_db_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", default: "", null: false
    t.integer "friends_count", default: -1, null: false
    t.integer "followers_count", default: -1, null: false
    t.boolean "protected", default: false, null: false
    t.boolean "suspended", default: false, null: false
    t.datetime "status_created_at"
    t.datetime "account_created_at"
    t.integer "statuses_count", default: -1, null: false
    t.integer "favourites_count", default: -1, null: false
    t.integer "listed_count", default: -1, null: false
    t.string "name", default: "", null: false
    t.string "location", default: "", null: false
    t.string "description", default: "", null: false
    t.string "url", default: "", null: false
    t.boolean "geo_enabled", default: false, null: false
    t.boolean "verified", default: false, null: false
    t.string "lang", default: "", null: false
    t.string "profile_image_url_https", default: "", null: false
    t.string "profile_banner_url", default: "", null: false
    t.string "profile_link_color", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_twitter_db_users_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_users_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_users_on_uid", unique: true
    t.index ["updated_at"], name: "index_twitter_db_users_on_updated_at"
  end

  create_table "twitter_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.integer "friends_size", default: -1, null: false
    t.integer "followers_size", default: -1, null: false
    t.integer "friends_count", default: -1, null: false
    t.integer "followers_count", default: -1, null: false
    t.integer "search_count", default: 0, null: false
    t.integer "update_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_twitter_users_on_created_at"
    t.index ["screen_name", "user_id"], name: "index_twitter_users_on_screen_name_and_user_id"
    t.index ["screen_name"], name: "index_twitter_users_on_screen_name"
    t.index ["uid", "user_id"], name: "index_twitter_users_on_uid_and_user_id"
    t.index ["uid"], name: "index_twitter_users_on_uid"
  end

  create_table "unfollow_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "uid", null: false
    t.datetime "finished_at"
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_unfollow_requests_on_created_at"
    t.index ["user_id"], name: "index_unfollow_requests_on_user_id"
  end

  create_table "unfollowerships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_unfollowerships_on_follower_uid"
    t.index ["from_uid"], name: "index_unfollowerships_on_from_uid"
  end

  create_table "unfriendships", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_unfriendships_on_friend_uid"
    t.index ["from_uid"], name: "index_unfriendships_on_from_uid"
  end

  create_table "usage_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
    t.bigint "uid", null: false
    t.text "wday_json", null: false
    t.text "wday_drilldown_json", null: false
    t.text "hour_json", null: false
    t.text "hour_drilldown_json", null: false
    t.text "usage_time_json", null: false
    t.text "breakdown_json", null: false
    t.text "hashtags_json", null: false
    t.text "mentions_json", null: false
    t.text "tweet_clusters_json", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_usage_stats_on_created_at"
    t.index ["uid"], name: "index_usage_stats_on_uid", unique: true
  end

  create_table "user_engagement_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "date", null: false
    t.integer "total", default: 0, null: false
    t.integer "1_days", default: 0, null: false
    t.integer "2_days", default: 0, null: false
    t.integer "3_days", default: 0, null: false
    t.integer "4_days", default: 0, null: false
    t.integer "5_days", default: 0, null: false
    t.integer "6_days", default: 0, null: false
    t.integer "7_days", default: 0, null: false
    t.integer "8_days", default: 0, null: false
    t.integer "9_days", default: 0, null: false
    t.integer "10_days", default: 0, null: false
    t.integer "11_days", default: 0, null: false
    t.integer "12_days", default: 0, null: false
    t.integer "13_days", default: 0, null: false
    t.integer "14_days", default: 0, null: false
    t.integer "15_days", default: 0, null: false
    t.integer "16_days", default: 0, null: false
    t.integer "17_days", default: 0, null: false
    t.integer "18_days", default: 0, null: false
    t.integer "19_days", default: 0, null: false
    t.integer "20_days", default: 0, null: false
    t.integer "21_days", default: 0, null: false
    t.integer "22_days", default: 0, null: false
    t.integer "23_days", default: 0, null: false
    t.integer "24_days", default: 0, null: false
    t.integer "25_days", default: 0, null: false
    t.integer "26_days", default: 0, null: false
    t.integer "27_days", default: 0, null: false
    t.integer "28_days", default: 0, null: false
    t.integer "29_days", default: 0, null: false
    t.integer "30_days", default: 0, null: false
    t.integer "before_1_days", default: 0, null: false
    t.integer "before_2_days", default: 0, null: false
    t.integer "before_3_days", default: 0, null: false
    t.integer "before_4_days", default: 0, null: false
    t.integer "before_5_days", default: 0, null: false
    t.integer "before_6_days", default: 0, null: false
    t.integer "before_7_days", default: 0, null: false
    t.integer "before_8_days", default: 0, null: false
    t.integer "before_9_days", default: 0, null: false
    t.integer "before_10_days", default: 0, null: false
    t.integer "before_11_days", default: 0, null: false
    t.integer "before_12_days", default: 0, null: false
    t.integer "before_13_days", default: 0, null: false
    t.integer "before_14_days", default: 0, null: false
    t.integer "before_15_days", default: 0, null: false
    t.integer "before_16_days", default: 0, null: false
    t.integer "before_17_days", default: 0, null: false
    t.integer "before_18_days", default: 0, null: false
    t.integer "before_19_days", default: 0, null: false
    t.integer "before_20_days", default: 0, null: false
    t.integer "before_21_days", default: 0, null: false
    t.integer "before_22_days", default: 0, null: false
    t.integer "before_23_days", default: 0, null: false
    t.integer "before_24_days", default: 0, null: false
    t.integer "before_25_days", default: 0, null: false
    t.integer "before_26_days", default: 0, null: false
    t.integer "before_27_days", default: 0, null: false
    t.integer "before_28_days", default: 0, null: false
    t.integer "before_29_days", default: 0, null: false
    t.integer "before_30_days", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_user_engagement_stats_on_date", unique: true
  end

  create_table "user_retention_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "date", null: false
    t.integer "total", default: 0, null: false
    t.integer "1_days", default: 0, null: false
    t.integer "2_days", default: 0, null: false
    t.integer "3_days", default: 0, null: false
    t.integer "4_days", default: 0, null: false
    t.integer "5_days", default: 0, null: false
    t.integer "6_days", default: 0, null: false
    t.integer "7_days", default: 0, null: false
    t.integer "8_days", default: 0, null: false
    t.integer "9_days", default: 0, null: false
    t.integer "10_days", default: 0, null: false
    t.integer "11_days", default: 0, null: false
    t.integer "12_days", default: 0, null: false
    t.integer "13_days", default: 0, null: false
    t.integer "14_days", default: 0, null: false
    t.integer "15_days", default: 0, null: false
    t.integer "16_days", default: 0, null: false
    t.integer "17_days", default: 0, null: false
    t.integer "18_days", default: 0, null: false
    t.integer "19_days", default: 0, null: false
    t.integer "20_days", default: 0, null: false
    t.integer "21_days", default: 0, null: false
    t.integer "22_days", default: 0, null: false
    t.integer "23_days", default: 0, null: false
    t.integer "24_days", default: 0, null: false
    t.integer "25_days", default: 0, null: false
    t.integer "26_days", default: 0, null: false
    t.integer "27_days", default: 0, null: false
    t.integer "28_days", default: 0, null: false
    t.integer "29_days", default: 0, null: false
    t.integer "30_days", default: 0, null: false
    t.integer "after_1_days", default: 0, null: false
    t.integer "after_2_days", default: 0, null: false
    t.integer "after_3_days", default: 0, null: false
    t.integer "after_4_days", default: 0, null: false
    t.integer "after_5_days", default: 0, null: false
    t.integer "after_6_days", default: 0, null: false
    t.integer "after_7_days", default: 0, null: false
    t.integer "after_8_days", default: 0, null: false
    t.integer "after_9_days", default: 0, null: false
    t.integer "after_10_days", default: 0, null: false
    t.integer "after_11_days", default: 0, null: false
    t.integer "after_12_days", default: 0, null: false
    t.integer "after_13_days", default: 0, null: false
    t.integer "after_14_days", default: 0, null: false
    t.integer "after_15_days", default: 0, null: false
    t.integer "after_16_days", default: 0, null: false
    t.integer "after_17_days", default: 0, null: false
    t.integer "after_18_days", default: 0, null: false
    t.integer "after_19_days", default: 0, null: false
    t.integer "after_20_days", default: 0, null: false
    t.integer "after_21_days", default: 0, null: false
    t.integer "after_22_days", default: 0, null: false
    t.integer "after_23_days", default: 0, null: false
    t.integer "after_24_days", default: 0, null: false
    t.integer "after_25_days", default: 0, null: false
    t.integer "after_26_days", default: 0, null: false
    t.integer "after_27_days", default: 0, null: false
    t.integer "after_28_days", default: 0, null: false
    t.integer "after_29_days", default: 0, null: false
    t.integer "after_30_days", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_user_retention_stats_on_date", unique: true
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.boolean "authorized", default: true, null: false
    t.string "token", null: false
    t.string "secret", null: false
    t.string "email", default: "", null: false
    t.datetime "first_access_at"
    t.datetime "last_access_at"
    t.datetime "first_search_at"
    t.datetime "last_search_at"
    t.datetime "first_sign_in_at"
    t.datetime "last_sign_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["first_access_at"], name: "index_users_on_first_access_at"
    t.index ["last_access_at"], name: "index_users_on_last_access_at"
    t.index ["screen_name"], name: "index_users_on_screen_name"
    t.index ["token"], name: "index_users_on_token"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "visitor_engagement_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "date", null: false
    t.integer "total", default: 0, null: false
    t.integer "1_days", default: 0, null: false
    t.integer "2_days", default: 0, null: false
    t.integer "3_days", default: 0, null: false
    t.integer "4_days", default: 0, null: false
    t.integer "5_days", default: 0, null: false
    t.integer "6_days", default: 0, null: false
    t.integer "7_days", default: 0, null: false
    t.integer "8_days", default: 0, null: false
    t.integer "9_days", default: 0, null: false
    t.integer "10_days", default: 0, null: false
    t.integer "11_days", default: 0, null: false
    t.integer "12_days", default: 0, null: false
    t.integer "13_days", default: 0, null: false
    t.integer "14_days", default: 0, null: false
    t.integer "15_days", default: 0, null: false
    t.integer "16_days", default: 0, null: false
    t.integer "17_days", default: 0, null: false
    t.integer "18_days", default: 0, null: false
    t.integer "19_days", default: 0, null: false
    t.integer "20_days", default: 0, null: false
    t.integer "21_days", default: 0, null: false
    t.integer "22_days", default: 0, null: false
    t.integer "23_days", default: 0, null: false
    t.integer "24_days", default: 0, null: false
    t.integer "25_days", default: 0, null: false
    t.integer "26_days", default: 0, null: false
    t.integer "27_days", default: 0, null: false
    t.integer "28_days", default: 0, null: false
    t.integer "29_days", default: 0, null: false
    t.integer "30_days", default: 0, null: false
    t.integer "before_1_days", default: 0, null: false
    t.integer "before_2_days", default: 0, null: false
    t.integer "before_3_days", default: 0, null: false
    t.integer "before_4_days", default: 0, null: false
    t.integer "before_5_days", default: 0, null: false
    t.integer "before_6_days", default: 0, null: false
    t.integer "before_7_days", default: 0, null: false
    t.integer "before_8_days", default: 0, null: false
    t.integer "before_9_days", default: 0, null: false
    t.integer "before_10_days", default: 0, null: false
    t.integer "before_11_days", default: 0, null: false
    t.integer "before_12_days", default: 0, null: false
    t.integer "before_13_days", default: 0, null: false
    t.integer "before_14_days", default: 0, null: false
    t.integer "before_15_days", default: 0, null: false
    t.integer "before_16_days", default: 0, null: false
    t.integer "before_17_days", default: 0, null: false
    t.integer "before_18_days", default: 0, null: false
    t.integer "before_19_days", default: 0, null: false
    t.integer "before_20_days", default: 0, null: false
    t.integer "before_21_days", default: 0, null: false
    t.integer "before_22_days", default: 0, null: false
    t.integer "before_23_days", default: 0, null: false
    t.integer "before_24_days", default: 0, null: false
    t.integer "before_25_days", default: 0, null: false
    t.integer "before_26_days", default: 0, null: false
    t.integer "before_27_days", default: 0, null: false
    t.integer "before_28_days", default: 0, null: false
    t.integer "before_29_days", default: 0, null: false
    t.integer "before_30_days", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_visitor_engagement_stats_on_date", unique: true
  end

  create_table "visitor_retention_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "date", null: false
    t.integer "total", default: 0, null: false
    t.integer "1_days", default: 0, null: false
    t.integer "2_days", default: 0, null: false
    t.integer "3_days", default: 0, null: false
    t.integer "4_days", default: 0, null: false
    t.integer "5_days", default: 0, null: false
    t.integer "6_days", default: 0, null: false
    t.integer "7_days", default: 0, null: false
    t.integer "8_days", default: 0, null: false
    t.integer "9_days", default: 0, null: false
    t.integer "10_days", default: 0, null: false
    t.integer "11_days", default: 0, null: false
    t.integer "12_days", default: 0, null: false
    t.integer "13_days", default: 0, null: false
    t.integer "14_days", default: 0, null: false
    t.integer "15_days", default: 0, null: false
    t.integer "16_days", default: 0, null: false
    t.integer "17_days", default: 0, null: false
    t.integer "18_days", default: 0, null: false
    t.integer "19_days", default: 0, null: false
    t.integer "20_days", default: 0, null: false
    t.integer "21_days", default: 0, null: false
    t.integer "22_days", default: 0, null: false
    t.integer "23_days", default: 0, null: false
    t.integer "24_days", default: 0, null: false
    t.integer "25_days", default: 0, null: false
    t.integer "26_days", default: 0, null: false
    t.integer "27_days", default: 0, null: false
    t.integer "28_days", default: 0, null: false
    t.integer "29_days", default: 0, null: false
    t.integer "30_days", default: 0, null: false
    t.integer "after_1_days", default: 0, null: false
    t.integer "after_2_days", default: 0, null: false
    t.integer "after_3_days", default: 0, null: false
    t.integer "after_4_days", default: 0, null: false
    t.integer "after_5_days", default: 0, null: false
    t.integer "after_6_days", default: 0, null: false
    t.integer "after_7_days", default: 0, null: false
    t.integer "after_8_days", default: 0, null: false
    t.integer "after_9_days", default: 0, null: false
    t.integer "after_10_days", default: 0, null: false
    t.integer "after_11_days", default: 0, null: false
    t.integer "after_12_days", default: 0, null: false
    t.integer "after_13_days", default: 0, null: false
    t.integer "after_14_days", default: 0, null: false
    t.integer "after_15_days", default: 0, null: false
    t.integer "after_16_days", default: 0, null: false
    t.integer "after_17_days", default: 0, null: false
    t.integer "after_18_days", default: 0, null: false
    t.integer "after_19_days", default: 0, null: false
    t.integer "after_20_days", default: 0, null: false
    t.integer "after_21_days", default: 0, null: false
    t.integer "after_22_days", default: 0, null: false
    t.integer "after_23_days", default: 0, null: false
    t.integer "after_24_days", default: 0, null: false
    t.integer "after_25_days", default: 0, null: false
    t.integer "after_26_days", default: 0, null: false
    t.integer "after_27_days", default: 0, null: false
    t.integer "after_28_days", default: 0, null: false
    t.integer "after_29_days", default: 0, null: false
    t.integer "after_30_days", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_visitor_retention_stats_on_date", unique: true
  end

  create_table "visitors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "-1", null: false
    t.string "screen_name", default: "", null: false
    t.datetime "first_access_at"
    t.datetime "last_access_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_visitors_on_created_at"
    t.index ["first_access_at"], name: "index_visitors_on_first_access_at"
    t.index ["last_access_at"], name: "index_visitors_on_last_access_at"
    t.index ["screen_name"], name: "index_visitors_on_screen_name"
    t.index ["session_id"], name: "index_visitors_on_session_id", unique: true
    t.index ["uid"], name: "index_visitors_on_uid"
    t.index ["user_id"], name: "index_visitors_on_user_id"
  end

  create_table "welcome_messages", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_welcome_messages_on_created_at"
    t.index ["token"], name: "index_welcome_messages_on_token", unique: true
    t.index ["user_id"], name: "index_welcome_messages_on_user_id"
  end

  add_foreign_key "tokimeki_friendships", "tokimeki_users", column: "user_uid", primary_key: "uid"
  add_foreign_key "twitter_db_followerships", "twitter_db_users", column: "follower_uid", primary_key: "uid"
  add_foreign_key "twitter_db_followerships", "twitter_db_users", column: "user_uid", primary_key: "uid"
  add_foreign_key "twitter_db_friendships", "twitter_db_users", column: "friend_uid", primary_key: "uid"
  add_foreign_key "twitter_db_friendships", "twitter_db_users", column: "user_uid", primary_key: "uid"
end
