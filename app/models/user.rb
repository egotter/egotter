# == Schema Information
#
# Table name: users
#
#  id          :integer          not null, primary key
#  uid         :bigint(8)        not null
#  screen_name :string(191)      not null
#  authorized  :boolean          default(TRUE), not null
#  locked      :boolean          default(FALSE), not null
#  token       :string(191)
#  secret      :string(191)
#  email       :string(191)      default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_users_on_created_at   (created_at)
#  index_users_on_email        (email)
#  index_users_on_screen_name  (screen_name)
#  index_users_on_token        (token)
#  index_users_on_uid          (uid) UNIQUE
#

class User < ApplicationRecord
  devise :rememberable, :omniauthable

  has_one :credential_token

  include CredentialsApi

  def remember_created_at=(_) end

  with_options dependent: :destroy, validate: false, autosave: false do |obj|
    order_by_desc = -> { order(created_at: :desc) }

    obj.has_many :search_reports, order_by_desc
    obj.has_many :welcome_messages, order_by_desc
    obj.has_many :follow_requests, order_by_desc
    obj.has_many :reset_egotter_requests, order_by_desc
    obj.has_many :delete_tweets_requests, order_by_desc
    obj.has_many :delete_favorites_requests, order_by_desc
    obj.has_many :reset_cache_requests, order_by_desc
    obj.has_many :tweet_requests, order_by_desc

    obj.has_one :notification_setting
    obj.has_one :periodic_report_setting
    obj.has_one :credential_token
    obj.has_many :orders
    obj.has_many :coupons
    obj.has_many :access_days
  end

  accepts_nested_attributes_for :notification_setting

  validates :uid, presence: true, uniqueness: true
  validates_with Validations::UidValidator
  validates :screen_name, presence: true
  validates_with Validations::ScreenNameValidator
  validates_with Validations::EmailValidator

  scope :authorized, -> { where(authorized: true) }

  scope :premium, -> do
    includes(:orders).merge(Order.unexpired)
                     .references(:orders)
  end

  def expired_token?
    !api_client.verify_credentials
  rescue => e
    if TwitterApiStatus.invalid_or_expired_token?(e)
      true
    else
      raise
    end
  end

  def unauthorized_or_expire_token?
    !authorized? || expired_token?
  end

  class << self
    def egotter
      find_by(uid: EGOTTER_UID)
    end

    def egotter_cs
      find_by(uid: EGOTTER_CS_UID)
    end

    def tweet_cleaner
      find_by(uid: TWEET_CLEANER_UID)
    end

    def admin
      find_by(uid: ADMIN_UID)
    end

    def update_or_create_with_token!(values)
      if exists?(uid: values[:uid])
        user = update_with_token(values[:uid], values[:screen_name], values[:email], values[:token], values[:secret])
        yield(user, :update) if block_given?
      else
        user = create_with_token(values[:uid], values[:screen_name], values[:email], values[:token], values[:secret])
        yield(user, :create) if block_given?
      end

      user
    rescue => e
      Airbag.warn "#{self}##{__method__}: #{e.class} #{e.message} #{e.respond_to?(:record) ? e.record.inspect : 'NONE'} #{values.inspect}"
      raise e
    end

    def create_with_token(uid, screen_name, email, token, secret)
      user = new(uid: uid, screen_name: screen_name, email: email)
      # user.token = token if user.respond_to?(:token)
      # user.secret = secret if user.respond_to?(:secret)

      user.email = '' if user.email.blank?

      transaction do
        user.save!
        user.create_notification_setting!(report_interval: 12.hours, permission_level: NotificationSetting::PROPER_PERMISSION)
        user.create_periodic_report_setting!
        user.create_credential_token!(version: 2, token: token, secret: secret)
      end

      user
    end

    def update_with_token(uid, screen_name, email, token, secret)
      user = find_by(uid: uid)
      user.authorized = true
      user.locked = false
      # user.token = token if user.respond_to?(:token)
      # user.secret = secret if user.respond_to?(:secret)

      # In extremely rare cases, the values may be nil.
      user.screen_name = screen_name if screen_name.present?

      user.email = email if email.present?
      user.email = '' if user.email.blank?

      transaction do
        user.save! if user.changed?
        user.credential_token.update!(version: 2, token: token, secret: secret)
      end

      user
    end

    def api_client
      ids = where(authorized: true, locked: false).order(created_at: :desc).limit(200).pluck(:id)
      find(ids.sample).api_client
    end

    def authorized_agents
      where(created_at: 11.days.ago..9.days.ago).where(authorized: true)
    end
  end

  def to_param
    screen_name
  end

  def api_client(options = {})
    opt = options.merge(access_token: credential_token.token, access_token_secret: credential_token.secret, user: self)
    ApiClient.instance(opt)
  end

  def twitter_user
    if instance_variable_defined?(:@twitter_user)
      @twitter_user
    else
      @twitter_user = TwitterUser.latest_by(uid: uid)
    end
  end

  def following_egotter?
    EgotterFollower.exists?(uid: uid)
  end

  def sharing_count(duration = nil)
    duration = 1.hour unless duration
    tweet_requests.where(created_at: duration.ago..Time.zone.now).
        where(deleted_at: nil).where.not(tweet_id: nil).size
  end

  def invited_count
    @invited_count ||= ClickIdGenerator.invited_count(self)
  rescue => e
    0
  end

  def coupons_search_count
    coupons.not_expired.has_search_count.sum(:search_count)
  end

  def coupons_stripe_coupon_ids
    coupons.not_expired.has_stripe_coupon_id.pluck(:stripe_coupon_id).uniq
  end

  ADMIN_UID = 58135830
  EGOTTER_UID = 187385226
  EGOTTER_CS_UID = 216924023
  EGOTTER_AI_UID = 1362067811061829636
  TWEET_CLEANER_UID = 1392464015004114945

  def admin?
    uid == ADMIN_UID
  end

  PERIODIC_REPORT_AT_MARK_DURATION = 1.week

  def add_atmark_to_periodic_report?
    has_valid_subscription? || PERIODIC_REPORT_AT_MARK_DURATION.ago < created_at
  end

  def send_periodic_report_even_though_not_following?
    has_valid_subscription? || 1.weeks.ago < created_at
  end

  def reveal_names_on_block_report?
    has_valid_subscription? && !has_trial_subscription?
  end

  def continuous_sign_in?(ignore_today = true)
    (ignore_today || access_days.where(date: Time.zone.now.in_time_zone('Tokyo').to_date).exists?) &&
        access_days.where(date: 1.day.ago.in_time_zone('Tokyo').to_date).exists?
  end

  # TODO trial = nil
  def has_valid_subscription?
    if instance_variable_defined?(:@has_valid_subscription)
      @has_valid_subscription
    else
      @has_valid_subscription = orders.unexpired.any?
    end
  end

  def has_trial_subscription?
    if instance_variable_defined?(:@has_trial_subscription)
      @has_trial_subscription
    else
      @has_trial_subscription = valid_order.trial?
    end
  end

  def valid_order
    orders.unexpired.last
  end

  # TODO Remove
  def valid_customer_id
    order = orders.where.not(customer_id: :nil).order(created_at: :desc).first
    order&.customer_id
  end

  def purchased_search_count
    valid_order.search_count
  end

  def persisted_statuses_count
    TwitterDB::User.find_by(uid: uid)&.statuses_count
  end

  def persisted_favorites_count
    TwitterDB::User.find_by(uid: uid)&.favourites_count
  end

  def user_token
    signature_base = uid.to_s
    signature_key = credential_token.secret
    OpenSSL::HMAC.hexdigest('sha1', signature_key, signature_base)
  end

  def valid_user_token?(value)
    user_token == value
  end

  def can_see_adult_account?
    has_valid_subscription? || ((user = TwitterDB::User.find_by(uid: uid)) && TwitterUserDecorator.new(user).adult_account?)
  end

  def enough_permission_level?
    return true unless notification_setting # For test
    notification_setting.permission_level == NotificationSetting::PROPER_PERMISSION
  end

  def banned?
    BannedUser.where(user_id: id).exists?
  end
end
