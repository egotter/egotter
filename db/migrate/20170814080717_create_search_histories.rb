class CreateSearchHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :search_histories do |t|
      t.string  :session_id,    null: false, default: ''
      t.integer :user_id,       null: false
      t.bigint  :uid,           null: false
      t.bigint  :ahoy_visit_id, null: true
      t.string  :via,           null: true

      t.timestamps null: false

      t.index :session_id
      t.index :user_id
      t.index :created_at
    end
  end
end
