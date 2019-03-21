class Nikaidate::Citation < ActiveRecord::Base
  with_options(dependent: :destroy, validate: false, autosave: false) do |obj|
    obj.belongs_to :post, primary_key: :archive_id, foreign_key: :archive_id
    obj.belongs_to :opinion, primary_key: :status_id, foreign_key: :status_id
  end
end