class CreateListsListMembers < ActiveRecord::Migration
  def change
    create_table :lists_list_members do |t|
      t.references :lists,        index: true, foreign_key: true, null: false
      t.references :list_members, index: true, foreign_key: true, null: false
    end
  end
end
