# == Schema Information
#
# Table name: twitter_users
#
#  id           :integer          not null, primary key
#  uid          :string(191)      not null
#  screen_name  :string(191)      not null
#  user_info    :text(65535)      not null
#  search_count :integer          default(0), not null
#  update_count :integer          default(0), not null
#  user_id      :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_created_at               (created_at)
#  index_twitter_users_on_screen_name              (screen_name)
#  index_twitter_users_on_screen_name_and_user_id  (screen_name,user_id)
#  index_twitter_users_on_uid                      (uid)
#  index_twitter_users_on_uid_and_user_id          (uid,user_id)
#

class TwitterUser < ActiveRecord::Base
  with_options foreign_key: :from_id, dependent: :destroy, validate: false do |obj|
    obj.has_many :friends
    obj.has_many :followers
    obj.has_many :statuses
    obj.has_many :mentions
    obj.has_many :search_results
    obj.has_many :favorites
  end

  attr_accessor :client, :egotter_context

  def login_user
    User.find_by(id: user_id)
  end

  include Concerns::TwitterUser::Store
  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Equalizer
  include Concerns::TwitterUser::Builder
  include Concerns::TwitterUser::Utils
  include Concerns::TwitterUser::Api
  include Concerns::TwitterUser::Dirty
  include Concerns::TwitterUser::Persistence

  def search_log
    # TODO need to use user_id?
    log = BackgroundSearchLog.order(created_at: :desc).find_by(uid: uid)
    Hashie::Mash.new(log.nil? ? {} : log.attributes)
  end
end
