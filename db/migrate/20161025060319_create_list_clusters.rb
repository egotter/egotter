class CreateListClusters < ActiveRecord::Migration
  def change
    create_table :list_clusters do |t|
      t.string :word, unique: true, null: false

      t.datetime :created_at, null: false
    end
  end
end
