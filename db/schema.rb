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

ActiveRecord::Schema.define(version: 2021_12_21_040841) do

  create_table "access_days", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "date", null: false
    t.timestamp "time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_access_days_on_user_id_and_date", unique: true
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activeness_warning_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_activeness_warning_messages_on_created_at"
    t.index ["token"], name: "index_activeness_warning_messages_on_token", unique: true
    t.index ["user_id"], name: "index_activeness_warning_messages_on_user_id"
  end

  create_table "ahoy_events", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "ahoy_visits", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.timestamp "started_at", null: false
    t.index ["started_at"], name: "index_ahoy_visits_on_started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "announcements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.boolean "status", default: true, null: false
    t.string "date", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_announcements_on_created_at"
  end

  create_table "assemble_twitter_user_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "twitter_user_id", null: false
    t.bigint "user_id"
    t.bigint "uid"
    t.string "status", default: "", null: false
    t.string "requested_by"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_assemble_twitter_user_requests_on_created_at"
    t.index ["twitter_user_id"], name: "index_assemble_twitter_user_requests_on_twitter_user_id"
  end

  create_table "audience_insights", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "background_force_update_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "background_search_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "background_update_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "banned_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_banned_users_on_created_at"
    t.index ["user_id"], name: "index_banned_users_on_user_id", unique: true
  end

  create_table "blacklist_words", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_blacklist_words_on_created_at"
    t.index ["text"], name: "index_blacklist_words_on_text", unique: true
  end

  create_table "block_friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_block_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_block_friendships_on_from_uid"
  end

  create_table "block_reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "message_id", default: "", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.string "requested_by"
    t.datetime "read_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_block_reports_on_created_at"
    t.index ["token"], name: "index_block_reports_on_token", unique: true
    t.index ["user_id"], name: "index_block_reports_on_user_id"
  end

  create_table "blocked_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name"
    t.bigint "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_blocked_users_on_created_at"
    t.index ["uid"], name: "index_blocked_users_on_uid", unique: true
  end

  create_table "blocking_relationships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "to_uid", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_blocking_relationships_on_created_at"
    t.index ["from_uid", "to_uid"], name: "index_blocking_relationships_on_from_uid_and_to_uid", unique: true
    t.index ["to_uid", "from_uid"], name: "index_blocking_relationships_on_to_uid_and_from_uid", unique: true
  end

  create_table "bots", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.boolean "authorized", default: true, null: false
    t.boolean "locked", default: false, null: false
    t.string "secret", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authorized", "locked"], name: "index_bots_on_authorized_and_locked"
    t.index ["screen_name"], name: "index_bots_on_screen_name"
    t.index ["uid"], name: "index_bots_on_uid", unique: true
  end

  create_table "cache_directories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "dir", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dir"], name: "index_cache_directories_on_dir", unique: true
    t.index ["name"], name: "index_cache_directories_on_name", unique: true
  end

  create_table "checkout_sessions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_checkout_session_id", null: false
    t.json "properties"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_checkout_sessions_on_created_at"
    t.index ["user_id", "stripe_checkout_session_id"], name: "index_on_user_id_and_scs_id", unique: true
  end

  create_table "close_friends_og_images", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.json "properties"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_close_friends_og_images_on_uid", unique: true
  end

  create_table "close_friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_close_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_close_friendships_on_from_uid"
  end

  create_table "coupons", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "search_count", null: false
    t.string "stripe_coupon_id"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_coupons_on_created_at"
    t.index ["user_id"], name: "index_coupons_on_user_id"
  end

  create_table "crawler_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "controller", default: "", null: false
    t.string "action", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "ip", default: "", null: false
    t.string "method", default: "", null: false
    t.string "path", default: "", null: false
    t.string "params"
    t.integer "status", default: -1, null: false
    t.string "user_agent", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_crawler_logs_on_created_at"
  end

  create_table "create_deletable_tweets_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_create_deletable_tweets_requests_on_created_at"
    t.index ["user_id"], name: "index_create_deletable_tweets_requests_on_user_id"
  end

  create_table "create_direct_message_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "sender_id"
    t.bigint "recipient_id"
    t.text "error_message"
    t.json "properties"
    t.timestamp "sent_at"
    t.timestamp "failed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_create_direct_message_requests_on_created_at"
    t.index ["recipient_id"], name: "index_create_direct_message_requests_on_recipient_id"
    t.index ["sender_id"], name: "index_create_direct_message_requests_on_sender_id"
  end

  create_table "create_follow_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "create_periodic_report_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "requested_by"
    t.string "status", default: "", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_create_periodic_report_requests_on_created_at"
    t.index ["user_id"], name: "index_create_periodic_report_requests_on_user_id"
  end

  create_table "create_periodic_tweet_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_create_periodic_tweet_requests_on_created_at"
    t.index ["user_id"], name: "index_create_periodic_tweet_requests_on_user_id", unique: true
  end

  create_table "create_prompt_report_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.integer "request_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.boolean "status", default: false, null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_prompt_report_logs_on_created_at"
    t.index ["error_class"], name: "index_create_prompt_report_logs_on_error_class"
    t.index ["request_id"], name: "index_create_prompt_report_logs_on_request_id"
    t.index ["screen_name"], name: "index_create_prompt_report_logs_on_screen_name"
    t.index ["uid"], name: "index_create_prompt_report_logs_on_uid"
    t.index ["user_id", "created_at"], name: "index_create_prompt_report_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_create_prompt_report_logs_on_user_id"
  end

  create_table "create_relationship_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "create_test_report_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.integer "request_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.boolean "status", default: false, null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_test_report_logs_on_created_at"
    t.index ["request_id"], name: "index_create_test_report_logs_on_request_id"
    t.index ["screen_name"], name: "index_create_test_report_logs_on_screen_name"
    t.index ["uid"], name: "index_create_test_report_logs_on_uid"
  end

  create_table "create_test_report_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_create_test_report_requests_on_created_at"
    t.index ["user_id"], name: "index_create_test_report_requests_on_user_id"
  end

  create_table "create_twitter_user_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "create_twitter_user_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id"
    t.integer "user_id", null: false
    t.bigint "uid", null: false
    t.integer "twitter_user_id"
    t.string "status_message"
    t.string "requested_by", default: "", null: false
    t.datetime "finished_at"
    t.bigint "ahoy_visit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_create_twitter_user_requests_on_created_at"
    t.index ["twitter_user_id"], name: "index_create_twitter_user_requests_on_twitter_user_id"
    t.index ["user_id"], name: "index_create_twitter_user_requests_on_user_id"
  end

  create_table "create_unfollow_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "create_welcome_message_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.integer "request_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.boolean "status", default: false, null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_create_welcome_message_logs_on_created_at"
    t.index ["request_id"], name: "index_create_welcome_message_logs_on_request_id"
    t.index ["screen_name"], name: "index_create_welcome_message_logs_on_screen_name"
    t.index ["uid"], name: "index_create_welcome_message_logs_on_uid"
  end

  create_table "credential_tokens", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token"
    t.string "secret"
    t.string "instance_id"
    t.string "device_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_credential_tokens_on_created_at"
    t.index ["token"], name: "index_credential_tokens_on_token"
    t.index ["user_id"], name: "index_credential_tokens_on_user_id", unique: true
  end

  create_table "customers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_customer_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_customers_on_created_at"
    t.index ["user_id", "stripe_customer_id"], name: "index_customers_on_user_id_and_stripe_customer_id", unique: true
  end

  create_table "deletable_tweets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.bigint "tweet_id", null: false
    t.integer "retweet_count"
    t.integer "favorite_count"
    t.datetime "tweeted_at", null: false
    t.json "hashtags"
    t.json "user_mentions"
    t.json "urls"
    t.json "media"
    t.json "properties"
    t.datetime "deletion_reserved_at"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_deletable_tweets_on_created_at"
    t.index ["tweet_id"], name: "index_deletable_tweets_on_tweet_id"
    t.index ["uid", "tweet_id"], name: "index_deletable_tweets_on_uid_and_tweet_id", unique: true
  end

  create_table "delete_favorites_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "since_date"
    t.datetime "until_date"
    t.boolean "send_dm", default: false, null: false
    t.boolean "tweet", default: false, null: false
    t.integer "reservations_count", default: 0, null: false
    t.integer "destroy_count", default: 0, null: false
    t.integer "errors_count", default: 0, null: false
    t.datetime "stopped_at"
    t.datetime "finished_at"
    t.string "error_class", default: "", null: false
    t.text "error_message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_delete_favorites_requests_on_created_at"
    t.index ["user_id"], name: "index_delete_favorites_requests_on_user_id"
  end

  create_table "delete_tweets_by_archive_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "since_date"
    t.datetime "until_date"
    t.integer "reservations_count", default: 0, null: false
    t.integer "deletions_count", default: 0, null: false
    t.datetime "finished_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_delete_tweets_by_archive_requests_on_created_at"
    t.index ["user_id"], name: "index_delete_tweets_by_archive_requests_on_user_id"
  end

  create_table "delete_tweets_by_search_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "reservations_count", default: 0, null: false
    t.integer "deletions_count", default: 0, null: false
    t.boolean "send_dm", default: false, null: false
    t.boolean "post_tweet", default: false, null: false
    t.text "error_message"
    t.json "filters"
    t.json "tweet_ids"
    t.datetime "finished_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_delete_tweets_by_search_requests_on_created_at"
    t.index ["user_id"], name: "index_delete_tweets_by_search_requests_on_user_id"
  end

  create_table "delete_tweets_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "request_id", default: -1, null: false
    t.integer "user_id", default: -1, null: false
    t.bigint "uid", default: -1, null: false
    t.string "screen_name", default: "", null: false
    t.boolean "status", default: false, null: false
    t.integer "destroy_count", default: 0, null: false
    t.integer "retry_in", default: 0, null: false
    t.string "message", default: "", null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_delete_tweets_logs_on_created_at"
  end

  create_table "delete_tweets_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id"
    t.string "request_token"
    t.integer "user_id", null: false
    t.datetime "since_date"
    t.datetime "until_date"
    t.boolean "send_dm", default: false, null: false
    t.boolean "tweet", default: false, null: false
    t.integer "reservations_count", default: 0, null: false
    t.integer "destroy_count", default: 0, null: false
    t.integer "errors_count", default: 0, null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "finished_at"
    t.string "error_class", default: "", null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_delete_tweets_requests_on_created_at"
    t.index ["user_id"], name: "index_delete_tweets_requests_on_user_id"
  end

  create_table "direct_message_error_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "sender_id"
    t.bigint "recipient_id"
    t.text "error_class"
    t.text "error_message"
    t.json "properties"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_direct_message_error_logs_on_created_at"
    t.index ["recipient_id"], name: "index_direct_message_error_logs_on_recipient_id"
    t.index ["sender_id"], name: "index_direct_message_error_logs_on_sender_id"
  end

  create_table "direct_message_event_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "sender_id"
    t.bigint "recipient_id"
    t.timestamp "time", null: false
    t.index ["name", "time"], name: "index_direct_message_event_logs_on_name_and_time"
    t.index ["time"], name: "index_direct_message_event_logs_on_time"
  end

  create_table "direct_message_receive_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "sender_id"
    t.bigint "recipient_id"
    t.boolean "automated"
    t.text "message"
    t.datetime "created_at", null: false
    t.index ["automated", "created_at", "recipient_id", "sender_id"], name: "index_direct_message_receive_logs_on_acrs"
    t.index ["created_at"], name: "index_direct_message_receive_logs_on_created_at"
    t.index ["recipient_id"], name: "index_direct_message_receive_logs_on_recipient_id"
    t.index ["sender_id", "recipient_id", "automated", "created_at"], name: "index_direct_message_receive_logs_on_srac"
    t.index ["sender_id"], name: "index_direct_message_receive_logs_on_sender_id"
  end

  create_table "direct_message_send_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "sender_id"
    t.bigint "recipient_id"
    t.boolean "automated"
    t.text "message"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_direct_message_send_logs_on_created_at"
    t.index ["recipient_id"], name: "index_direct_message_send_logs_on_recipient_id"
    t.index ["sender_id", "automated"], name: "index_direct_message_send_logs_on_sender_id_and_automated"
    t.index ["sender_id"], name: "index_direct_message_send_logs_on_sender_id"
  end

  create_table "egotter_followers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name"
    t.bigint "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_egotter_followers_on_created_at"
    t.index ["uid"], name: "index_egotter_followers_on_uid", unique: true
  end

  create_table "favorite_friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_favorite_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_favorite_friendships_on_from_uid"
  end

  create_table "favorites", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "follow_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "uid", null: false
    t.string "requested_by", default: "", null: false
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_follow_requests_on_created_at"
    t.index ["user_id"], name: "index_follow_requests_on_user_id"
  end

  create_table "follower_insights", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.json "profiles_count"
    t.json "locations_count"
    t.json "tweet_times"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_follower_insights_on_created_at"
    t.index ["uid"], name: "index_follower_insights_on_uid", unique: true
  end

  create_table "followers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "user_info", null: false
    t.integer "from_id", null: false
    t.datetime "created_at", null: false
    t.index ["from_id"], name: "index_followers_on_from_id"
  end

  create_table "followers_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_followers_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_followers_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_followers_count_points_on_uid"
  end

  create_table "followerships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "from_id", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_followerships_on_follower_uid"
    t.index ["from_id", "follower_uid"], name: "index_followerships_on_from_id_and_follower_uid", unique: true
    t.index ["from_id"], name: "index_followerships_on_from_id"
  end

  create_table "forbidden_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name", null: false
    t.bigint "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_forbidden_users_on_created_at"
    t.index ["screen_name"], name: "index_forbidden_users_on_screen_name", unique: true
  end

  create_table "friend_insights", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.json "profiles_count"
    t.json "locations_count"
    t.json "tweet_times"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_friend_insights_on_created_at"
    t.index ["uid"], name: "index_friend_insights_on_uid", unique: true
  end

  create_table "friends", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
    t.string "uid", null: false
    t.string "screen_name", null: false
    t.text "user_info", null: false
    t.integer "from_id", null: false
    t.datetime "created_at", null: false
    t.index ["from_id"], name: "index_friends_on_from_id"
  end

  create_table "friends_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_friends_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_friends_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_friends_count_points_on_uid"
  end

  create_table "friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "from_id", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_friendships_on_friend_uid"
    t.index ["from_id", "friend_uid"], name: "index_friendships_on_from_id_and_friend_uid", unique: true
    t.index ["from_id"], name: "index_friendships_on_from_id"
  end

  create_table "global_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "text", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_global_messages_on_created_at"
    t.index ["expires_at"], name: "index_global_messages_on_expires_at"
  end

  create_table "import_twitter_user_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "twitter_user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_import_twitter_user_requests_on_created_at"
    t.index ["user_id"], name: "index_import_twitter_user_requests_on_user_id"
  end

  create_table "inactive_followers_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_inactive_followers_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_inactive_followers_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_inactive_followers_count_points_on_uid"
  end

  create_table "inactive_followerships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_inactive_followerships_on_follower_uid"
    t.index ["from_uid"], name: "index_inactive_followerships_on_from_uid"
  end

  create_table "inactive_friends_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_inactive_friends_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_inactive_friends_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_inactive_friends_count_points_on_uid"
  end

  create_table "inactive_friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_inactive_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_inactive_friendships_on_from_uid"
  end

  create_table "inactive_mutual_friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_inactive_mutual_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_inactive_mutual_friendships_on_from_uid"
  end

  create_table "mentions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "modal_open_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "mute_reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "message_id", default: "", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.string "requested_by"
    t.datetime "read_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_mute_reports_on_created_at"
    t.index ["token"], name: "index_mute_reports_on_token", unique: true
    t.index ["user_id"], name: "index_mute_reports_on_user_id"
  end

  create_table "muting_relationships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "to_uid", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_muting_relationships_on_created_at"
    t.index ["from_uid", "to_uid"], name: "index_muting_relationships_on_from_uid_and_to_uid", unique: true
    t.index ["to_uid", "from_uid"], name: "index_muting_relationships_on_to_uid_and_from_uid", unique: true
  end

  create_table "mutual_friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_mutual_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_mutual_friendships_on_from_uid"
  end

  create_table "new_followers_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_new_followers_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_new_followers_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_new_followers_count_points_on_uid"
  end

  create_table "new_friends_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_new_friends_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_new_friends_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_new_friends_count_points_on_uid"
  end

  create_table "new_unfollowers_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_new_unfollowers_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_new_unfollowers_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_new_unfollowers_count_points_on_uid"
  end

  create_table "new_unfriends_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_new_unfriends_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_new_unfriends_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_new_unfriends_count_points_on_uid"
  end

  create_table "news_reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "not_found_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screen_name", null: false
    t.bigint "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_not_found_users_on_created_at"
    t.index ["screen_name"], name: "index_not_found_users_on_screen_name", unique: true
  end

  create_table "notification_settings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "email", default: true, null: false
    t.boolean "dm", default: true, null: false
    t.boolean "news", default: true, null: false
    t.boolean "search", default: true, null: false
    t.boolean "prompt_report", default: true, null: false
    t.integer "report_interval", default: 0, null: false
    t.boolean "report_if_changed", default: false, null: false
    t.boolean "push_notification", default: false, null: false
    t.string "permission_level"
    t.datetime "last_email_at"
    t.datetime "last_dm_at"
    t.datetime "last_news_at"
    t.datetime "search_sent_at"
    t.datetime "prompt_report_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_settings_on_user_id", unique: true
  end

  create_table "old_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "one_sided_followers_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_one_sided_followers_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_one_sided_followers_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_one_sided_followers_count_points_on_uid"
  end

  create_table "one_sided_followerships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_one_sided_followerships_on_follower_uid"
    t.index ["from_uid"], name: "index_one_sided_followerships_on_from_uid"
  end

  create_table "one_sided_friends_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_one_sided_friends_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_one_sided_friends_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_one_sided_friends_count_points_on_uid"
  end

  create_table "one_sided_friendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_one_sided_friendships_on_friend_uid"
    t.index ["from_uid"], name: "index_one_sided_friendships_on_from_uid"
  end

  create_table "orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "ahoy_visit_id"
    t.integer "user_id", null: false
    t.string "email"
    t.string "name"
    t.integer "price"
    t.decimal "tax_rate", precision: 4, scale: 2
    t.integer "trial_end"
    t.integer "search_count", default: 0, null: false
    t.integer "follow_requests_count", default: 0, null: false
    t.integer "unfollow_requests_count", default: 0, null: false
    t.string "checkout_session_id"
    t.string "customer_id"
    t.string "subscription_id"
    t.datetime "canceled_at"
    t.datetime "charge_failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "page_cache_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "payment_intents", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_payment_intent_id", null: false
    t.datetime "expiry_date", null: false
    t.datetime "succeeded_at"
    t.datetime "canceled_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["stripe_payment_intent_id"], name: "index_payment_intents_on_stripe_payment_intent_id", unique: true
    t.index ["user_id"], name: "index_payment_intents_on_user_id"
  end

  create_table "periodic_report_received_message_confirmations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_on_created_at"
    t.index ["user_id"], name: "index_on_user_id", unique: true
  end

  create_table "periodic_report_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "morning", default: true, null: false
    t.boolean "afternoon", default: true, null: false
    t.boolean "evening", default: true, null: false
    t.boolean "night", default: true, null: false
    t.boolean "send_only_if_changed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_periodic_report_settings_on_created_at"
    t.index ["user_id"], name: "index_periodic_report_settings_on_user_id", unique: true
  end

  create_table "periodic_reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.string "token", null: false
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.json "screen_names"
    t.json "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_periodic_reports_on_created_at"
    t.index ["token"], name: "index_periodic_reports_on_token", unique: true
    t.index ["user_id", "created_at"], name: "index_periodic_reports_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_periodic_reports_on_user_id"
  end

  create_table "personality_insights", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.json "profile"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_personality_insights_on_created_at"
    t.index ["uid"], name: "index_personality_insights_on_uid", unique: true
  end

  create_table "polling_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "private_mode_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_private_mode_settings_on_created_at"
    t.index ["user_id"], name: "index_private_mode_settings_on_user_id", unique: true
  end

  create_table "remind_periodic_report_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_remind_periodic_report_requests_on_created_at"
    t.index ["user_id"], name: "index_remind_periodic_report_requests_on_user_id", unique: true
  end

  create_table "reset_cache_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "reset_cache_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reset_cache_requests_on_created_at"
    t.index ["user_id"], name: "index_reset_cache_requests_on_user_id"
  end

  create_table "reset_egotter_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "reset_egotter_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "user_id", null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reset_egotter_requests_on_created_at"
    t.index ["user_id"], name: "index_reset_egotter_requests_on_user_id"
  end

  create_table "scores", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "klout_id", null: false
    t.float "klout_score", limit: 53, null: false
    t.text "influence_json", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_scores_on_created_at"
    t.index ["uid"], name: "index_scores_on_uid", unique: true
  end

  create_table "search_error_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.integer "user_id", default: -1, null: false
    t.string "uid", default: "", null: false
    t.string "screen_name", default: "", null: false
    t.string "location", default: "", null: false
    t.string "message", default: "", null: false
    t.string "controller", default: "", null: false
    t.string "action", default: "", null: false
    t.boolean "xhr", default: false, null: false
    t.string "method", default: "", null: false
    t.string "path", default: "", null: false
    t.string "params"
    t.integer "status", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "ip"
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_search_error_logs_on_created_at"
    t.index ["screen_name"], name: "index_search_error_logs_on_screen_name"
    t.index ["session_id"], name: "index_search_error_logs_on_session_id"
    t.index ["uid"], name: "index_search_error_logs_on_uid"
    t.index ["user_id"], name: "index_search_error_logs_on_user_id"
  end

  create_table "search_histories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "search_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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
    t.string "params"
    t.integer "status", default: -1, null: false
    t.string "via", default: "", null: false
    t.string "device_type", default: "", null: false
    t.string "os", default: "", null: false
    t.string "browser", default: "", null: false
    t.string "ip"
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

  create_table "search_reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "search_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "uid"
    t.string "screen_name"
    t.string "status"
    t.json "properties"
    t.string "error_class"
    t.text "error_message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_search_requests_on_created_at"
    t.index ["uid"], name: "index_search_requests_on_uid"
    t.index ["user_id"], name: "index_search_requests_on_user_id"
  end

  create_table "sign_in_logs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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
    t.string "ip"
    t.string "user_agent", default: "", null: false
    t.string "referer", default: "", null: false
    t.string "referral", default: "", null: false
    t.string "channel", default: "", null: false
    t.string "ab_test", default: "", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_sign_in_logs_on_created_at"
    t.index ["user_id"], name: "index_sign_in_logs_on_user_id"
  end

  create_table "slack_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "channel"
    t.text "message"
    t.json "properties"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_slack_messages_on_created_at"
  end

  create_table "sneak_search_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_sneak_search_requests_on_created_at"
    t.index ["user_id"], name: "index_sneak_search_requests_on_user_id", unique: true
  end

  create_table "statuses", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
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

  create_table "stop_block_report_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_stop_block_report_requests_on_created_at"
    t.index ["user_id"], name: "index_stop_block_report_requests_on_user_id", unique: true
  end

  create_table "stop_mute_report_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_stop_mute_report_requests_on_created_at"
    t.index ["user_id"], name: "index_stop_mute_report_requests_on_user_id", unique: true
  end

  create_table "stop_periodic_report_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_stop_periodic_report_requests_on_created_at"
    t.index ["user_id"], name: "index_stop_periodic_report_requests_on_user_id", unique: true
  end

  create_table "stop_search_report_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_stop_search_report_requests_on_created_at"
    t.index ["user_id"], name: "index_stop_search_report_requests_on_user_id", unique: true
  end

  create_table "sync_deletable_tweets_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_sync_deletable_tweets_requests_on_created_at"
    t.index ["user_id"], name: "index_sync_deletable_tweets_requests_on_user_id"
  end

  create_table "test_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_test_messages_on_created_at"
    t.index ["token"], name: "index_test_messages_on_token", unique: true
    t.index ["user_id"], name: "index_test_messages_on_user_id"
  end

  create_table "trend_insights", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "trend_id", null: false
    t.json "words_count"
    t.json "profile_words_count"
    t.json "times_count"
    t.json "users_count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_trend_insights_on_created_at"
    t.index ["trend_id"], name: "index_trend_insights_on_trend_id", unique: true
  end

  create_table "trends", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "woe_id", null: false
    t.integer "rank"
    t.integer "tweet_volume"
    t.integer "tweets_size"
    t.timestamp "tweets_imported_at"
    t.string "name"
    t.json "properties"
    t.timestamp "time", null: false
    t.json "words_count"
    t.json "times_count"
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_trends_on_created_at"
    t.index ["time"], name: "index_trends_on_time"
  end

  create_table "tweet_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "tweet_id"
    t.string "text", null: false
    t.datetime "finished_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tweet_requests_on_created_at"
    t.index ["user_id"], name: "index_tweet_requests_on_user_id"
  end

  create_table "twitter_api_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_twitter_api_logs_on_created_at"
    t.index ["name"], name: "index_twitter_api_logs_on_name"
  end

  create_table "twitter_db_favorites", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "twitter_db_mentions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "twitter_db_profiles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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
    t.index ["created_at"], name: "index_twitter_db_profiles_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_profiles_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_profiles_on_uid", unique: true
  end

  create_table "twitter_db_statuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "twitter_db_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_twitter_db_users_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_users_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_users_on_uid", unique: true
    t.index ["updated_at"], name: "index_twitter_db_users_on_updated_at"
  end

  create_table "twitter_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: -1, null: false
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.integer "friends_size", default: -1, null: false
    t.integer "followers_size", default: -1, null: false
    t.integer "friends_count", default: -1, null: false
    t.integer "followers_count", default: -1, null: false
    t.integer "statuses_interval"
    t.float "follow_back_rate"
    t.float "reverse_follow_back_rate"
    t.integer "new_friends_size"
    t.integer "new_followers_size"
    t.integer "unfriends_size"
    t.integer "unfollowers_size"
    t.integer "mutual_unfriends_size"
    t.integer "one_sided_friends_size"
    t.integer "one_sided_followers_size"
    t.integer "mutual_friends_size"
    t.integer "inactive_friends_size"
    t.integer "inactive_followers_size"
    t.bigint "top_follower_uid"
    t.datetime "cache_created_at"
    t.datetime "assembled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_twitter_users_on_created_at"
    t.index ["screen_name"], name: "index_twitter_users_on_screen_name"
    t.index ["uid", "created_at"], name: "index_twitter_users_on_uid_and_created_at"
    t.index ["uid"], name: "index_twitter_users_on_uid"
  end

  create_table "unfollow_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "uid", null: false
    t.string "requested_by", default: "", null: false
    t.datetime "finished_at"
    t.string "error_class", default: "", null: false
    t.string "error_message", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_unfollow_requests_on_created_at"
    t.index ["user_id"], name: "index_unfollow_requests_on_user_id"
  end

  create_table "unfollowers_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_unfollowers_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_unfollowers_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_unfollowers_count_points_on_uid"
  end

  create_table "unfollowerships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "follower_uid", null: false
    t.integer "sequence", null: false
    t.index ["follower_uid"], name: "index_unfollowerships_on_follower_uid"
    t.index ["from_uid"], name: "index_unfollowerships_on_from_uid"
  end

  create_table "unfriends_count_points", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.integer "value", null: false
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_unfriends_count_points_on_created_at"
    t.index ["uid", "created_at"], name: "index_unfriends_count_points_on_uid_and_created_at"
    t.index ["uid"], name: "index_unfriends_count_points_on_uid"
  end

  create_table "unfriendships", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "from_uid", null: false
    t.bigint "friend_uid", null: false
    t.integer "sequence", null: false
    t.index ["friend_uid"], name: "index_unfriendships_on_friend_uid"
    t.index ["from_uid"], name: "index_unfriendships_on_from_uid"
  end

  create_table "usage_stats", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4", force: :cascade do |t|
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
    t.json "tweet_times"
    t.json "tweet_clusters"
    t.json "words_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_usage_stats_on_created_at"
    t.index ["uid"], name: "index_usage_stats_on_uid", unique: true
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "uid", null: false
    t.string "screen_name", null: false
    t.boolean "authorized", default: true, null: false
    t.boolean "locked", default: false, null: false
    t.string "token"
    t.string "secret"
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email"
    t.index ["screen_name"], name: "index_users_on_screen_name"
    t.index ["token"], name: "index_users_on_token"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "violation_events", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.json "properties"
    t.timestamp "time", null: false
    t.index ["name", "time"], name: "index_violation_events_on_name_and_time"
    t.index ["time"], name: "index_violation_events_on_time"
    t.index ["user_id"], name: "index_violation_events_on_user_id"
  end

  create_table "warning_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "read_at"
    t.string "message_id", null: false
    t.string "message", default: "", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_warning_messages_on_created_at"
    t.index ["token"], name: "index_warning_messages_on_token", unique: true
    t.index ["user_id"], name: "index_warning_messages_on_user_id"
  end

  create_table "webhook_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "controller"
    t.string "action"
    t.string "path"
    t.json "params"
    t.string "ip"
    t.string "method"
    t.integer "status"
    t.string "user_agent"
    t.timestamp "created_at", null: false
    t.index ["created_at"], name: "index_webhook_logs_on_created_at"
  end

  create_table "welcome_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
