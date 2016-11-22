# == Schema Information
#
# Table name: users
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  authorized  :boolean          default(TRUE), not null
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

  validates :uid, format: {with: Validations::UidValidator::REGEXP}
  validates :screen_name, format: {with: Validations::ScreenNameValidator::REGEXP}
  validates :secret, presence: true
  validates :token, presence: true
  validates :email, presence: true, allow_blank: true

  def self.update_or_create_for_oauth_by!(auth)
    attrs = {
      screen_name: auth.info.nickname,
      secret: auth.credentials.secret,
      token: auth.credentials.token
    }

    user = User.find_or_initialize_by(uid: auth.uid)
    if user.persisted?
      attrs.update(email: auth.info.email) if auth.info.email.present?
      user.update!(attrs)
    else
      attrs.update(email: auth.info.email || '')
      user.assign_attributes(attrs)
      self.transaction do
        user.save!
        user.create_notification_setting!(last_email_at: 1.day.ago, last_dm_at: 1.day.ago, last_news_at: 1.day.ago, last_search_at: 1.day.ago)
      end
    end

    yield(user, :update) if block_given?

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
