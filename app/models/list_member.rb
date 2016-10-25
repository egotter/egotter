class ListMember < ActiveRecord::Base
  has_and_belongs_to_many :lists, validate: false
end
