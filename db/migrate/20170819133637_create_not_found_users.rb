class CreateNotFoundUsers < ActiveRecord::Migration
  def change
    create_table :not_found_users do |t|
      t.string :screen_name, null: false

      t.timestamps null: false
    end

    add_index :not_found_users, :screen_name, unique: true
    add_index :not_found_users, :created_at
  end
end
