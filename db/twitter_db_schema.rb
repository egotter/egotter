# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_22_090610) do

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
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_twitter_db_users_on_created_at"
    t.index ["screen_name"], name: "index_twitter_db_users_on_screen_name"
    t.index ["uid"], name: "index_twitter_db_users_on_uid", unique: true
    t.index ["updated_at"], name: "index_twitter_db_users_on_updated_at"
  end
end
