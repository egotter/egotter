require 'active_support/concern'

module Concerns::TwitterUser::Associations
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    with_options foreign_key: :from_id, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends
      obj.has_many :followers
      obj.has_many :unfriends
      obj.has_many :unfollowers
      obj.has_many :statuses
      obj.has_many :mentions
      obj.has_many :search_results
      obj.has_many :favorites
    end
  end
end
