# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  uid              :string(191)      not null
#  screen_name      :string(191)      not null
#  authorized       :boolean          default(TRUE), not null
#  secret           :string(191)      not null
#  token            :string(191)      not null
#  email            :string(191)      default(""), not null
#  first_access_at  :datetime
#  last_access_at   :datetime
#  first_search_at  :datetime
#  last_search_at   :datetime
#  first_sign_in_at :datetime
#  last_sign_in_at  :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
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

  with_options dependent: :destroy, validate: false, autosave: false do |obj|
    obj.has_many :notification_messages
    obj.has_one :notification_setting
  end

  accepts_nested_attributes_for :notification_setting

  delegate :can_send?, to: :notification_setting

  validates :uid, presence: true, uniqueness: true
  validates_with Validations::UidValidator
  validates :screen_name, presence: true
  validates_with Validations::ScreenNameValidator
  validates :secret, presence: true
  validates :token, presence: true
  validates_each :email do |record, attr, value|
    record.errors.add(attr, :invalid) if value.nil? || (value != '' && !value.match(/\A[^@]+@[^@]+\z/))
  end

  def self.update_or_create_for_oauth_by!(auth)
    user = User.find_or_initialize_by(uid: auth.uid)
    user.assign_attributes(
      screen_name: auth.info.nickname,
      secret: auth.credentials.secret,
      token: auth.credentials.token
    )
    user.email = auth.info.email if auth.info.email.present?

    if user.new_record?
      self.transaction do
        user.save!
        user.create_notification_setting!
      end
      yield(user, :create) if block_given?
    else
      user.save! if user.changed?
      yield(user, :update) if block_given?
    end

    user
  rescue => e
    logger.warn "#{self}##{__method__}: #{e.class} #{e.message} #{e.respond_to?(:record) ? e.record.inspect : 'NONE'} #{auth.inspect}"
    raise e
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
