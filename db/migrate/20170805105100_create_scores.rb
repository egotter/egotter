class CreateScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.integer :uid, limit: 8,  null: false
      t.string  :klout_id,       null: false
      t.float   :klout_score,    null: false
      t.text    :influence_json, null: false
    end
    add_index :scores, :uid, unique: true
  end
end
