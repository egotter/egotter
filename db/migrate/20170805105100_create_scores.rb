class CreateScores < ActiveRecord::Migration[4.2]
  def change
    create_table :scores do |t|
      t.integer :uid, limit: 8,  null: false
      t.string  :klout_id,       null: false
      t.float   :klout_score,    null: false, limit: 53
      t.text    :influence_json, null: false

      t.timestamps null: false
    end
    add_index :scores, :uid, unique: true
    add_index :scores, :created_at
  end
end
