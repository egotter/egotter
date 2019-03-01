class CreateAudienceInsights < ActiveRecord::Migration[5.1]
  def change
    create_table :audience_insights do |t|
      t.bigint :uid,               null: false
      t.text   :categories_text,        null: false
      t.text   :friends_text,           null: false
      t.text   :followers_text,         null: false
      t.text   :new_friends_text,       null: false
      t.text   :new_followers_text,     null: false
      t.text   :unfriends_text,         null: false
      t.text   :unfollowers_text,       null: false
      t.text   :new_unfriends_text,     null: false
      t.text   :new_unfollowers_text,   null: false
      t.text   :tweets_categories_text, null: false
      t.text   :tweets_text,            null: false

      t.timestamps null: false

      t.index :uid, unique: true
      t.index :created_at
    end
  end
end
