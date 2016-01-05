class Follower < ActiveRecord::Base
  belongs_to :twitter_user
end
