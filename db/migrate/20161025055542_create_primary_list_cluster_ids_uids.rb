class CreatePrimaryListClusterIdsUids < ActiveRecord::Migration
  def change
    create_table :primary_list_cluster_ids_uids do |t|
      t.integer :primary_list_cluster_id, index: true, null: false
      t.string  :uid,                     index: true, null: false
    end
  end
end
