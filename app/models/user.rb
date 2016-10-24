# == Schema Information
#
# Table name: users
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  secret      :string(191)      not null
#  token       :string(191)      not null
#  email       :string(191)      default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_users_on_created_at   (created_at)
#  index_users_on_screen_name  (screen_name)
#  index_users_on_uid          (uid) UNIQUE
#

class User < ActiveRecord::Base
  devise :rememberable, :omniauthable

  include Concerns::TwitterUser::Inflections

  def remember_created_at=(_)
  end

  has_one :notification_setting, foreign_key: :from_id, dependent: :destroy, validate: false
  accepts_nested_attributes_for :notification_setting

  delegate :can_send?, to: :notification_setting

  def self.update_or_create_for_oauth_by!(auth)
    attrs = {
      screen_name: auth.info.nickname,
      secret: auth.credentials.secret,
      token: auth.credentials.token
    }
    if User.exists?(uid: auth.uid)
      user = User.find_by(uid: auth.uid)
      self.transaction do
        user.update(attrs.update(email: (auth.info.email.present? ? auth.info.email : user.email)))
        user.touch
      end

      yield(user, :update) if block_given?
    else
      user = nil
      self.transaction do
        user = User.create!(attrs.update(uid: auth.uid, email: (auth.info.email || '')))
        user.create_notification_setting!(last_email_at: 1.day.ago, last_dm_at: 1.day.ago, last_news_at: 1.day.ago, last_search_at: 1.day.ago)
      end

      yield(user, :create) if block_given?
    end

    user
  end

  def config
    ApiClient.config(access_token: token, access_token_secret: secret)
  end

  def api_client
    ApiClient.instance(config)
  end

  def twitter_user
    if instance_variable_defined?(:@twitter_user)
      @twitter_user
    else
      @twitter_user = TwitterUser.latest(uid.to_i)
    end
  end

  ADMIN_UID = 58135830

  def admin?
    uid.to_i == ADMIN_UID
  end
end
