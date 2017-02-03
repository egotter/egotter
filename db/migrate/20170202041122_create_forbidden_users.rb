class CreateForbiddenUsers < ActiveRecord::Migration
  def change
    create_table :forbidden_users do |t|
      t.string :screen_name, null: false

      t.timestamps null: false
    end

    add_index :forbidden_users, :screen_name, unique: true
    add_index :forbidden_users, :created_at
  end
end
