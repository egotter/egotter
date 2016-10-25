class List < ActiveRecord::Base
  has_and_belongs_to_many :list_members, validate: false
end
