class CreateNikaidateCitations < ActiveRecord::Migration
  def change
    create_table :nikaidate_citations do |t|
      t.string :archive_id, null: false
      t.string :status_id,  null: false
    end
    add_index :nikaidate_citations, :archive_id
  end
end
